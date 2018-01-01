local opts = terumet.options.smelter

local asmelt = {}
asmelt.full_id = terumet.id('mach_asmelt')
-- time between smelter ticks
asmelt.timer = 0.5

-- state identifier consts
asmelt.STATE = {}
asmelt.STATE.IDLE = 0
asmelt.STATE.FLUX_MELT = 1
asmelt.STATE.ALLOYING = 2

function asmelt.start_timer(pos)
    minetest.get_node_timer(pos):start(asmelt.timer)
end

function asmelt.generate_formspec(smelter)
    local heat_pct = 100.0 * smelter.heat_level / opts.FULL_HEAT
    local flux_pct = 100.0 * smelter.flux_tank / opts.FLUX_MAXIMUM
    local fs = 'size[8,9]background[0,0;8,9;terumet_asmeltgui_bg.png;true]listcolors[#3a101b;#905564;#521626;#114f51;#d2fdff]'..
    --player inventory
    'list[current_player;main;0,4.75;8,1;]'..
    'list[current_player;main;0,6;8,3;8]'..
    --input inventory
    'list[context;inp;0,1.5;2,2;]'..
    'label[0.5,3.5;Input Slots]'..
    --output inventory
    'list[context;out;6,1.5;2,2;]'..
    'label[6.5,3.5;Output Slots]'
    if smelter.heat_level == 0 or (not smelter.inv:is_empty('fuel')) then
    --fuel inventory (if needed/not empty)
        fs = fs..'list[context;fuel;6.5,0;1,1;]'..
        'label[6.5,1;Fuel Slot]'
    end
    --current status texts
    fs = fs..'label[0,0;Terumetal Alloy Smelter]'..
    'label[0,0.5;' .. smelter.status_text .. ']'..
    'image[2,1.5;2,2;terumet_asmeltgui_flux_bg.png^[lowpart:'..flux_pct..':terumet_asmeltgui_flux_fg.png]'..
    'label[2.5,3.5;Molten Flux]'..
    'image[4,1.5;2,2;terumet_asmeltgui_heat_bg.png^[lowpart:'..heat_pct..':terumet_asmeltgui_heat_fg.png]'..
    'label[4.5,3.5;Heat Level]'..
    --list rings
    "listring[current_player;main]"..
	"listring[context;inp]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function asmelt.generate_infotext(smelter)
    return string.format('Alloy Smelter (%.0f%% heat): %s', 100.0 * smelter.heat_level / opts.FULL_HEAT, smelter.status_text)
end

function asmelt.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('inp', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)

    local init_smelter = {
        flux_tank = 0,
        state = asmelt.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        status_text = 'New',
    }

    asmelt.write_state(pos, init_smelter)
end

