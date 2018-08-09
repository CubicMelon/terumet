local htg_id = terumet.id('item_htglass')

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

-- =============================================

local emit_id = terumet.id('item_heatunit')

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

-- =============================================

local press_id = terumet.id('item_press')
minetest.register_craftitem( press_id, {
    description = 'Terutin Expansion Press',
    inventory_image = terumet.tex(press_id)
})

minetest.register_craft{ output = press_id,
    recipe = {
        {'default:stone', 'default:stone', 'default:stone'},
        {terumet.id('ingot_tste'), terumet.id('ingot_tste'), terumet.id('ingot_tste')},
        {terumet.id('ingot_ttin'), terumet.id('ingot_ttin'), terumet.id('ingot_ttin')}
    }
}