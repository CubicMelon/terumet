local opts = terumet.options.heater.entropy
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local ent_htr = {}
ent_htr.id = terumet.id('mach_htr_entropy')

-- state identifier consts
ent_htr.STATE = {}
ent_htr.STATE.GENERATING = 0

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE
    },
    machine = function(machine)
        local fs = 'label[3,2;NOT DOING ANYTHING YET BOSS]'
        return fs
    end
}

function ent_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('upgrade', 6)

    local init_heater = {
        class = ent_htr.nodedef._terumach_class,
        state = ent_htr.STATE.GENERATING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_heater)
    base_mach.set_timer(init_heater)
end

function ent_htr.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function ent_htr.do_processing(machine, dt)
    machine.status_text = "Matrix in position!"
end

function ent_htr.tick(pos, dt)
    -- read state from meta
    local machine = base_mach.read_state(pos)
    if not base_mach.check_overheat(machine, opts.MAX_HEAT) then
        local pos_above = terumet.pos_plus(pos, base_mach.ADJACENT_OFFSETS.up)
        local node_above = minetest.get_node_or_nil(pos_above)
        if node_above and node_above.name == terumet.id('block_entropy') then
            ent_htr.do_processing(machine, dt)
        else
            machine.status_text = 'Requires Entropy Matrix directly above'
        end
        if machine.heat_xfer_mode == base_mach.HEAT_XFER_MODE.PROVIDE_ONLY then
            base_mach.push_heat_adjacent(machine, opts.HEAT_TRANSFER_RATE)
        end
    end
    -- write status back to meta
    base_mach.write_state(pos, machine)
    base_mach.set_timer(machine)
end

ent_htr.nodedef = base_mach.nodedef{
    -- node properties
    description = "Accelerated Entropy Heater",
    tiles = {
        terumet.tex('htr_entropy_top'), terumet.tex('cgls_heater_sides'),
        terumet.tex('cgls_heater_sides'), terumet.tex('cgls_heater_sides'),
        terumet.tex('cgls_heater_sides'), terumet.tex('cgls_heater_sides')
    },
    paramtype2 = 'none',
    -- callbacks
    on_construct = ent_htr.init,
    on_timer = ent_htr.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Accelerated Entropy Heater',
        timer = 1.0,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        on_external_heat = terumet.NO_FUNCTION,
        get_drop_contents = ent_htr.get_drop_contents,
    }
}

minetest.register_node(ent_htr.id, ent_htr.nodedef)

minetest.register_craft{ output = ent_htr.id, recipe = {
    {terumet.id('item_upg_gen_up'), terumet.id('item_htglass'), terumet.id('item_upg_gen_up')},
    {terumet.id('item_entropy'), terumet.id('frame_cgls'), terumet.id('item_entropy')},
    {terumet.id('block_ceramic'), terumet.id('item_entropy'), terumet.id('block_ceramic')}
}}