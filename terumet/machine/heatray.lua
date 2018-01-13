local opts = terumet.options.heat_ray
local base_opts = terumet.options.machine
local base_mach = terumet.machine

local base_ray = {}
base_ray.id = terumet.id('mach_hray')

-- state identifier consts
base_ray.STATE = {}
base_ray.STATE.WAITING = 0
base_ray.STATE.SEEKING = 1

function base_ray.generate_formspec(ray)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    --current status
    'label[0,0;HEAT Ray Emitter]'..
    'label[0,0.5;' .. ray.status_text .. ']'..
    base_mach.fs_heat_info(ray,4.25,1.5)..
    -- testing facing info
    string.format('label[0,1;I am facing %s]', base_mach.FACING_DIRECTION[ray.facing])..
    string.format('label[0,1.5;So forward is %s]', dump(base_mach.FACING_OFFSETS[ray.facing]))..
    --list rings
    'listring[current_player;main]'..
	'listring[context;fuel]'..
    'listring[current_player;main]'..
    'listring[context;out]'
    return fs
end

function base_ray.generate_infotext(ray)
    return string.format('HEAT Ray Emitter (%.1f%% heat): %s', base_mach.heat_pct(ray), ray.status_text)
end

function base_ray.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    local init_ray = {
        class = base_ray.nodedef._terumach_class,
        state = base_ray.STATE.WAITING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.ACCEPT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_ray)
end

function base_ray.tick(pos, dt)
    -- read state from meta
    local ray = base_mach.read_state(pos)

    --[[ TODO BLAH BLAH

    if ray.state ~= base_ray.STATE.IDLE and (not ray.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        base_mach.set_timer(ray)
        base_mach.set_node(pos, base_ray.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, base_ray.unlit_id)
    end
    ]]--
    -- write status back to meta
    base_mach.set_timer(ray)
    base_mach.write_state(pos, ray)

end

-- callback when minetest screwdriver used on node
function base_ray.on_screwdriver(pos, node, user, mode, new_param2)
    -- return nil for default behavior, false to deny use, true to say "i rotated it myself, apply wear to screwdriver"
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
        timer = 1.0,
        drop_id = base_ray.id,
        --get_drop_contents = base_ray.get_drop_contents,
        on_write_state = function(htfurnace)
            htfurnace.meta:set_string('formspec', base_ray.generate_formspec(htfurnace))
            htfurnace.meta:set_string('infotext', base_ray.generate_infotext(htfurnace))
        end
    }
}

minetest.register_node(base_ray.id, base_ray.nodedef)

minetest.register_craft{ output = base_ray.id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_htglass'), terumet.id('item_coil_tgol')},
    {terumet.id('item_ceramic'), terumet.id('frame_cgls'), terumet.id('item_ceramic')},
    {terumet.id('item_coil_tgol'), terumet.id('item_heatunit'), terumet.id('item_coil_tgol')}
}}