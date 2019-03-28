local function add_terumet_recipes()
    -- add each defined alloy recipe to UnInv
    for _, recipe in pairs(terumet.options.smelter.recipes) do
        local listed = {}
        for i=1,#recipe.input do listed[#listed+1] = recipe.input[i] end
        if recipe.flux > 0 then
            listed[#listed+1] = terumet.id('uninv_flux_req', recipe.flux)
        end
        listed[#listed+1] = terumet.id('uninv_time_req', math.ceil(recipe.time))
        unified_inventory.register_craft{
            type = 'terumet_alloy',
            output = recipe.result,
            items = listed
        }
    end

    -- add each defined flux source to UnInv
    for source, details in pairs(terumet.options.smelter.FLUX_ITEMS) do
        unified_inventory.register_craft{
            type = 'terumet_alloy',
            output = terumet.id('uninv_flux_req'),
            items = {source, terumet.id('uninv_time_req', math.ceil(details.time))}
        }
    end

    -- add each crusher recipe to UnInv
    for source, result in pairs(terumet.options.crusher.recipes) do
        unified_inventory.register_craft{
            type = 'terumet_crush',
            output = result,
            items = {source}
        }
    end

    -- add each repair material to UnInv
    for id, repmatval in pairs(terumet.options.repm.repair_mats) do
        unified_inventory.register_craft{
            type = 'terumet_repmat',
            output = terumet.id('uninv_repmat', repmatval),
            items = {id}
        }
    end

    -- add each repairable tool to UnInv
    for id, rmreq in pairs(terumet.options.repm.repairable) do
        unified_inventory.register_craft{
            type = 'terumet_repair',
            output = id,
            items = {id, terumet.id('uninv_repmat', rmreq)}
        }
    end

    -- add each crystal vulcanizer recipe to UnInv
    for source, result in pairs(terumet.options.vulcan.recipes) do
        --minetest.log(string.format('%s => %s x %s', source or 'NIL', result[1] or 'NIL', result[2] or 'NIL'))
        unified_inventory.register_craft{
            type = 'terumet_vulcan',
            output = result[1] .. ' ' .. result[2],
            items = {source}
        }
    end

    -- add each valid ore for ore saw to UnInv
    for node, _ in pairs(terumet.options.ore_saw.VALID_ORES) do
        unified_inventory.register_craft{
            type = 'terumet_ore_saw',
            output = node,
            items = {node}
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

-- dummy item to display amount of repair material
minetest.register_craftitem( terumet.id('uninv_repmat'), {
    description = "repair material value",
    inventory_image = terumet.tex('uninv_repmat'),
    groups={not_in_creative_inventory=1}
})

-- register terumetal alloying with UnInv
unified_inventory.register_craft_type( 'terumet_alloy', {
    description = 'Terumetal Alloy Smelting',
    icon = 'terumet_asmelt_front_lit.png',
    width=3,
    height=2,
})

-- register crushing with UnInv
unified_inventory.register_craft_type( 'terumet_crush', {
    description = 'Expansion Crusher',
    icon = 'terumet_crush_front_lit.png',
    width=1,
    height=1,
})

-- register repair materials with UnInv
unified_inventory.register_craft_type( 'terumet_repmat', {
    description = 'Equipment Reformer\n(material)',
    icon = 'terumet_repm_front.png',
    width=1,
    height=1,
})

-- register tool repair with UnInv
unified_inventory.register_craft_type( 'terumet_repair', {
    description = 'Equipment Reformer\n(for 100% wear)',
    icon = 'terumet_repm_front.png',
    width=2,
    height=1,
})

-- register crystal vulcanizing with UnInv
unified_inventory.register_craft_type( 'terumet_vulcan', {
    description = 'Crystal Vulcanizer',
    icon = 'terumet_vulcan_front.png',
    width=1,
    height=1,
})

-- register ore saw gathering
unified_inventory.register_craft_type( 'terumet_ore_saw', {
    description = 'Ore-cutting Saw',
    icon = 'terumet_tool_ore_saw.png^[transformFX',
    width=1,
    height=1,
})

-- call after all mods are loaded to catch new submod recipes/changes
minetest.after(0.01, function() add_terumet_recipes() end)