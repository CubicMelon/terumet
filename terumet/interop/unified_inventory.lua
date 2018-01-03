
-- dummy item to display amount of flux needed to alloy
minetest.register_craftitem( terumet.id('uninv_flux_req'), {
    description = "flux used",
    inventory_image = terumet.tex('uninv_flux_req'),
    groups={not_in_creative_inventory=1}
})

-- dummy item to display amount of time needed to alloy
minetest.register_craftitem( terumet.id('uninv_time_req'), {
    description = "time (seconds)",
    inventory_image = terumet.tex('uninv_time_req'),
    groups={not_in_creative_inventory=1}
})

-- register new crafting type with UnInv
unified_inventory.register_craft_type( 'terumet_alloy', {
    description = 'Terumetal Alloy Smelting',
    icon = 'terumet_asmelt_front_lit.png',
    width=3,
    height=2,
})

-- add each defined alloy recipe to the new crafting type UnInv
for result, recipe in pairs(terumet.alloy_recipes) do
    local listed = {}
    for i=1,#recipe do listed[#listed+1] = recipe[i] end
    listed[#listed+1] = terumet.id('uninv_flux_req', recipe.flux)
    listed[#listed+1] = terumet.id('uninv_time_req', math.ceil(recipe.time))
    unified_inventory.register_craft{
        type = 'terumet_alloy',
        output = result,
        items = listed
    }
end