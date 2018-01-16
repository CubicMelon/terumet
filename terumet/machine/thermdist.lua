local opts = terumet.options.thermdist
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_tdist = {}
base_tdist.id = terumet.id('mach_thermdist')

-- state identifier consts
base_tdist.STATE = {}
base_tdist.STATE.PULLING = 0

function base_tdist.generate_formspec(box)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --fuel slot
    base_mach.fs_fuel_slot(box,3.5,0)..
    --output slot
    base_mach.fs_output(box,3.5,2,1,1)..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    base_mach.fs_owner(box,5,0)..
    base_mach.fs_upgrades(box,6.75,1)..
    --current status
    'label[0,0;Thermal Distributor]'..
    'label[0,0.5;' .. box.status_text .. ']'..
    base_mach.fs_heat_info(box,1,1.5)..
    base_mach.fs_heat_mode(box,1,4)
    return fs
end

function base_tdist.generate_infotext(box)
    return string.format('Thermal Distributor (%.1f%% heat): %s', base_mach.heat_pct(box), box.status_text)
end

function base_tdist.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('out', 1)
    inv:set_size('upgrade', 2)
    local init_box = {
        class = base_tdist.nodedef._terumach_class,
        state = base_tdist.STATE.PULLING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.ACCEPT,
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
    if tbox.heat_level == 0 then
        tbox.status_text = "Waiting for heat..."
        return
    end

    local facing_dir = base_mach.FACING_DIRECTION[tbox.facing]
    local input_sides = {}
    input_sides[facing_dir] = true
    base_mach.push_heat_adjacent(tbox, opts.HEAT_TRANSFER_RATE, input_sides)
    tbox.status_text = "Distributing heat to orange sides"
end

function base_tdist.tick(pos, dt)
    -- read state from meta
    local tbox = base_mach.read_state(pos)
    if not base_mach.check_heat_max(tbox, opts.MAX_HEAT) then
        base_mach.process_fuel(tbox)
        base_tdist.do_processing(tbox, dt)
    end
    -- write status back to meta
    base_mach.write_state(pos, tbox)
    base_mach.set_timer(tbox)
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
        drop_id = base_tdist.id,
        on_external_heat = nil,
        on_inventory_change = nil,
        get_drop_contents = base_tdist.get_drop_contents,
        on_write_state = function(tbox)
            tbox.meta:set_string('formspec', base_tdist.generate_formspec(tbox))
            tbox.meta:set_string('infotext', base_tdist.generate_infotext(tbox))
        end
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
