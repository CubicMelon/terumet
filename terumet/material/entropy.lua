local ent_crystal_id = terumet.id('item_entropy')
local ent_matrix_id = terumet.id('block_entropy')

minetest.register_craftitem( ent_crystal_id, {
    description = 'Entropic Crystal',
    inventory_image = terumet.tex(ent_crystal_id)
})

minetest.register_node( ent_matrix_id, {
    description = 'Entropic Matrix\nPlace directly above EEE Heater',
    tiles = {terumet.tex(ent_matrix_id)},
    is_ground_content = false,
    groups={cracky=1, level=2},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = ent_crystal_id,
    recipe = {
        { terumet.id('item_cryst_ob'), terumet.id('item_cryst_mese'), terumet.id('item_cryst_ob') },
        { terumet.id('item_cryst_mese'), terumet.id('item_cryst_dia'), terumet.id('item_cryst_mese') },
        { terumet.id('item_cryst_ob'), terumet.id('item_cryst_mese'), terumet.id('item_cryst_ob') },
}}

minetest.register_craft{ output = ent_matrix_id,
    recipe = terumet.recipe_box(ent_crystal_id, 'default:diamondblock')
}