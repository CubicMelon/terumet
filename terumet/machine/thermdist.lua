local opts = terumet.options.thermdist
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_tdist = {}
base_tdist.id = terumet.id('mach_thermdist')

base_tdist.STATE = {}
base_tdist.STATE.IDLE = 0
base_tdist.STATE.ACTIVE = 1

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    fuel_slot = {true},
}

function base_tdist.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('out', 1)
    inv:set_size('upgrade', 2)
    local init_box = {
        class = base_tdist.nodedef._terumach_class,
        state = base_tdist.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_box)
    base_mach.set_timer(init_box)
end

function base_tdist.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    default.get_inventory_drops(machine.pos, 'fuel', drops)
    default.get_inventory_drops(machine.pos, 'out', drops)
    return drops
end

function base_tdist.do_processing(tbox, dt)
    if (tbox.heat_xfer_mode == base_mach.HEAT_XFER_MODE.NO_XFER) or (tbox.heat_level <= 0) then
        tbox.status_text = "Idle"
        tbox.state = base_tdist.STATE.IDLE
        return
    end
    -- ignore node in output direction (facing dir)
    local facing_dir = util3d.FACING_DIRECTION[tbox.facing]
    base_mach.push_heat_adjacent(tbox, opts.HEAT_TRANSFER_RATE, {facing_dir})
    tbox.status_text = "Distributing heat to orange sides"
    tbox.state = base_tdist.STATE.ACTIVE
end

function base_tdist.tick(pos, dt)
    -- read state from meta
    local tbox = base_mach.read_state(pos)
    local venting = false

    if base_mach.check_overheat(tbox, opts.MAX_HEAT) then
        venting = true
    else
        base_mach.process_fuel(tbox)
        base_tdist.do_processing(tbox, dt)
    end
    
    -- write status back to meta
    base_mach.write_state(pos, tbox)
    return venting or (tbox.state == base_tdist.STATE.ACTIVE)
end

base_tdist.nodedef = base_mach.nodedef{
    -- node properties
    description = "Thermal Distributor",
    tiles = {
        terumet.tex('tdis_front'), terumet.tex('tdis_back'), terumet.tex('tdis_sides')
    },
    sounds = default.node_sound_glass_defaults(),
    -- callbacks
    on_construct = base_tdist.init,
    on_timer = base_tdist.tick,
    on_rotate = function() return nil end, -- default rotation
    -- terumet machine class data
    _terumach_class = {
        name = 'Thermal Distributor',
        timer = 1.0,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_tdist.id,
        get_drop_contents = base_tdist.get_drop_contents,
    }
}

minetest.register_node(base_tdist.id, base_tdist.nodedef)

minetest.register_craft{ output = base_tdist.id,
    recipe = {
        {terumet.id('item_coil_raw'), terumet.id('item_coil_tcop'), terumet.id('item_coil_raw')},
        {terumet.id('item_coil_tcop'), terumet.id('block_ceramic'), terumet.id('item_coil_tcop')},
        {terumet.id('item_coil_raw'), terumet.id('item_coil_tcop'), terumet.id('item_coil_raw')}
    }
}
