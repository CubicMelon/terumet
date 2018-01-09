function add_terumet_recipes()
    -- add each defined alloy recipe to UnInv
    for _, recipe in pairs(terumet.options.smelter.recipes) do
        local listed = {}
        for i=1,#recipe.input do listed[#listed+1] = recipe.input[i] end
        listed[#listed+1] = terumet.id('uninv_flux_req', recipe.flux)
        listed[#listed+1] = terumet.id('uninv_time_req', math.ceil(recipe.time))
        unified_inventory.register_craft{
            type = 'terumet_alloy',
            output = recipe.result,
            items = listed
        }
    end

    -- add each defined flux source to UnInv
    for source, details in pairs(terumet.options.smelter.flux_items) do
        unified_inventory.register_craft{
            type = 'terumet_alloy',
            output = terumet.id('uninv_flux_req'),
            items = {source, terumet.id('uninv_time_req', math.ceil(details.time))}
        }
    end

    for source, crystal in pairs(terumet.options.vulcan.recipes) do
        unified_inventory.register_craft{
            type = 'terumet_vulcan',
            output = crystal .. ' 2',  -- change here if yield updated
            items = {source}
        }
    end
end

-- dummy item to display amount of flux needed to alloy
minetest.register_craftitem( terumet.id('uninv_flux_req'), {
    description = "terumetal flux (in smelter tank)",
    inventory_image = terumet.tex('uninv_flux_req'),
    groups={not_in_creative_inventory=1}
})

-- dummy item to display amount of time needed to alloy
minetest.register_craftitem( terumet.id('uninv_time_req'), {
    description = "time (seconds)",
    inventory_image = terumet.tex('uninv_time_req'),
    groups={not_in_creative_inventory=1}
})

-- register alloying with UnInv
unified_inventory.register_craft_type( 'terumet_alloy', {
    description = 'Terumetal Alloy Smelting',
    icon = 'terumet_asmelt_front_lit.png',
    width=3,
    height=2,
})

-- register crystal vulcanizing with UnInv
unified_inventory.register_craft_type( 'terumet_vulcan', {
    description = 'Crystal Vulcanizer',
    icon = 'terumet_vulcan_sides.png',
    width=1,
    height=1,
})

-- call after all mods are loaded to catch new submod recipes/changes
minetest.after(0.01, function() add_terumet_recipes() end)