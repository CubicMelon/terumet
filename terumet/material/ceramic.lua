local cplate_id = terumet.id('item_ceramic')
local cblock_id = terumet.id('block_ceramic')

minetest.register_craftitem( cplate_id, {
    description = 'Teruceramic Plate',
    inventory_image = terumet.tex(cplate_id)
})

minetest.register_node( cblock_id, {
    description = 'Teruceramic Block',
    tiles = {terumet.tex(cblock_id)},
    is_ground_content = false,
    groups={cracky=1, level=1},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = cblock_id,
    recipe = terumet.recipe_3x3(cplate_id)
}

minetest.register_craft{ type = 'shapeless', output = terumet.id('item_ceramic', 9),
    recipe = {cblock_id}
}