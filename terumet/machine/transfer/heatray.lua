local opts = terumet.options.heat_ray
--local base_opts = terumet.options.machine
local base_mach = terumet.machine

local base_ray = {}
base_ray.id = terumet.id('mach_hray')
base_ray.reflector_id = terumet.id('block_rayref')

-- state identifier consts
base_ray.STATE = {}
base_ray.STATE.WAITING = 0

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
        {flag='show_seeking', icon='terumet_part_seek.png', name='seek_toggle', on_text='Seeking visible', off_text='Seeking not visible'}
    },
    machine = function(machine)
        return string.format('label[0,1;:Last result: %s]', machine.last_error or 'none')
    end
}

local FORM_ACTION = function(ray, fields, player)
    if fields.seek_toggle then
        ray.show_seeking = not ray.show_seeking
        ray.meta:set_int('opt_seek', (ray.show_seeking and 1) or 0)
        return true -- update formspec
    end
end

function base_ray.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    local init_ray = {
        class = base_ray.nodedef._terumach_class,
        state = base_ray.STATE.WAITING,
        show_seeking = false,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_ray)
    base_mach.set_timer(init_ray)
end

function base_ray.read_search(meta)
    local active = meta:get_int('search_active')
    if active == 1 then
        --minetest.log('error', 'reading search pos='..meta:get_string('search_pos'))
        local spos = minetest.string_to_pos(meta:get_string('search_pos'))
        local sdir = meta:get_int('search_dir')
        local sdist = meta:get_int('search_dist')
        return {pos=spos, dir=sdir, dist=sdist}
    else
        return nil
    end
end

function base_ray.write_search(meta, search)
    if search then
        --minetest.log('error', 'writing search pos='..minetest.pos_to_string(search.pos))
        meta:set_string('search_pos', minetest.pos_to_string(search.pos))
        meta:set_int('search_dir', search.dir)
        meta:set_int('search_dist', search.dist)
        meta:set_int('search_active', 1)
    else
        meta:set_int('search_active', 0)
    end
end

function base_ray.set_search_result(ray, msg)
    ray.status_text = 'End: '..msg
    ray.last_error = msg
end

function base_ray.goto_next_node(ray, search)
    local npos = util3d.pos_plus(search.pos, util3d.FACING_OFFSETS[search.dir])
    local npos_node = minetest.get_node_or_nil(npos)
    if not npos_node then
        base_ray.set_search_result(ray, 'Unloaded area at ' .. minetest.pos_to_string(npos))
        return nil
    end

    local npos_nodedef = minetest.registered_nodes[npos_node.name]
    if not npos_nodedef then
        base_ray.set_search_result(ray, 'Unknown node at ' .. minetest.pos_to_string(npos))
        return nil
    end

    if npos_nodedef._terumach_class then
        -- hit a target!
        search.hit = true
        search.pos = npos
        return search
    elseif npos_node.name == base_ray.reflector_id then
        -- hit a deflector
        search.pos = npos
        -- for particle purposes, do not create particles for this section
        search.invisible = true
        search.dir = math.floor(npos_node.param2 / 4) -- facing of deflector
        -- don't add 1 to distance, deflectors are free
        ray.status_text = "Reflected... " .. minetest.pos_to_string(search.pos)
    elseif npos_nodedef.sunlight_propagates then
        -- hit a node ray can pass
        search.dist = search.dist + 1
        if search.dist > opts.MAX_DISTANCE then
            base_ray.set_search_result(ray, 'Maximum range at ' .. minetest.pos_to_string(npos))
            return nil
        end
        ray.status_text = "Seeking... " .. minetest.pos_to_string(search.pos)
        search.pos = npos
    else
        base_ray.set_search_result(ray, string.format('Obstruction (%s) at %s', npos_nodedef.description or npos_node.name, minetest.pos_to_string(npos)))
        return nil
    end

    return search
end

