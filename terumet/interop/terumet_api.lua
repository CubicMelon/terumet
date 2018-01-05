-- API for other mods to interface with this mod

-- register a new alloy smelter recipe
--[[ example data: 
{
    result = 'terumet:ingot_tcop',
    input = {'default:copper_lump'}, -- input must be a table of item ids, up to 4 items supported in machine
    time = 3.0  -- time is in seconds
    flux = 1 -- flux items used out of machine tank
}
]]--
function terumet.register_alloy_recipe(data)
    local list = terumet.options.smelter.recipes
    -- TODO error checking
    list[#list+1] = data
end

-- register a new crystallized material
--[[ example data:
{
    suffix = 'copper', -- id of crystallized item will be terumetal:item_cryst_suffix
    color = '#ebba5d', -- minetest colorspec of crystal
    name = 'Crystallized Copper', -- name of crystallized item
    source = 'default:copper_lump', -- item that yields crystal in Crystal Vulcanizer
    cooking_result = 'default:copper_ingot' -- result when crystallized item itself is cooked
}
-- IMPORTANT NOTE: a single source item can only be defined as a single crystal
-- for example, trying to add a new crystal for 'default:copper_lump' will override the default one
]]--
function terumet.register_crystal(data)
    local crys_id = terumet.id('item_cryst_' .. data.suffix)
    minetest.register_craftitem( crys_id, {
        description = data.name,
        inventory_image = terumet.tex('item_cryst_bg')..'^('..terumet.tex('item_cryst')..'^[multiply:'..data.color..')',
    })

    minetest.register_craft{ type = 'cooking', 
        output = data.cooking_result,
        recipe = crys_id,
        cooktime = 5
    }

    terumet.options.vulcan.recipes[data.source] = crys_id
end