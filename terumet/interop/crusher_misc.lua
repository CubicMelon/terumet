-- add crushing recipes for various mods if they are active

local function add_crush(item, result)
    terumet.options.crusher.recipes[item] = result
end


if minetest.global_exists('bushes') then
    add_crush('bushes:BushLeaves1', 'terumet:item_dust_bio')
    add_crush('bushes:BushLeaves2', 'terumet:item_dust_bio')
end

if minetest.global_exists('dryplants') then
    add_crush('dryplants:grass', 'terumet:item_dust_bio')
end

if minetest.global_exists('vines') then
    add_crush('vines:vines', 'terumet:item_dust_bio')
end

if minetest.global_exists('farming') then
    -- small crops turn into 2 biomatter
    local small_crops = {
        'wheat', 'peas', 'barley', 'beans', 'pepper', 'beetroot', 'chili_pepper', 'blueberries',
        'cucumber', 'grapes', 'garlic', 'onion', 'pea_pod', 'pineapple_ring', 'pineapple_top', 'potato',
        'raspberries', 'tomato', 'corn', 'rhubarb'
    }

    for _,crop in ipairs(small_crops) do
        local crop_id = 'farming:'..crop
        if minetest.registered_items[crop_id] then
            add_crush(crop_id, 'terumet:item_dust_bio 2')
        end
    end

    -- big crops turn into 5 biomatter
    local big_crops = {
        'pumpkin', 'pineapple', 'melon_8'
    }

    for _,crop in ipairs(big_crops) do
        local crop_id = 'farming'..crop
        if minetest.registered_items[crop_id] then
            add_crush(crop_id, 'terumet:item_dust_bio 5')
        end
    end
end