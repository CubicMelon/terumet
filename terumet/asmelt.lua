terumet.FLUX_MELTING_TIME = 3.0
terumet.FLUX_SOURCE = terumet.id('lump_raw')
terumet.FLUX_MAXIMUM = 10

local asmelt = {}
asmelt.full_id = terumet.id('mach_asmelt')

function asmelt.start_timer(pos)
    minetest.get_node_timer(pos):start(1.0)
end

function asmelt.stack_is_valid_fuel(stack)
    return minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0
end

function asmelt.generate_formspec(status, melted)
    local fs = 'size[8,9]'..
    --player inventory
    'list[current_player;main;0,4.75;8,1;]'..
    'list[current_player;main;0,6;8,3;8]'..
    --input inventory
    'list[current_name;in;0,0.5;2,2]'..
    --output inventory
    'list[current_name;out;6,0.5;2,2]'..
    --fuel inventory
    'list[current_name;fuel;1,3;1,1]'..
    --current status text
    'label[2.4,1;' .. (status or 'Idle') .. ']'..
    --molten readout
    'label[2.4,2.5;Molten flux: ' .. (melted or '???') .. '/' .. terumet.FLUX_MAXIMUM .. ' lumps' .. ']'
    return fs
end

function asmelt.generate_infotext(status)
    return 'Alloy Smelter: ' .. status
end

function asmelt.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('in', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)
    meta:set_float('melted', 0)
    meta:set_string('action', 'idle')
    meta:set_string('formspec', asmelt.generate_formspec('New', 0))
    meta:set_string('infotext', asmelt.generate_infotext('New'))
end

function asmelt.get_drops(pos, include_self)
    local drops = {}
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "in", drops)
    default.get_inventory_drops(pos, "out", drops)
    local melted = minetest.get_meta(pos):get_float('melted') or 0
    if melted > 0 then
        drops[#drops+1] = ItemStack(terumet.id('lump_raw'), math.min(99, melted))
    end
    if include_self then drops[#drops+1] = asmelt.full_id end
    return drops
end

function asmelt.tick(pos, dt)
    -- read status from metadata
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local melted = meta:get_float('melted') or 0
    local action = meta:get_string('action') or 'idle'
    local action_time = meta:get_float('action_time') or 0
    local status_text = 'STATUS TEXT NOT SET'
    
    -- do processing
    -- inprocess of melting flux
    if action == 'melting' then
        action_time = action_time - dt
        status_text = 'Melting flux (' .. string.format('%.1f', action_time) .. 's)'
        if action_time <= 0 then
            action = 'idle'
            melted = melted + 1
        end
    elseif action == 'alloying' then
        local result_stack = inv:get_stack('result', 1)
        action_time = action_time - dt
        status_text = 'Alloying ' .. result_stack:get_name() .. ' (' .. string.format('%.1f', action_time) .. 's)'
        if action_time <= 0 then
            if inv:room_for_item('out', result_stack) then
                inv:set_stack('result', 1, nil)
                inv:add_item('out', result_stack)
            else
                status_text = 'No space in output!'
                action_time = -0.1
            end
        end 
    end

    -- check for new processing actions if now idle
    if action == 'idle' then
        -- check for flux to melt
        if inv:contains_item('in', terumet.FLUX_SOURCE) then
            if melted < terumet.FLUX_MAXIMUM then
                action = 'melting'
                inv:remove_item('in', terumet.FLUX_SOURCE)
                action_time = terumet.FLUX_MELTING_TIME
                status_text = 'Melting flux...'
            else
                status_text = 'Molten flux tank full!'
            end
        else
            -- check for any matched recipes in input
            local matched_result = nil
            for result, recipe in pairs(terumet.alloy_recipes) do
                --minetest.chat_send_all('checking recipe' .. dump(result) .. ' to list: ' .. dump(source_list))
                local sources_count = 0
                for i = 1,#recipe do
                    --minetest.chat_send_all('looking for srcitem: ' .. source_list[i])
                    if inv:contains_item('in', recipe[i]) then
                        sources_count = sources_count + 1
                    end
                end
                if sources_count == #recipe then
                    matched_result = result
                    break
                end
            end
            if matched_result then
                local recipe = terumet.alloy_recipes[matched_result]
                local result_name = minetest.registered_items[matched_result].description
                if melted >= recipe.flux then
                    action = 'alloying'
                    for _, consumed_source in ipairs() do
                        inv:remove_item('in', consumed_source)
                    end
                    action_time = recipe.time
                    inv:set_stack('result', 1, ItemStack(matched_result, recipe.result_count))
                    melted = melted - recipe.flux
                    status_text = 'Alloying ' .. result_name .. '...'
                else
                    status_text = 'Ready to alloy ' .. result_name .. ', needs ' .. recipe.flux .. ' flux'
                end
            else
                status_text = 'Idle'
            end
        end
    end

    -- write status back to metadata
    meta:set_string('formspec', asmelt.generate_formspec(status_text, melted))
    meta:set_string('infotext', asmelt.generate_infotext(status_text))
    meta:set_float('melted', melted)
    meta:set_string('action', action)
    meta:set_float('action_time', action_time)
    -- if not currently idle, set next timer tick
    if action ~= 'idle' then asmelt.start_timer(pos) end
end

function asmelt.allow_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0 -- number of items allowed to move
    end
    if listname == "fuel" then
        if asmelt.stack_is_valid_fuel(stack) then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == "in" then
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
    local stack = minetest.get_meta(pos):get_inventory():get_stack(from_list, from_index)
    return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
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