local opts = terumet.options.heater.entropy
-- local base_opts = terumet.options.machine

local base_mach = terumet.machine

local ent_htr = {}
ent_htr.id = terumet.id('mach_htr_entropy')

-- state identifier consts
ent_htr.STATE = {}
ent_htr.STATE.FINDING = 0
ent_htr.STATE.DRAINING = 1
ent_htr.STATE.DRAIN_FULL = 2

local FSDEF = {
    status_text={x=2,y=0},
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE
    },
    machine = function(machine)
        local fs = ''
        if machine.state ~= ent_htr.STATE.FINDING then
            fs=fs..string.format('item_image[3,1;2,2;%s]label[3,3;%d HU/second]', machine.inv:get_stack('drain',1):get_name(), machine.heat_rate)
        end
        return fs
    end
}

function ent_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('upgrade', 6)
    inv:set_size('drain', 1)
    local init_heater = {
        class = ent_htr.nodedef._terumach_class,
        state = ent_htr.STATE.FINDING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos,
    }
    base_mach.write_state(pos, init_heater)
    base_mach.set_timer(init_heater)
end

function ent_htr.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

local PARTICLE_DATA = {
    expiration = 0.6,
    glow = 1,
    size = 2.0,
    texture = 'terumet_part_entropy.png',
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 0.8,
    }
}

function ent_htr.do_processing(machine, dt)
    if machine.state == ent_htr.STATE.FINDING then
        if machine.search_pos then
            machine.search_pos.y = machine.search_pos.y - 1
            if machine.search_pos.y < (machine.pos.y - opts.MAX_RANGE.y) then
                machine.search_pos.y = machine.pos.y + opts.MAX_RANGE.y
                machine.search_pos.x = machine.search_pos.x - 1
                if machine.search_pos.x < (machine.pos.x - opts.MAX_RANGE.x) then
                    machine.search_pos.x = machine.pos.x + opts.MAX_RANGE.x
                    machine.search_pos.z = machine.search_pos.z - 1
                    if machine.search_pos.z < (machine.pos.z - opts.MAX_RANGE.z) then
                        machine.search_pos = nil
                    end
                end
            end
        end
        if not machine.search_pos then
            -- reset
            machine.search_pos = util3d.pos_plus(machine.pos, opts.MAX_RANGE)
        end
        local found_node = minetest.get_node_or_nil(machine.search_pos)
        if found_node then
            local effects = opts.EFFECTS[found_node.name]
            if not effects then
                -- check groups for definition
                local def = minetest.registered_nodes[found_node.name]
                effects = terumet.match_group_key(opts.EFFECTS, def)
            end
            if effects then
                machine.state = ent_htr.STATE.DRAINING
                machine.inv:set_stack('drain', 1, found_node.name)
                machine.state_time = effects.time or opts.DEFAULT_DRAIN_TIME
                machine.heat_rate = effects.hups
                if effects.change then
                    found_node.name = effects.change
                    minetest.set_node(machine.search_pos, found_node)
                end
                machine.status_text = 'Starting extraction of ' .. machine.inv:get_stack('drain',1):get_name() .. ' at ' .. minetest.pos_to_string(machine.search_pos) .. '...'
                terumet.particle_stream(util3d.pos_plus(machine.pos, util3d.ADJACENT_OFFSETS.up), machine.search_pos, 5, PARTICLE_DATA)
            else
                local node_def = minetest.registered_nodes[found_node.name]
                local node_name = (node_def and node_def.description) or 'Undefined node'
                machine.status_text = node_name .. ' at ' .. minetest.pos_to_string(machine.search_pos) .. ' found but unusuable...'
            end
        else
            machine.status_text = minetest.pos_to_string(machine.search_pos) .. ' unloaded or invalid...'
        end
    else
        local gain = math.ceil(machine.heat_rate * dt)
        --if gain == 0 then return end -- no longer necessary?
        local under_cap = machine.heat_level < (machine.max_heat - gain)
        if machine.state == ent_htr.STATE.DRAIN_FULL and under_cap then
            machine.state = ent_htr.STATE.DRAINING
        end
        if machine.state == ent_htr.STATE.DRAINING then
            if under_cap then
                machine.state_time = machine.state_time - dt
                base_mach.gain_heat(machine, gain)
                if machine.state_time <= 0 then
                    machine.inv:set_stack('drain', 1, nil)
                    machine.status_text = 'Entropy extraction complete'
                    machine.state = ent_htr.STATE.FINDING
                else
                    machine.status_text = 'Extracting (' .. terumet.format_time(machine.state_time) .. ')'
                    base_mach.generate_particle(util3d.pos_plus(machine.pos, util3d.ADJACENT_OFFSETS.up), PARTICLE_DATA, 3)
                end
            else
                machine.state = ent_htr.STATE.DRAIN_FULL
                machine.status_text = 'Entropy extraction paused: Heat maximum'
            end
        end
    end
end

function ent_htr.tick(pos, dt)
    -- read state from meta
    local machine = base_mach.tick_read_state(pos)
    if not base_mach.check_overheat(machine, opts.MAX_HEAT) then
        local pos_above = util3d.pos_plus(pos, util3d.ADJACENT_OFFSETS.up)
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
    description = "EEE Heater",
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
        name = 'Environmental Entropy Extraction Heater',
        timer = 0.5,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        on_external_heat = terumet.NO_FUNCTION,
        on_inventory_change = terumet.NO_FUNCTION,
        get_drop_contents = ent_htr.get_drop_contents,
        -- heatlines cannot send heat to this machine
        heatline_target = false,
        on_read_state = function(machine)
            machine.heat_rate = machine.meta:get_float('heat_rate')
            machine.search_pos = minetest.string_to_pos(machine.meta:get_string('search_pos'))
        end,
        on_write_state = function(machine)
            machine.meta:set_float('heat_rate', machine.heat_rate or 0)
            if machine.search_pos then
                machine.meta:set_string('search_pos', minetest.pos_to_string(machine.search_pos))
            else
                machine.meta:set_string('search_pos', '')
            end
        end,
    }
}

base_mach.define_machine_node(ent_htr.id, ent_htr.nodedef)

minetest.register_craft{ output = ent_htr.id, recipe = {
    {terumet.id('item_upg_gen_up'), terumet.id('item_htglass'), terumet.id('item_upg_gen_up')},
    {terumet.id('item_entropy'), terumet.id('frame_cgls'), terumet.id('item_entropy')},
    {terumet.id('block_ceramic'), terumet.id('item_entropy'), terumet.id('block_ceramic')}
}}