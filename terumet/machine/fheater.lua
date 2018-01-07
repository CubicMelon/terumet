local opts = terumet.options.heater
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_htr = {}
base_htr.unlit_id = terumet.id('mach_fheater')
base_htr.lit_id = terumet.id('mach_fheater_lit')

-- state identifier consts
base_htr.STATE = {}
base_htr.STATE.IDLE = 0
base_htr.STATE.BURNING = 1
base_htr.STATE.BURN_FULL = 2

function base_htr.generate_formspec(heater)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    --input inventory
    'list[context;inp;3,1.5;1,1;]'..
    --current status
    'label[0,0;Furnace Heater]'..
    'label[0,0.5;' .. heater.status_text .. ']'..
    base_mach.fs_heat_info(heater,4,1.5)
    if heater.state ~= base_htr.STATE.IDLE then
        fs=fs..'image[3,3;1,1;terumet_gui_product_bg.png]item_image[3,3;1,1;'..heater.inv:get_stack('burn',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;inp]"
    return fs
end

function base_htr.generate_infotext(heater)
    return string.format('Furnace Heater (%.1f%% heat): %s', base_mach.heat_pct(heater), heater.status_text)
end

function base_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('inp', 1)
    inv:set_size('burn', 1)

    local init_heater = {
        class = base_htr.unlit_nodedef._terumach_class,
        state = base_htr.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        status_text = 'New',
        inv = inv,
        meta = meta
    }
    base_mach.write_state(pos, init_heater)
end

function base_htr.get_drops(pos, include_self)
    local drops = {}
    default.get_inventory_drops(pos, "inp", drops)
    if include_self then drops[#drops+1] = base_htr.unlit_id end
    return drops
end

function base_htr.do_processing(heater, dt)
    local gain = math.floor(10 * dt) -- heat gain this tick
    if gain == 0 then return end
    local under_cap = heater.heat_level < (heater.max_heat - gain)
    if heater.state == base_htr.STATE.BURN_FULL and under_cap then
        heater.state = base_htr.STATE.BURNING
    end
    if heater.state == base_htr.STATE.BURNING then
        if under_cap then
            heater.state_time = heater.state_time - dt
            base_mach.gain_heat(heater, gain)
            if heater.state_time <= 0 then
                heater.inv:set_stack('burn', 1, nil)
                heater.status_text = 'Burn complete'
                heater.state = base_htr.STATE.IDLE
            else
                heater.status_text = 'Burning (' .. terumet.format_time(heater.state_time) .. ')'
            end
        else
            heater.state = base_htr.STATE.BURN_FULL
            heater.status_text = 'Burning Paused: Heat maximum'
        end
    end
end

function base_htr.check_new_processing(heater)
    if heater.state ~= base_htr.STATE.IDLE or heater.heat_level == heater.max_heat then return end
    local input_stack = heater.inv:get_stack('inp', 1)
    local cook_result
    local cook_after
    cook_result, cook_after = minetest.get_craft_result({method = 'fuel', width = 1, items = {input_stack}})
    if cook_result.time ~= 0 then
        heater.state = base_htr.STATE.BURNING
        heater.inv:set_stack('inp', 1, cook_after.items[1])
        heater.inv:set_stack('burn', 1, input_stack)
        heater.state_time = math.floor(cook_result.time * heater.class.timer)
        heater.status_text = 'Accepting ' .. input_stack:get_definition().description .. ' for burning...'
        return
    end
    heater.status_text = 'Idle'
end

function base_htr.tick(pos, dt)
    -- read state from meta
    local heater = base_mach.read_state(pos)

    base_htr.do_processing(heater, dt)

    base_htr.check_new_processing(heater)

    base_mach.push_heat_adjacent(heater, opts.HEAT_TRANSFER_RATE)
    -- remain active if currently burning something or have any heat (for distribution)
    if heater.state == base_htr.STATE.BURNING then
        base_mach.set_timer(heater)
        base_mach.set_node(pos, base_htr.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, base_htr.unlit_id)
        if heater.heat_level > 0 then base_mach.set_timer(heater) end
    end

    -- write status back to meta
    base_mach.write_state(pos, heater)

end

function base_htr.inventory_change(pos)
    base_htr.tick(pos, 0)
end

function base_htr.on_destruct(pos)
    for _,item in ipairs(base_htr.get_drops(pos, false)) do
        minetest.add_item(pos, item)
    end
end

function base_htr.on_blast(pos)
    drops = base_htr.get_drops(pos, true)
    minetest.remove_node(pos)
    return drops
end

base_htr.unlit_nodedef = {
    -- node properties
    description = "Furnace Heater",
    tiles = {
        terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
        terumet.tex('raw_sides_unlit'), terumet.tex('raw_sides_unlit'),
        terumet.tex('raw_sides_unlit'), terumet.tex('fheater_front_unlit')
    },
    paramtype2 = 'facedir',
    groups = {cracky=1},
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    legacy_facedir_simple = true,
    -- inventory slot control
    allow_metadata_inventory_put = base_mach.allow_put,
    allow_metadata_inventory_move = base_mach.allow_move,
    allow_metadata_inventory_take = base_mach.allow_take,
    -- callbacks
    on_construct = base_htr.init,
    on_metadata_inventory_move = base_htr.inventory_change,
    on_metadata_inventory_put = base_htr.inventory_change,
    on_metadata_inventory_take = base_htr.inventory_change,
    on_timer = base_htr.tick,
    on_destruct = base_htr.on_destruct,
    on_blast = base_htr.on_blast,
    -- terumet machine class data
    _terumach_class = {
        timer = 0.5,
        on_write_state = function(fheater)
            fheater.meta:set_string('formspec', base_htr.generate_formspec(fheater))
            fheater.meta:set_string('infotext', base_htr.generate_infotext(fheater))
        end
    }
}

base_htr.lit_nodedef = {}
for k,v in pairs(base_htr.unlit_nodedef) do base_htr.lit_nodedef[k] = v end
base_htr.lit_nodedef.on_construct = nil -- lit node shouldn't be constructed by player
base_htr.lit_nodedef.tiles = {
    terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
    terumet.tex('raw_sides_lit'), terumet.tex('raw_sides_lit'),
    terumet.tex('raw_sides_lit'), terumet.tex('fheater_front_lit')
}
base_htr.lit_nodedef.groups={cracky=1, not_in_creative_inventory=1}
base_htr.lit_nodedef.drop = base_htr.unlit_id
base_htr.lit_nodedef.light_source = 10


minetest.register_node(base_htr.unlit_id, base_htr.unlit_nodedef)
minetest.register_node(base_htr.lit_id, base_htr.lit_nodedef)

minetest.register_craft{ output = base_htr.unlit_id, recipe = {
    {terumet.id('item_coil_tcop'), 'default:furnace', terumet.id('item_coil_tcop')},
    {terumet.id('item_coil_tcop'), terumet.id('frame_raw'), terumet.id('item_coil_tcop')},
    {terumet.id('item_coil_tcop'), 'default:copperblock', terumet.id('item_coil_tcop')}
}}