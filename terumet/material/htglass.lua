local htg_id = terumet.id('item_htglass')
local emit_id = terumet.id('item_heatunit')

minetest.register_craftitem( htg_id, {
    description = 'Heat-transference Glass',
    inventory_image = terumet.tex(htg_id)
})

minetest.register_craft{ output = htg_id .. ' 3',
    recipe = {
        {'', 'default:obsidian_glass', ''},
        {terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin'), terumet.id('item_cryst_tin')},
        {'', 'default:obsidian_glass', ''}
    }
}

minetest.register_craftitem( emit_id, {
    description = 'High Energy Alpha-wave Transmission Unit',
    inventory_image = terumet.tex(emit_id)
})

minetest.register_craft{ output = emit_id,
    recipe = {
        {terumet.id('ingot_tgol'), 'default:obsidian_glass', terumet.id('ingot_tgol')},
        {terumet.id('item_thermese'), 'default:mese_crystal', terumet.id('item_thermese')},
        {terumet.id('item_ceramic'), terumet.id('item_coil_tgol'), terumet.id('item_ceramic')}
    }
}