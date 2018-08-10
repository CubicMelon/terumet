local opts = terumet.options.crusher
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_crs = {}
base_crs.unlit_id = terumet.id('mach_crusher')
base_crs.lit_id = terumet.id('mach_crusher_lit')

-- state identifier consts
base_crs.STATE = {}
base_crs.STATE.IDLE = 0
base_crs.STATE.HEATING = 1
base_crs.STATE.COOLING = 2

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    machine = function(machine)
        local fs = ''
        if machine.state == base_crs.STATE.HEATING then
            fs=fs..base_mach.fs_proc(3,2,'pres1', machine.inv:get_stack('process',1))
        elseif machine.state == base_crs.STATE.COOLING then
            fs=fs..base_mach.fs_proc(3,2,'pres2', machine.inv:get_stack('result',1))
        else
            fs=fs..'image[3,2;2,2;terumet_gui_idle_pres.png]'
        end
        return fs
    end,
    input = {true},
    output = {true},
}

function base_crs.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 4)
    inv:set_size('process', 1)
    inv:set_size('result', 1)
    inv:set_size('out', 4)
    inv:set_size('upgrade', 2)

    local init_crusher = {
        class = base_crs.unlit_nodedef._terumach_class,
        flux_tank = 0,
        state = base_crs.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos,
    }
    base_mach.write_state(pos, init_crusher)
end

function base_crs.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function base_crs.do_processing(crusher, dt)
    local speed_mult = 1
    if base_mach.has_upgrade(crusher, 'speed_up') then speed_mult = 2 end

    if crusher.state == base_crs.STATE.HEATING and base_mach.expend_heat(crusher, opts.COST_HEATING * speed_mult, 'Heating presses') then
        crusher.state_time = crusher.state_time - (dt * speed_mult)
        if crusher.state_time <= 0 then
            crusher.inv:set_stack('process', 1, nil)
            crusher.state = base_crs.STATE.COOLING
            crusher.state_time = opts.TIME_COOLING
            crusher.status_text = 'Heating finished.'
        else
            crusher.status_text = 'Heating presses (' .. terumet.format_time(crusher.state_time) .. ')'
        end
    elseif crusher.state == base_crs.STATE.COOLING then
        crusher.state_time = crusher.state_time - (dt * speed_mult)
        if crusher.state_time <= 0 then
            local result_stack = crusher.inv:get_stack('result', 1)
            local result_name = terumet.itemstack_desc(result_stack)
            local out_inv, out_list = base_mach.get_output(crusher)
            if out_inv then
                if out_inv:room_for_item(out_list, result_stack) then
                    crusher.inv:set_stack('result', 1, nil)
                    out_inv:add_item(out_list, result_stack)
                    crusher.state = base_crs.STATE.IDLE
                    crusher.status_text = 'Cooling finished. '..result_name..' released.'
                else
                    crusher.status_text = result_name .. ' ready - no output space!'
                    crusher.state_time = -0.1
                end
            else
                crusher.status_text = 'No output'
                crusher.state_time = -0.1
            end
        else
            crusher.status_text = 'Cooling presses (' .. terumet.format_time(crusher.state_time) .. ')'
        end
    end
end

function base_crs.check_new_processing(crusher)
    if crusher.state ~= base_crs.STATE.IDLE then return end
    if crusher.heat_level == 0 then
        crusher.status_text = 'Idle'
        return
    end
    local in_inv, in_list = base_mach.get_input(crusher)
    if not in_inv then
        crusher.status_text = "No input"
        return
    end
    local output = nil
    -- check inputs in order
    for in_slot = 1,in_inv:get_size(in_list) do
        local input_stack = in_inv:get_stack(in_list, in_slot)
        local matched = opts.recipes[input_stack:get_name()]
        -- try to match a group recipe if not a specific match
        if not matched then matched = terumet.match_group_key(opts.recipes, input_stack:get_definition()) end
        if matched then
            local proc_stack = in_inv:remove_item(in_list, input_stack:get_name())
            crusher.inv:set_stack('process', 1, proc_stack)
            crusher.inv:set_stack('result', 1, matched)
            crusher.state_time = opts.TIME_HEATING
            crusher.state = base_crs.STATE.HEATING
            crusher.status_text = string.format('Accepting %s for crushing...', terumet.itemstack_desc(proc_stack))
            return
        end
    end
end

function base_crs.tick(pos, dt)
    -- read state from meta
    local crusher = base_mach.tick_read_state(pos)
    local venting

    if base_mach.check_overheat(crusher, opts.MAX_HEAT) then
        venting = true
    else
        base_crs.do_processing(crusher, dt)
        base_crs.check_new_processing(crusher)
    end

    if crusher.state == base_crs.STATE.HEATING and (not crusher.need_heat) then
        base_mach.generate_smoke(pos)
        base_mach.set_node(pos, base_crs.lit_id)
    elseif crusher.state == base_crs.STATE.COOLING then
        base_mach.generate_smoke(pos, 4)
        base_mach.set_node(pos, base_crs.unlit_id)
    else
        base_mach.set_node(pos, base_crs.unlit_id)
    end

    if venting or base_mach.has_upgrade(crusher, 'ext_input') then
        reset_timer = true
    end
    -- write status back to metad
    base_mach.write_state(pos, crusher)

    return crusher.state ~= base_crs.STATE.IDLE or venting
end

base_crs.unlit_nodedef = base_mach.nodedef{
    -- node properties
    description = "Expansion Crusher",
    tiles = {
        terumet.tex('lavam_top'), terumet.tex('raw_mach_bot'),
        terumet.tex('raw_sides_unlit'), terumet.tex('raw_sides_unlit'),
        terumet.tex('raw_sides_unlit'), terumet.tex('crush_front_unlit')
    },
    -- callbacks
    on_construct = base_crs.init,
    on_timer = base_crs.tick,
    -- machine class data
    _terumach_class = {
        name = 'Expansion Crusher',
        timer = 1.0,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_crs.unlit_id,
        get_drop_contents = base_crs.get_drop_contents,
    }
}

base_crs.lit_nodedef = {}
for k,v in pairs(base_crs.unlit_nodedef) do base_crs.lit_nodedef[k] = v end
base_crs.lit_nodedef.on_construct = nil
base_crs.lit_nodedef.tiles = {
    terumet.tex('lavam_top'), terumet.tex('raw_mach_bot'),
    terumet.tex('raw_sides_lit'), terumet.tex('raw_sides_lit'),
    terumet.tex('raw_sides_lit'), terumet.tex('crush_front_lit')
}
base_crs.lit_nodedef.groups = terumet.create_lit_node_groups(base_crs.unlit_nodedef.groups)
base_crs.lit_nodedef.light_source = 10

minetest.register_node(base_crs.unlit_id, base_crs.unlit_nodedef)
minetest.register_node(base_crs.lit_id, base_crs.lit_nodedef)

minetest.register_craft{ output = base_crs.unlit_id, recipe = {
    {terumet.id('item_coil_tcop'), terumet.id('item_press'), terumet.id('item_coil_tcop')},
    {terumet.id('ingot_tcha'), terumet.id('frame_raw'), terumet.id('ingot_tcha')},
    {terumet.id('item_coil_tcop'), terumet.id('item_press'), terumet.id('item_coil_tcop')}
}}