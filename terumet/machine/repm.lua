local opts = terumet.options.repm
-- local base_opts = terumet.options.machine

local base_mach = terumet.machine

-- id for repair material drop item
local REPMAT_DROP_ID = terumet.id('repmat_drop')

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
            fs=fs..base_mach.fs_proc(3,2,'alloy', machine.inv:get_stack('process', 1))
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
        local total_drop_ct = math.floor(rmat_tank / opts.MELTING_RATE)
        while total_drop_ct > 0 do
            local drop_ct = math.min(99, total_drop_ct)
            drops[#drops+1] = string.format('%s %d', REPMAT_DROP_ID, drop_ct)
            total_drop_ct = total_drop_ct - drop_ct
        end
    end
    return drops
end

function base_repm.try_eject_item(repm, desc)
    local proc_item = repm.inv:get_stack('process', 1)
    if proc_item then
        local out_inv, out_list = base_mach.get_output(repm)
        if out_inv:room_for_item(out_list, proc_item) then
            out_inv:add_item(out_list, proc_item)
            repm.inv:set_stack('process', 1, nil)
            repm.state = base_repm.STATE.IDLE
            if desc then
                repm.status_text = string.format('%s ejected: %s', terumet.itemstack_desc(proc_item), desc)
            else
                repm.status_text = string.format('%s ejected', terumet.itemstack_desc(proc_item))
            end
            return true
        end
        repm.status_text = string.format('Cannot eject %s: No output space', terumet.itemstack_desc(proc_item))
    end
    return false
end

function base_repm.process(repm, dt)
    if repm.state == base_repm.STATE.IDLE then return end

    local speed_mult = 1.0
    if base_mach.has_upgrade(repm, 'speed_up') then speed_mult = 2.0 end

    if repm.state == base_repm.STATE.RMAT_MELT then
        if base_mach.expend_heat(repm, opts.MELTING_HEAT * speed_mult, 'Melting repair material') then
            local rmat_time = math.min(repm.state_time, dt * speed_mult)
            local rmat_gain = math.floor(rmat_time * opts.MELTING_RATE)
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
        local rep_item = repm.inv:get_stack('process', 1)
        local rep_item_wear = rep_item:get_wear()
        if rep_item_wear > 0 and base_mach.expend_heat(repm, opts.REPAIR_HEAT * speed_mult, 'Repairing') then
            local item_full_repair_cost = opts.repairable[rep_item:get_name()]
            if item_full_repair_cost then
                -- wear points removed per point of repmat
                local repair_per_rmp = math.ceil(65535 / item_full_repair_cost)
                -- repmat points used this tick
                local rmp_used = math.ceil(math.min(opts.REPAIR_RATE * dt * speed_mult, rep_item_wear * repair_per_rmp))
                if repm.rmat_tank >= rmp_used then
                    repm.rmat_tank = repm.rmat_tank - rmp_used
                    local new_wear = math.max(0, rep_item_wear - (rmp_used * repair_per_rmp))
                    rep_item:set_wear(new_wear)
                    repm.inv:set_stack('process', 1, rep_item)
                    if new_wear > 0 then
                        repm.status_text = string.format('Repairing %s... (%.1f%% wear)', terumet.itemstack_desc(rep_item), 100*new_wear/65535)
                    else
                        base_repm.try_eject_item(repm, 'Repair complete')
                    end
                else
                    base_repm.try_eject_item(repm, 'Not enough repair material')
                end
            else
                -- in case item becomes unrepairable mid-process
                -- (server reset with changed options?)
                base_repm.try_eject_item(repm, 'Item not repairable')
            end
        else
            -- in order to keep tools from being "stuck" in the machine,
            -- if either heat or repmat runs out we eject the item before shutting down
            -- try_eject_item will set state to IDLE if successful
            base_repm.try_eject_item(repm, 'Not enough heat')
        end
    end
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
                repm.state_time = opts.repair_mats[item_name] / opts.MELTING_RATE
                repm.status_text = string.format('Accepting %s as repair material...', terumet.itemstack_desc(material_item))
                break
            elseif opts.repairable[item_name] and in_stack:get_wear() > 0 then
                -- can be repaired
                repm.inv:set_stack('process', 1, in_stack)
                repm.state = base_repm.STATE.REPAIRING
                in_inv:set_stack(in_list, slot, nil)
                -- do not set state_time for repairing
                repm.status_text = string.format('Accepting %s for repairing...', terumet.itemstack_desc(in_stack))
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
    local repm = base_mach.tick_read_state(pos)
    local venting
    local reset_timer = false
    if base_mach.check_overheat(repm, opts.MAX_HEAT) then
        -- venting heat
        venting = true
    else
        repm.status_text = 'Idle' -- if not overwritten
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

-- register 'crystallized repair material' drop

minetest.register_craftitem( REPMAT_DROP_ID, {
    description = 'Crystallized Repair Material',
    inventory_image = terumet.crystal_tex('#39df34'),
})
terumet.register_repair_material(REPMAT_DROP_ID, opts.MELTING_RATE)

base_mach.define_machine_node(base_repm.id, base_repm.nodedef)

minetest.register_craft{ output = base_repm.id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_ceramic'), terumet.id('item_coil_tgol')},
    {terumet.id('item_coil_tgol'), terumet.id('frame_tste'), terumet.id('item_coil_tgol')},
    {terumet.id('item_ceramic'), 'bucket:bucket_empty', terumet.id('item_ceramic')}
}}