function base_ray.fire(ray, target)
    local ray_path = {}
    -- first trace path fully to ensure no obstructions
    local trace = {pos=ray.pos, dir=ray.facing, dist=0}
    local last = ray.pos
    while trace and not trace.hit do
        trace = base_ray.goto_next_node(ray, trace)
        if trace and (not trace.invisible) and opts.RAY_PARTICLES_PER_NODE and (opts.RAY_PARTICLES_PER_NODE > 0) then
            local xstep = (trace.pos.x - last.x) / opts.RAY_PARTICLES_PER_NODE
            local ystep = (trace.pos.y - last.y) / opts.RAY_PARTICLES_PER_NODE
            local zstep = (trace.pos.z - last.z) / opts.RAY_PARTICLES_PER_NODE
            for pn = 1, opts.RAY_PARTICLES_PER_NODE do
                ray_path[#ray_path + 1] = {x=last.x + (xstep * pn), y=last.y + (ystep * pn), z=last.z + (zstep * pn)}
            end
            last = trace.pos
        end
        if trace then trace.invisible = false end
    end

    -- if we hit the expected target, create the particles and send the heat!
    if trace and trace.hit and vector.equals(target.pos, trace.pos) then
        for _,ppos in pairs(ray_path) do
            minetest.add_particle{
                pos=ppos,
                velocity=terumet.random_velocity(5),
                expirationtime=1,
                size=1,
                texture='terumet_part_ray.png',
                animation=base_ray.PARTICLE_ANIMATION,
                glow=100,
            }
        end
        base_mach.push_heat_single(ray, target, opts.SEND_AMOUNT)
        base_ray.set_search_result(ray, 'Successful fire at ' .. target.class.name .. ' at ' .. minetest.pos_to_string(target.pos) .. '!')
    end
end

base_ray.PARTICLE_ANIMATION = {
    type = "vertical_frames",
    aspect_w = 16,
    aspect_h = 16,
    length = 1.1,
}

function base_ray.tick(pos, dt)
    -- read state from meta
    local ray = base_mach.tick_read_state(pos)

    if ray.heat_level < opts.SEND_AMOUNT then
        ray.status_text = 'Waiting for enough heat...'
    else
        local search = base_ray.read_search(ray.meta)
        if search then
            search = base_ray.goto_next_node(ray, search)
            if search then
                if search.hit then
                    -- do hit!
                    local hit_machine = base_mach.read_state(search.pos)
                    if hit_machine then
                        if hit_machine.heat_xfer_mode == base_mach.HEAT_XFER_MODE.ACCEPT and hit_machine.heat_level < hit_machine.max_heat then
                            base_ray.fire(ray, hit_machine)
                        else
                            base_ray.set_search_result(ray, hit_machine.class.name .. ' at ' .. minetest.pos_to_string(search.pos) .. ' does not require heat')
                        end
                    else
                        base_ray.set_search_result(ray, 'Machine at ' .. minetest.pos_to_string(search.pos) .. ' could not be loaded')
                    end
                    search = nil
                else
                    if ray.show_seeking then
                        minetest.add_particle{
                            pos=search.pos,
                            velocity={x=0, y=0, z=0},
                            expirationtime=0.5,
                            size=4.0,
                            texture='terumet_part_seek.png',
                            --animation=base_ray.PARTICLE_ANIMATION,
                            glow=100,
                        }
                    end
                end
            end
        else
            search = {pos=ray.pos, dir=ray.facing, dist=0}
            ray.status_text = 'Begin seeking'
        end
        base_ray.write_search(ray.meta, search)
    end
    base_mach.set_timer(ray)
    base_mach.write_state(pos, ray)

end

-- callback when minetest screwdriver used on node
function base_ray.on_screwdriver(pos, node, user, mode, new_param2)
    -- return nil for default behavior, false to deny use, true to say "i rotated it myself, apply wear to screwdriver"
    -- clear any searching data to force restart
    base_ray.write_search(minetest.get_meta(pos), nil)
    return nil
end

base_ray.nodedef = base_mach.nodedef{
    -- node properties
    description = "HEAT Ray Emitter",
    tiles = {
        terumet.tex('hray_front'), terumet.tex('hray_back'), terumet.tex('hray_sides')
    },
    -- callbacks
    on_construct = base_ray.init,
    on_timer = base_ray.tick,
    on_rotate = base_ray.on_screwdriver,
    -- terumet machine class data
    _terumach_class = {
        name = 'HEAT Ray Emitter',
        timer = 0.2,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        on_form_action = FORM_ACTION,
        drop_id = base_ray.id,
        on_external_heat = nil,
        on_inventory_change = nil,
        on_read_state = function(ray)
            ray.last_error = ray.meta:get_string('last_error')
            ray.show_seeking = (ray.meta:get_int('opt_seek') or 0) == 1
        end,
        on_write_state = function(ray)
            ray.meta:set_string('last_error', ray.last_error or 'none')
            -- opt seek is set by form action
        end
    }
}

base_mach.define_machine_node(base_ray.id, base_ray.nodedef)

minetest.register_craft{ output = base_ray.id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_htglass'), terumet.id('item_coil_tgol')},
    {terumet.id('item_ceramic'), terumet.id('frame_cgls'), terumet.id('item_ceramic')},
    {terumet.id('item_coil_tgol'), terumet.id('item_heatunit'), terumet.id('item_coil_tgol')}
}}


minetest.register_node( base_ray.reflector_id, {
    description = 'HEAT Ray Reflector',
    stack_max = 99,
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    paramtype2 = 'facedir',
    groups = {cracky=2},
    tiles = {
        terumet.tex('rayref_front'), terumet.tex('rayref_back'), terumet.tex('rayref_sides')
    }
})

minetest.register_craft{ output = base_ray.reflector_id, recipe = {
    {terumet.id('ingot_raw'), terumet.id('item_htglass'), terumet.id('ingot_raw')},
    {terumet.id('item_htglass'), 'default:tin_ingot', terumet.id('item_htglass')},
    {terumet.id('ingot_raw'), terumet.id('item_htglass'), terumet.id('ingot_raw')}
}}