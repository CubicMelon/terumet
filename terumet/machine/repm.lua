local opts = terumet.options.repm
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_repm = {}
base_repm.id = terumet.id('mach_repm')

-- state identifier consts
base_repm.STATE = {}
base_repm.STATE.IDLE = 0
base_repm.STATE.RMAT_MELT = 1
base_repm.STATE.REPAIRING = 2

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,        
    },
    machine = function(machine)
        -- TODO: display tweaking
        local fs = base_mach.fs_meter(2.5,1, 'rmat', 100*machine.rmat_tank/opts.RMAT_MAXIMUM, 'Repair Material')
        if machine.state == base_repm.STATE.RMAT_MELT then
            fs=fs..base_mach.fs_proc(3,2,'melt', machine.inv:get_stack('process', 1))
        elseif machine.state == base_repm.STATE.REPAIRING then
            fs=fs..base_mach.fs_proc(3,2,'alloy')
        end
        return fs
    end,
    input = {true},
    output = {true},
}

function base_repm.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 4)
    inv:set_size('process', 1)
    inv:set_size('out', 4)
    inv:set_size('upgrade', 3)

    local init_repm = {
        class = base_repm.nodedef._terumach_class,
        rmat_tank = 0,
        rmat_melting = 0,
        state = base_repm.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos,
    }
    base_mach.write_state(pos, init_repm)
end

