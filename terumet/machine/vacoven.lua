local opts = terumet.options.vac_oven
-- local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_vov = {}
base_vov.unlit_id = terumet.id('mach_vcoven')
--base_vov.lit_id = terumet.id('mach_htfurn_lit')

-- state identifier consts
base_vov.STATE = {}
base_vov.STATE.IDLE = 0
base_vov.STATE.COOKING = 1
base_vov.STATE.EJECT = 2

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    machine = function(machine)
        local fs = ''
        if machine.state ~= base_vov.STATE.IDLE then
            fs=fs..base_mach.fs_proc(3,2,'cook', machine.inv:get_stack('result',1))
        end
        return fs
    end,
    input = {true},
    output = {true},
    bg = 'gui_back3'
}

local MAX_RESULTS = opts.MAX_RESULTS -- maximum number of result items from a recipe

function base_vov.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 4)
    inv:set_size('result', MAX_RESULTS)
    inv:set_size('out', 4)
    inv:set_size('upgrade', 4)
    local init_oven = {
        class = base_vov.unlit_nodedef._terumach_class,
        state = base_vov.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_oven)
end

function base_vov.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function base_vov.do_processing(oven, dt)
    if base_mach.has_upgrade(oven, 'speed_up') then dt = dt * 2 end

    local heat_req = math.min(dt, oven.state_time) * opts.COOK_HUPS
    if oven.state == base_vov.STATE.COOKING and base_mach.expend_heat(oven, heat_req, 'Heating') then
        oven.state_time = oven.state_time - dt
        if oven.state_time <= 0 then
            oven.state = base_vov.STATE.EJECT
        else
            oven.status_text = 'Heating (' .. terumet.format_time(oven.state_time) .. ')'
        end
    end

    if oven.state == base_vov.STATE.EJECT then
        local out_inv, out_list = base_mach.get_output(oven)
        if out_inv then
            local empties = 0
            for result_num = 1,MAX_RESULTS do
                local result_stack = oven.inv:get_stack('result', result_num)
                if result_stack then
                    if out_inv:room_for_item(out_list, result_stack) then
                        oven.inv:set_stack('result', result_num, nil)
                        out_inv:add_item(out_list, result_stack)
                        empties = empties + 1
                    else
                        oven.status_text = terumet.itemstack_desc(result_stack) .. ' ready - no output space!'
                    end
                else
                    empties = empties + 1
                end
            end
            if empties >= MAX_RESULTS then oven.state = base_vov.STATE.IDLE end
        else
            oven.status_text = 'No output'
        end
    end
end

function base_vov.check_new_processing(oven)
    if oven.state ~= base_vov.STATE.IDLE then return end
    local in_inv, in_list = base_mach.get_input(oven)
    if not in_inv then
        oven.status_text = 'No input'
        return
    end
    for _,recipe in ipairs(opts.recipes) do
        if in_inv:contains_item(in_list, recipe.input) then
            in_inv:remove_item(in_list, recipe.input)
            for slot,result_item in ipairs(recipe.results) do
                oven.inv:set_stack('result', slot, result_item)
            end
            oven.state = base_vov.STATE.COOKING
            oven.state_time = recipe.time
            oven.status_text = 'Beginning vacuum cycle...'
            return
        end
    end
    oven.status_text = 'Idle'
end

function base_vov.tick(pos, dt)
    -- read state from meta
    local oven = base_mach.tick_read_state(pos)

    local venting
    if base_mach.check_overheat(oven, opts.MAX_HEAT) then
        venting = true
    else
        base_vov.do_processing(oven, dt)
        base_vov.check_new_processing(oven)
    end

    local working = oven.state ~= base_vov.STATE.IDLE and (not oven.need_heat)

    -- write status back to meta
    base_mach.write_state(pos, oven)

    -- return true to reset tick timer
    return working or venting or base_mach.has_upgrade(oven, 'ext_input')
end

base_vov.unlit_nodedef = base_mach.nodedef{
    -- node properties
    description = "Vacuum Oven",
    tiles = {
        terumet.tex('vacoven_top'), terumet.tex('hray_back'),
        terumet.tex('vacoven_sides'), terumet.tex('vacoven_sides'),
        terumet.tex('vacoven_sides'), terumet.tex('vacoven_front')
    },
    -- callbacks
    on_construct = base_vov.init,
    on_timer = base_vov.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Vacuum Oven',
        timer = 0.5,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_vov.unlit_id,
        get_drop_contents = base_vov.get_drop_contents
    }
}

base_mach.define_machine_node(base_vov.unlit_id, base_vov.unlit_nodedef)

minetest.register_craft{ output = base_vov.unlit_id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_coil_tgol'), terumet.id('item_coil_tgol')},
    {terumet.id('item_ceramic'), terumet.id('frame_cgls'), terumet.id('item_ceramic')},
    {terumet.id('item_ceramic'), terumet.id('item_ceramic'), terumet.id('item_ceramic')}
}}