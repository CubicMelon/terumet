local opts = terumet.options.furnace
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_htf = {}
base_htf.unlit_id = terumet.id('mach_htfurn')
base_htf.lit_id = terumet.id('mach_htfurn_lit')

-- time between furnace ticks
base_htf.timer = 0.5

-- state identifier consts
base_htf.STATE = {}
base_htf.STATE.IDLE = 0
base_htf.STATE.COOKING = 1

function base_htf.start_timer(pos)
    minetest.get_node_timer(pos):start(base_htf.timer)
end

function base_htf.generate_formspec(furnace)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    --input inventory
    'list[context;inp;0,1.5;2,2;]'..
    'label[0.5,3.5;Input Slots]'..
    --output inventory
    'list[context;out;6,1.5;2,2;]'..
    'label[6.5,3.5;Output Slots]'..
    --fuel slot
    base_mach.fs_fuel_slot(furnace,6.5,0)..
    --current status
    'label[0,0;High-Temperature Furnace]'..
    'label[0,0.5;' .. furnace.status_text .. ']'..
    base_mach.fs_heat_info(furnace,4.25,1.5)
    if furnace.state == base_htf.STATE.COOKING then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..furnace.inv:get_stack('result',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;inp]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function base_htf.generate_infotext(furnace)
    return string.format('High-Temp Furnace (%.0f%% heat): %s', base_mach.heat_pct(furnace), furnace.status_text)
end

function base_htf.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('inp', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)

    local init_furnace = {
        state = base_htf.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta
    }
    base_mach.write_state(pos, init_furnace, base_htf.generate_formspec(init_furnace), base_htf.generate_infotext(init_furnace))
end

function base_htf.get_drops(pos, include_self)
    local drops = {}
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "inp", drops)
    default.get_inventory_drops(pos, "out", drops)
    if include_self then drops[#drops+1] = base_htf.unlit_id end
    return drops
end

function base_htf.do_processing(furnace, dt)
    if furnace.state == base_htf.STATE.COOKING and base_mach.expend_heat(furnace, opts.COST_COOKING_HU, 'Cooking') then
        local result_stack = furnace.inv:get_stack('result', 1)
        local result_name = result_stack:get_definition().description
        furnace.state_time = furnace.state_time - dt
        if furnace.state_time <= 0 then
            if furnace.inv:room_for_item('out', result_stack) then
                furnace.inv:set_stack('result', 1, nil)
                furnace.inv:add_item('out', result_stack)
                furnace.state = base_htf.STATE.IDLE
            else
                furnace.status_text = result_name .. ' ready - no space!'
                furnace.state_time = -0.1
            end
        else
            furnace.status_text = 'Cooking ' .. result_name .. ' (' .. terumet.format_time(furnace.state_time) .. ')'
        end
    end
end

function base_htf.check_new_processing(furnace)
    if furnace.state ~= base_htf.STATE.IDLE then return end
    local cook_result
    local cook_after
    for slot = 1,4 do
        local input_stack = furnace.inv:get_stack('inp', slot)
        cook_result, cook_after = minetest.get_craft_result({method = 'cooking', width = 1, items = {input_stack}})
        if cook_result.time ~= 0 then
            furnace.state = base_htf.STATE.COOKING
            furnace.inv:set_stack('inp', slot, cook_after.items[1])
            furnace.inv:set_stack('result', 1, cook_result.item)
            furnace.state_time = math.floor(cook_result.time * opts.TIME_MULT * base_htf.timer)
            furnace.status_text = 'Accepting ' .. input_stack:get_definition().description .. ' for cooking...'
            return
        end
    end
    furnace.status_text = 'Idle'
end

function base_htf.tick(pos, dt)
    -- read state from meta
    local furnace = base_mach.read_state(pos)

    base_htf.do_processing(furnace, dt)

    base_htf.check_new_processing(furnace)

    base_mach.process_fuel(furnace)

    if furnace.state ~= base_htf.STATE.IDLE and (not furnace.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        base_htf.start_timer(pos)
        base_mach.set_node(pos, base_htf.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, base_htf.unlit_id)
    end

    -- write status back to meta
    base_mach.write_state(pos, furnace, base_htf.generate_formspec(furnace), base_htf.generate_infotext(furnace))

end

function base_htf.on_destruct(pos)
    for _,item in ipairs(base_htf.get_drops(pos, false)) do
        minetest.add_item(pos, item)
    end
end

function base_htf.on_blast(pos)
    drops = base_htf.get_drops(pos, true)
    minetest.remove_node(pos)
    return drops
end

base_htf.unlit_nodedef = {
    -- node properties
    description = "High-Temperature Furnace",
    tiles = {
        terumet.tex('htfurn_top_unlit'), terumet.tex('block_ceramic'),
        terumet.tex('htfurn_sides'), terumet.tex('htfurn_sides'),
        terumet.tex('htfurn_sides'), terumet.tex('htfurn_front')
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
    on_construct = base_htf.init,
    on_metadata_inventory_move = base_htf.start_timer,
    on_metadata_inventory_put = base_htf.start_timer,
    on_metadata_inventory_take = base_htf.start_timer,
    on_timer = base_htf.tick,
    on_destruct = base_htf.on_destruct,
    on_blast = base_htf.on_blast,
}

base_htf.lit_nodedef = {}
for k,v in pairs(base_htf.unlit_nodedef) do base_htf.lit_nodedef[k] = v end
base_htf.lit_nodedef.on_construct = nil -- lit node shouldn't be constructed by player
base_htf.lit_nodedef.tiles = {
    terumet.tex('htfurn_top_lit'), terumet.tex('block_ceramic'),
    terumet.tex('htfurn_sides'), terumet.tex('htfurn_sides'),
    terumet.tex('htfurn_sides'), terumet.tex('htfurn_front')
}
base_htf.lit_nodedef.groups={cracky=1, not_in_creative_inventory=1}
base_htf.lit_nodedef.drop = base_htf.unlit_id
base_htf.lit_nodedef.light_source = 10


minetest.register_node(base_htf.unlit_id, base_htf.unlit_nodedef)
minetest.register_node(base_htf.lit_id, base_htf.lit_nodedef)

minetest.register_craft{ output = base_htf.unlit_id, recipe = {
    {terumet.id('item_coil_tcop'), terumet.id('item_coil_tcop'), terumet.id('item_coil_tcop')},
    {terumet.id('item_ceramic'), terumet.id('frame_tste'), terumet.id('item_ceramic')},
    {terumet.id('item_ceramic'), terumet.id('item_ceramic'), terumet.id('item_ceramic')}
}}