function base_repm.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    local rmat_tank = machine.meta:get_int('rmat_tank') or 0
    if rmat_tank > 0 then
        -- TODO drop some sort of raw rmat item?
        --drops[#drops+1] = terumet.id('item_cryst_raw', math.min(99, flux_tank))
    end
    return drops
end

function base_repm.try_eject_item(repm)
    local proc_item = repm.inv:get_stack('process', 1)
    if proc_item then
        local out_inv, out_list = base_mach.get_output(repm)
        if out_inv:room_for_item(out_list, proc_item) then
            out_inv:add_item(out_list, proc_item)
            repm.inv:set_stack('process', 1, nil)
            repm.state = base_repm.STATE.IDLE
            return true
        end
    end
    return false
end

function base_repm.process(repm, dt)
    if repm.state == base_repm.STATE.IDLE then return end
    
    -- check inputs and melt/repair them accordingly
    local in_inv, in_list = base_mach.get_input(repm)
    local out_inv, out_list = base_mach.get_output(repm)
    if not in_inv then
        repm.status_text = "No input"
        repm.state = base_repm.STATE.IDLE
        return
    end

    if repm.state == base_repm.STATE.RMAT_MELT then
        if base_mach.expend_heat(repm, opts.MELTING_HEAT, 'Melting repair material') then
            local rmat_time = math.min(repm.state_time, dt)
            local rmat_gain = rmat_time * opts.MELTING_RATE
            repm.rmat_tank = math.min(opts.RMAT_MAXIMUM, repm.rmat_tank + rmat_gain)
            repm.state_time = repm.state_time - rmat_time
            if repm.rmat_tank == opts.RMAT_MAXIMUM or repm.state_time <= 0.01 then
                repm.inv:set_stack('process', 1, nil)
                repm.state = base_repm.STATE.IDLE
            else
                repm.status_text = 'Melting repair material (' .. terumet.format_time(repm.state_time) .. ')'
            end
        end
    elseif repm.state == base_repm.STATE.REPAIRING then
        if base_mach.expend_heat(repm, opts.REPAIR_HEAT, 'Repairing') then
            -- TODO
        else
            -- in order to keep tools from being "stuck" in the machine,
            -- if either heat or repmat runs out we eject the item before shutting down
            -- try_eject_item will set state to IDLE if successful
            base_repm.try_eject_item()
        end
    end

    -- GARBAGE AFTER HERE ================================================================================
    --[[
    local repair_items = {}
    -- check each slot if it is a repmat item to melt or a repairable
    for slot = 1,in_inv:get_size(in_list) do
        local in_stack = in_inv:get_stack(in_list, slot)
        if in_stack then
            local item_name = in_stack:get_name()
            if opts.repair_mats[item_name] then
                -- is a repmat item -> consume one and add its value to the currently-melting value
                in_stack:set_count(in_stack:get_count() - 1)
                repm.rmat_melting = repm.rmat_melting + opts.repair_mats[item_name]
            elseif opts.repairable[item_name] and in_stack:get_wear() > 0 then
                -- is a repairable item with wear -> put it into list of items to try to repair this tick
                repair_items[#repair_items+1] = in_stack
            elseif out_inv:room_for_item(out_list, in_stack) then
                -- is not something we can process, move to output if there's space
                in_inv:remove_item(in_list, in_stack)
                out_inv:add_item(out_list, in_stack)
            end
        end
    end
    -- try to process any currently-melting repmat
    local rmat_space = opts.RMAT_MAXIMUM - repm.rmat_tank
    if repm.rmat_melting > 0 and rmat_space > 0 and base_mach.expend_heat(repm, opts.MELTING_HEAT, 'Melting repair material') then
        local rmat_add = math.min(opts.MAX_MELT, repm.rmat_melting, rmat_space)
        if rmat_add > 0 then
            continue_working = true
            repm.rmat_melting = repm.rmat_melting - rmat_add
            repm.rmat_tank = repm.rmat_tank + rmat_add
        else
            minetest.log('error', 'somehow rmat_add was zero when it should not be possible')
        end
    end
    -- try to repair previously-found items that are eligible
    if #repair_items > 0 then
        -- amount of maximum rmat that can be applied to each eligible item 
        local max_repair_each = math.floor(opts.MAX_REPAIR / #repair_items)
        -- keep track of how much rmat actually used and how many items repaired
        local total_rmat_used = 0
        local rep_count = 0
        for _,rep_item in ipairs(repair_items) do
            -- can't use standard heat using function because we only want to check for enough first
            if repm.heat_level >= opts.REPAIRING_HEAT then 
                local item_wear = rep_item:get_wear()
                local item_rmat_total = opts.repairable[rep_item:get_name()]
                local full_rmat_need = math.ceil(item_rmat_total * item_wear / 65535)
                local used_rmat = math.min(full_rmat_need, max_repair_each)
                if used_rmat > (repm.rmat_tank - total_rmat_used) then
                    repm.status_text = 'Not enough repair material for '..rep_item:get_description()
                elseif used_rmat > 0 then
                    rep_item:set_wear(math.max(0, item_wear - (65535 * used_rmat / item_rmat_total)))
                    total_rmat_used = total_rmat_used + used_rmat
                    rep_count = rep_count + 1
                    -- if fully repaired, move to output
                    if (rep_item:get_wear() == 0) and out_inv and out_inv:room_for_item(out_list, rep_item) then
                        in_inv:remove_item(in_list, rep_item)
                        out_inv:add_item(out_list, rep_item)
                    end
                else
                    minetest.log('error', 'somehow repair_item used 0 rmat to repair which should not be possible')
                end
            else
                -- cause error message
                base_mach.expend_heat(repm, opts.REPAIRING_HEAT, 'Repairing '..rep_item:get_description())
                break
            end
        end
        if rep_count > 0 then
            continue_working = true
            repm.rmat_tank = repm.rmat_tank - total_rmat_used
            repm.status_text = string.format('Repaired %d item%s', rep_count, (rep_count == 1 and '' or 's'))
        end
    end
    -- GARBAGE BEFORE HERE ================================================================================
    ]]--
end

function base_repm.check_new_processing(repm)
    -- only check if presently IDLE
    if repm.state ~= base_repm.STATE.IDLE then return end
    
    local in_inv, in_list = base_mach.get_input(repm)
    local out_inv, out_list = base_mach.get_output(repm)

    if not in_inv then
        repm.status_text = "No input"
        return
    end
    
    repm.status_text = 'Idle' -- default if no processing found

    -- check input slots
    for slot = 1,in_inv:get_size(in_list) do
        local in_stack = in_inv:get_stack(in_list, slot)
        if in_stack then
            local item_name = in_stack:get_name()
            if opts.repair_mats[item_name] and (repm.rmat_tank < opts.RMAT_MAXIMUM) then
                -- can be melted for repair material
                local material_item = in_stack:take_item(1)
                repm.inv:set_stack('process', 1, material_item)
                in_inv:set_stack(in_list, slot, in_stack)
                repm.state = base_repm.STATE.RMAT_MELT
                repm.state_time = opts.repair_mats[item_name] * 0.5 / opts.MELTING_RATE
                repm.status_text = string.format('Accepting %s as repair material...', terumet.itemstack_desc(material_item))
                break
            elseif opts.repairable[item_name] and in_stack:get_wear() > 0 then
                -- can be repaired
                repm.inv:set_stack('process', 1, in_stack)
                in_inv:set_stack(in_list, slot, nil)
                repm.state = base_repm.STATE.REPAIRING
                -- do not set state_time for repairing
                repm.status_text = string.format('Accepting %s for repairing...', terumet:itemstack_desc(in_stack))
                break
            elseif out_inv:room_for_item(out_list, in_stack) then
                -- not usable and room in output
                in_inv:remove_item(in_list, in_stack)
                out_inv:add_item(out_list, in_stack)
            end
        end
    end
end

function base_repm.tick(pos, dt)
    -- read state from meta
    local repm = base_mach.read_state(pos)
    local venting
    local reset_timer = false
    if base_mach.check_overheat(repm, opts.MAX_HEAT) then
        -- venting heat
        venting = true
    else
        -- normal operation
        base_repm.process(repm, dt)
        base_repm.check_new_processing(repm)
    end

    if repm.state ~= base_repm.STATE.IDLE and (not repm.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        reset_timer = true
        base_mach.generate_smoke(pos)
    elseif venting or base_mach.has_upgrade(repm, 'ext_input') then
        reset_timer = true
    end
    -- write status back to meta
    base_mach.write_state(pos, repm)

    -- TODAY I LEARNED
    -- if you return true from an on_timer callback, it automatically resets timer to last timeout
    return reset_timer
end

base_repm.nodedef = base_mach.nodedef{
    -- node properties
    description = "Equipment Reformer",
    tiles = {
        terumet.tex('frame_tste'), terumet.tex('block_ceramic'),
        terumet.tex('htfurn_sides'), terumet.tex('htfurn_sides'),
        terumet.tex('htfurn_sides'), terumet.tex('repm_front')
    },
    -- callbacks
    on_construct = base_repm.init,
    on_timer = base_repm.tick,
    -- machine class data
    _terumach_class = {
        name = 'Equipment Reformer',
        timer = 0.5,
        -- NEW
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        -- end new
        drop_id = base_repm.id,
        get_drop_contents = base_repm.get_drop_contents,
        on_read_state = function(repm)
            repm.rmat_tank = repm.meta:get_int('rmat_tank')
            repm.rmat_melting = repm.meta:get_int('rmat_melting')
        end,
        on_write_state = function(repm)
            repm.meta:set_int('rmat_tank', repm.rmat_tank)
            repm.meta:set_int('rmat_melting', repm.rmat_melting)
        end
    }
}

minetest.register_node(base_repm.id, base_repm.nodedef)

minetest.register_craft{ output = base_repm.id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_ceramic'), terumet.id('item_coil_tgol')},
    {terumet.id('item_coil_tgol'), terumet.id('frame_tste'), terumet.id('item_coil_tgol')},
    {terumet.id('item_ceramic'), 'bucket:empty_bucket', terumet.id('item_ceramic')}
}}