function asmelt.get_drops(pos, include_self)
    local drops = {}
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "inp", drops)
    default.get_inventory_drops(pos, "out", drops)
    local flux_tank = minetest.get_meta(pos):get_int('flux_tank') or 0
    if flux_tank > 0 then
        drops[#drops+1] = terumet.id('lump_raw', math.min(99, flux_tank))
    end
    if include_self then drops[#drops+1] = asmelt.full_id end
    return drops
end

function asmelt.read_state(pos)
    local smelter = {}
    local meta = minetest.get_meta(pos)
    smelter.meta = meta
    smelter.inv = meta:get_inventory()
    smelter.flux_tank = meta:get_int('flux_tank') or 0
    smelter.state = meta:get_int('state') or asmelt.STATE.IDLE
    smelter.heat_level = meta:get_int('heat_level') or 0
    smelter.state_time = meta:get_float('state_time') or 0
    smelter.status_text = nil
    return smelter
end

function asmelt.write_state(pos, smelter)
    local meta = minetest.get_meta(pos)
    meta:set_string('formspec', asmelt.generate_formspec(smelter))
    meta:set_string('infotext', asmelt.generate_infotext(smelter))
    meta:set_int('flux_tank', smelter.flux_tank)
    meta:set_int('state', smelter.state)
    meta:set_float('state_time', smelter.state_time)
    meta:set_int('heat_level', smelter.heat_level)
end

function asmelt.expend_heat(smelter, value)
    smelter.heat_level = math.max(0, smelter.heat_level - value)
end

function asmelt.do_processing(smelter, dt)
    if smelter.state == asmelt.STATE.FLUX_MELT then
        smelter.state_time = smelter.state_time - dt
        asmelt.expend_heat(smelter, 2)
        if smelter.state_time <= 0 then
            smelter.flux_tank = smelter.flux_tank + 1
            smelter.state = asmelt.STATE.IDLE
        else
            smelter.status_text = 'Melting flux (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    elseif smelter.state == asmelt.STATE.ALLOYING then
        local result_stack = smelter.inv:get_stack('result', 1)
        local result_name = result_stack:get_definition().description
        smelter.state_time = smelter.state_time - dt
        asmelt.expend_heat(smelter, 1)
        if smelter.state_time <= 0 then
            if smelter.inv:room_for_item('out', result_stack) then
                smelter.inv:set_stack('result', 1, nil)
                smelter.inv:add_item('out', result_stack)
                smelter.state = asmelt.STATE.IDLE
            else
                smelter.status_text = result_name .. ' ready - no space!'
                smelter.state_time = -0.1
            end
        else
            smelter.status_text = 'Alloying ' .. result_name .. ' (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    end
end

function asmelt.check_new_processing(smelter)
    -- first, check for elements of an alloying recipe in input
    local matched_result = nil
    for result, recipe in pairs(terumet.alloy_recipes) do
        local sources_count = 0
        for i = 1,#recipe do
            if smelter.inv:contains_item('inp', recipe[i]) then
                sources_count = sources_count + 1
            end
        end
        if sources_count == #recipe then
            matched_result = result
            break
        end
    end
    if matched_result and minetest.registered_items[matched_result] then
        local recipe = terumet.alloy_recipes[matched_result]
        local result_name = minetest.registered_items[matched_result].description
        if smelter.flux_tank < recipe.flux then
            smelter.status_text = 'Alloying ' .. result_name .. ': ' .. recipe.flux - smelter.flux_tank .. ' more flux needed'
        else
            smelter.state = asmelt.STATE.ALLOYING
            for _, consumed_source in ipairs(recipe) do
                smelter.inv:remove_item('inp', consumed_source)
            end
            smelter.state_time = recipe.time
            smelter.inv:set_stack('result', 1, ItemStack(matched_result, recipe.result_count))
            smelter.flux_tank = smelter.flux_tank - recipe.flux
            smelter.status_text = 'Alloying ' .. result_name .. '...'
        end
    end
    -- if could not begin alloying anything, check for flux to melt
    if smelter.state == asmelt.STATE.IDLE and smelter.inv:contains_item('inp', opts.FLUX_ITEM) then
        if smelter.flux_tank >= opts.FLUX_MAXIMUM then
            smelter.status_text = 'Flux tank full!'
        else
            smelter.state = asmelt.STATE.FLUX_MELT
            smelter.state_time = opts.FLUX_MELTING_TIME
            smelter.inv:remove_item('inp', opts.FLUX_ITEM)
            smelter.status_text = 'Melting flux...'
        end
    end
end

function asmelt.tick(pos, dt)
    -- read status from metadata
    local smelter = asmelt.read_state(pos)

    if smelter.heat_level == 0 then
        if smelter.inv:contains_item('fuel', opts.FUEL_ITEM) then
            if smelter.inv:room_for_item('out', opts.FUEL_RETURN) then
                smelter.inv:remove_item('fuel', opts.FUEL_ITEM)
                smelter.inv:add_item('out', opts.FUEL_RETURN)
                smelter.heat_level = opts.FULL_HEAT
            else
                smelter.status_text = 'No space for return bucket'
            end
        else
            smelter.status_text = 'Need heat ('..minetest.registered_items[opts.FUEL_ITEM].description..')'
        end
    end
    -- not an else since it could have changed!
    if smelter.heat_level > 0 then
        asmelt.do_processing(smelter, dt)

        if smelter.heat_level > 0 then
            -- if still heated and idle now, check for new processing to start
            if smelter.state == asmelt.STATE.IDLE then
                asmelt.check_new_processing(smelter) 
            end
        else
            -- if heat reached zero this tick, expel the fuel finish item (cobblestone by default)
            -- no need to check if fuel slot is empty because in normal usage it's been hidden since last fueling
            smelter.inv:set_stack('fuel', 1, opts.FUEL_COMPLETE)
        end
    end
    -- if idle, make sure status text has been set to something (if no other error happened)
    -- if still processing, set up timer for next tick
    if smelter.state == asmelt.STATE.IDLE then
        if not smelter.status_text then smelter.status_text = 'Idle' end
    else
        asmelt.start_timer(pos)
    end
    -- write status back to metadata
    asmelt.write_state(pos, smelter)
end

function asmelt.allow_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0 -- number of items allowed to move
    end
    if listname == "fuel" then
        if stack:get_name() == opts.FUEL_ITEM then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == "inp" then
        return stack:get_count()
    else
        return 0
    end
end

function asmelt.allow_take(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

function asmelt.allow_move(pos, from_list, from_index, to_list, to_index, count, player)
    --return count
    local stack = minetest.get_meta(pos):get_inventory():get_stack(from_list, from_index)
    return asmelt.allow_put(pos, to_list, to_index, stack, player)
end

asmelt.nodedef = {
    -- node properties
    description = "Terumetal Alloy Smelter",
    tiles = {
        terumet.tex_file('block_raw'), terumet.tex_file('block_raw'),
        terumet.tex_file('asmelt_sides'), terumet.tex_file('asmelt_sides'),
        terumet.tex_file('asmelt_sides'), terumet.tex_file('asmelt_front')
    },
    paramtype2 = 'facedir',
    groups = {cracky=1},
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    legacy_facedir_simple = true,
    -- inventory slot control
    allow_metadata_inventory_put = asmelt.allow_put,
    allow_metadata_inventory_move = asmelt.allow_move,
    allow_metadata_inventory_take = asmelt.allow_take,
    -- callbacks
    on_construct = asmelt.init,
    on_metadata_inventory_move = asmelt.start_timer,
    on_metadata_inventory_put = asmelt.start_timer,
    on_metadata_inventory_take = asmelt.start_timer,
    on_timer = asmelt.tick,
    on_destruct = function(pos)
        for _,item in ipairs(asmelt.get_drops(pos, false)) do
            minetest.add_item(pos, item)
        end
    end,
    on_blast = function(pos)
        drops = asmelt.get_drops(pos, true)
        minetest.remove_node(pos)
        return drops
    end
}

minetest.register_node(asmelt.full_id, asmelt.nodedef)

minetest.register_craft{ output = asmelt.full_id, recipe = {
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')},
    {'bucket:bucket_empty', 'default:copperblock', 'bucket:bucket_empty'},
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')}
}}