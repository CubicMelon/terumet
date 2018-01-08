local solar_id = terumet.id('item_solar')

minetest.register_craftitem( solar_id, {
    description = 'Solar Heating Glass',
    inventory_image = terumet.tex(solar_id)
})

minetest.register_craft{ output = solar_id,
    recipe = {
        {'', 'default:obsidian_glass', ''},
        {terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin')},
        {'', 'default:obsidian_glass', ''}
    }
}