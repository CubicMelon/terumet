--[[
    Adds food to the vacuum oven recipes:
    * Upgrades food items - vacuum two food items to create a condensed and packaged version that restores 3 times as much health/stamina.
        * Food items are items that are of the group "food_*" and have an on_use (presumably minetest.item_eat)
        * To ensure all food items are seen, any mods that add foods must be added as a dependent mod to Terumet - by default only "farming" is
]]--

local FMT = string.format

local function make_vacfood_image(img)
    return FMT('[combine:32x32:0,0=%s:8,8=%s', terumet.tex('item_vacfood'), img)
end

for id,def in pairs(minetest.registered_items) do
    local is_food = false
    for group,_ in pairs(def.groups) do
        if def.on_use and group:match('^food_') then
            is_food = true
            break
        end
    end
    if is_food then
        local mod, item = id:match('^(%S+):(%S+)')
        if mod and item then
            local vf_id = terumet.id(FMT('vacf_%s_%s', mod, item))
            local image
            if def.inventory_image and def.inventory_image ~= '' then
                image = make_vacfood_image(def.inventory_image)
            elseif def.tiles and def.tiles[1] and def.tiles[1] ~= '' then
                image = make_vacfood_image(def.tiles[1])
            else
                image = terumet.tex('item_vacfood')
            end

            local item_sound
            if def.sound then
                item_sound = table.copy(def.sound)
            else
                item_sound = {}
            end
            item_sound.eat = 'terumet_eat_vacfood'

            minetest.register_craftitem(vf_id, {
                description = 'Vacuum-packed ' .. def.description,
                inventory_image = image,
                sound=item_sound,
                _terumet_vacfood = true,
                on_use = def.on_use,
            })

            terumet.register_vacoven_recipe{
                input=id..' 2',
                results={vf_id},
                time=4.0
            }
        else
            minetest.log('warning', FMT('terumet: item "%s" was selected for vacfood but mod or item-id did not parse properly', id))
        end
    end
end

-- add a wrapper to core function of do_item_eat which triples hp_change value of items with _terumet_vacfood flag
-- there's no way to read what value individual food items are calling minetest.item_eat() with, so this is the next best way to multiply the value

local old_item_eat = core.do_item_eat

core.do_item_eat = function(hp_change, replace_with_item, itemstack, ...)
    local def = itemstack:get_definition()
    if def and def._terumet_vacfood then
        return old_item_eat(hp_change * 3, replace_with_item, itemstack, ...)
    else
        return old_item_eat(hp_change, replace_with_item, itemstack, ...)
    end
end
