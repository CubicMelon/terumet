local opts = terumet.options.thermobox
local util3d = terumet.util3d

local base_mach = terumet.machine

local base_tbox = {}
base_tbox.id = terumet.id('mach_thermobox')

-- state identifier consts
base_tbox.STATE = {}
base_tbox.STATE.IDLE = 0
base_tbox.STATE.ACTIVE = 1

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    bg='gui_backc',
    fuel_slot={true},
    battery_slot={true},
}

function base_tbox.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('upgrade', 2)
    inv:set_size('fuel', 1)
    inv:set_size('battery', 1)
    local init_box = {
        class = base_tbox.nodedef._terumach_class,
        state = base_tbox.STATE.IDLE,
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

function base_tbox.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    default.get_inventory_drops(machine.pos, 'battery', drops)
    default.get_inventory_drops(machine.pos, 'fuel', drops)
    return drops
end

function base_tbox.do_processing(tbox, dt)
    if tbox.heat_level == 0 then
        tbox.status_text = "Idle"
        tbox.state = base_tbox.STATE.IDLE
        return
    end
    local out_pos = util3d.pos_plus(tbox.pos, util3d.FACING_OFFSETS[tbox.facing])
    local out_mach = base_mach.read_state(out_pos)
    if out_mach then
        local res = base_mach.push_heat_single(tbox, out_mach, opts.HEAT_TRANSFER_RATE)
        if res and res > 0 then
            tbox.status_text = string.format('Providing heat to %s (%d last sent)', out_mach.class.name, res)
        else
            tbox.status_text = out_mach.class.name .. " does not require heat"
        end
    else
        tbox.status_text = "No output machine found"
    end
    tbox.state = base_tbox.STATE.ACTIVE
end

function base_tbox.tick(pos, dt)
    -- read state from meta
    local tbox = base_mach.tick_read_state(pos)
    base_mach.process_fuel(tbox)
    base_mach.process_battery(tbox)
    local venting = base_mach.check_overheat(tbox, opts.MAX_HEAT)
    if not venting then
        base_tbox.do_processing(tbox, dt)
    end
    -- write status back to meta
    base_mach.write_state(pos, tbox)
    return venting or (tbox.state == base_tbox.STATE.ACTIVE)
end

-- callback when minetest screwdriver used on node
function base_tbox.on_screwdriver(pos, node, user, mode, new_param2)
    -- wake up
    local machine = base_mach.read_state(pos)
    base_mach.set_timer(machine)
    return nil
end

base_tbox.nodedef = base_mach.nodedef{
    -- node properties
    description = "Thermobox",
    tiles = {
        terumet.tex('tbox_front'), terumet.tex('tbox_back'), terumet.tex('tbox_sides')
    },
    sounds = default.node_sound_glass_defaults(),
    -- callbacks
    on_construct = base_tbox.init,
    on_timer = base_tbox.tick,
    on_rotate = base_tbox.on_screwdriver,
    -- terumet machine class data
    _terumach_class = {
        name = 'Thermobox',
        valid_upgrades = terumet.valid_upgrade_sets(),
        timer = 1.0,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_tbox.id,
        get_drop_contents = base_tbox.get_drop_contents,
    }
}

base_mach.define_machine_node(base_tbox.id, base_tbox.nodedef)

minetest.register_craft{ output = base_tbox.id,
    recipe = {
        {terumet.id('item_coil_tgol'), terumet.id('item_thermese'), terumet.id('item_coil_tgol')},
        {terumet.id('item_thermese'), terumet.id('block_ceramic'), terumet.id('item_thermese')},
        {terumet.id('item_coil_tgol'), terumet.id('item_thermese'), terumet.id('item_coil_tgol')}
    }
}
