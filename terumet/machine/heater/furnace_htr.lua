local opts = terumet.options.heater.furnace
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local furn_htr = {}
furn_htr.unlit_id = terumet.id('mach_htr_furnace')
furn_htr.lit_id = terumet.id('mach_htr_furnace_lit')

-- state identifier consts
furn_htr.STATE = {}
furn_htr.STATE.IDLE = 0
furn_htr.STATE.BURNING = 1
furn_htr.STATE.BURN_FULL = 2

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE
    },
    machine = function(machine)
        local fs = ''
        if machine.state ~= furn_htr.STATE.IDLE then
            fs=fs..base_mach.fs_proc(3.5, 1.5, 'heat', machine.inv:get_stack('burn', 1))
        end
        return fs
    end,
    input = {x=2.5, y=1.5}
}

function furn_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 1)
    inv:set_size('burn', 1)
    inv:set_size('upgrade', 2)
    local init_heater = {
        class = furn_htr.unlit_nodedef._terumach_class,
        state = furn_htr.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta
    }
    base_mach.write_state(pos, init_heater)
end

function furn_htr.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function furn_htr.do_processing(heater, dt)
    local speed_mult = 1
    if base_mach.has_upgrade(heater, 'speed_up') then speed_mult = 2 end

    local gain = math.floor(opts.HEAT_GEN * dt * speed_mult) -- heat gain this tick
    if base_mach.has_upgrade(heater, 'gen_up') then gain = gain * 3 end
    if gain == 0 then return end
    local under_cap = heater.heat_level < (heater.max_heat - gain)
    if heater.state == furn_htr.STATE.BURN_FULL and under_cap then
        heater.state = furn_htr.STATE.BURNING
    end
    if heater.state == furn_htr.STATE.BURNING then
        if under_cap then
            heater.state_time = heater.state_time - (dt * speed_mult)
            base_mach.gain_heat(heater, gain)
            if heater.state_time <= 0 then
                heater.inv:set_stack('burn', 1, nil)
                heater.status_text = 'Burn complete'
                heater.state = furn_htr.STATE.IDLE
            else
                heater.status_text = 'Burning (' .. terumet.format_time(heater.state_time) .. ')'
            end
        else
            heater.state = furn_htr.STATE.BURN_FULL
            heater.status_text = 'Burning Paused: Heat maximum'
        end
    end
end

function furn_htr.check_new_processing(heater)
    if heater.state ~= furn_htr.STATE.IDLE or heater.heat_level == heater.max_heat then return end
    local in_inv, in_list = base_mach.get_input(heater)
    if not in_inv then
        heater.status_text = 'No input'
    end
    for slot=1,in_inv:get_size(in_list) do
        local input_stack = in_inv:get_stack(in_list, slot)
        local cook_result
        local cook_after
        cook_result, cook_after = minetest.get_craft_result({method = 'fuel', width = 1, items = {input_stack}})
        if cook_result.time ~= 0 then
            heater.state = furn_htr.STATE.BURNING
            in_inv:set_stack(in_list, slot, cook_after.items[1])
            heater.inv:set_stack('burn', 1, input_stack)
            heater.state_time = cook_result.time / 2
            heater.status_text = 'Accepting ' .. input_stack:get_definition().description .. ' for burning...'
            return
        end
    end
    heater.status_text = 'Idle'
end

function furn_htr.tick(pos, dt)
    -- read state from meta
    local heater = base_mach.tick_read_state(pos)
    local venting
    if base_mach.check_overheat(heater, opts.MAX_HEAT) then
        venting = true
    else
        furn_htr.do_processing(heater, dt)
        furn_htr.check_new_processing(heater)
    end

    if (not venting) and heater.heat_xfer_mode == base_mach.HEAT_XFER_MODE.PROVIDE_ONLY then
        base_mach.push_heat_adjacent(heater, opts.HEAT_TRANSFER_RATE)
    end

    -- remain active if currently burning something or have any heat (for distribution)
    if heater.state == furn_htr.STATE.BURNING then
        base_mach.set_timer(heater)
        base_mach.set_node(pos, furn_htr.lit_id)
        base_mach.generate_smoke(pos)
    elseif heater.state == furn_htr.STATE.BURN_FULL then
        base_mach.set_timer(heater)
    else
        base_mach.set_node(pos, furn_htr.unlit_id)
        if heater.heat_level > 0 then base_mach.set_timer(heater) end
    end

    if venting or base_mach.has_upgrade(heater, 'ext_input') then base_mach.set_timer(heater) end
    -- write status back to meta
    base_mach.write_state(pos, heater)

end

furn_htr.unlit_nodedef = base_mach.nodedef{
    -- node properties
    description = "Furnace Heater",
    tiles = {
        terumet.tex('raw_heater_sides'), terumet.tex('raw_heater_sides'),
        terumet.tex('raw_heater_sides'), terumet.tex('raw_heater_sides'),
        terumet.tex('raw_heater_sides'), terumet.tex('htr_furnace_front_unlit')
    },
    -- callbacks
    on_construct = furn_htr.init,
    on_timer = furn_htr.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Furnace Heater',
        timer = 0.5,
        fsdef = FSDEF,
        -- heatlines cannot send heat to this machine
        heatline_target = false,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        drop_id = furn_htr.unlit_id,
        on_external_heat = terumet.NO_FUNCTION,
        get_drop_contents = furn_htr.get_drop_contents
    }
}

furn_htr.lit_nodedef = {}
for k,v in pairs(furn_htr.unlit_nodedef) do furn_htr.lit_nodedef[k] = v end
furn_htr.lit_nodedef.on_construct = nil -- lit node shouldn't be constructed by player
furn_htr.lit_nodedef.tiles = {
    terumet.tex('raw_heater_sides'), terumet.tex('raw_heater_sides'),
    terumet.tex('raw_heater_sides'), terumet.tex('raw_heater_sides'),
    terumet.tex('raw_heater_sides'), terumet.tex('htr_furnace_front_lit')
}
furn_htr.lit_nodedef.groups=terumet.create_lit_node_groups(furn_htr.unlit_nodedef.groups)
furn_htr.lit_nodedef.light_source = 10


base_mach.define_machine_node(furn_htr.unlit_id, furn_htr.unlit_nodedef)
base_mach.define_machine_node(furn_htr.lit_id, furn_htr.lit_nodedef)

minetest.register_craft{ output = furn_htr.unlit_id, recipe = {
    {terumet.id('item_coil_tcop'), 'default:furnace', terumet.id('item_coil_tcop')},
    {terumet.id('item_ceramic'), terumet.id('frame_raw'), terumet.id('item_ceramic')},
    {terumet.id('item_coil_tcop'), terumet.id('block_tcop'), terumet.id('item_coil_tcop')}
}}