local htg_id = terumet.id('item_htglass')

minetest.register_craftitem( htg_id, {
    description = 'Heat-transference Glass',
    inventory_image = terumet.tex(htg_id)
})

minetest.register_craft{ output = htg_id,
    recipe = {
        {'', 'default:obsidian_glass', ''},
        {terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin')},
        {'', 'default:obsidian_glass', ''}
    }
}