local thcrys_id = terumet.id('item_thermese')
local thblock_id = terumet.id('block_thermese')

minetest.register_craftitem( thcrys_id, {
    description = 'Thermese Crystal',
    inventory_image = terumet.tex(thcrys_id)
})

minetest.register_node( thblock_id, {
    description = 'Thermese Block',
    tiles = {terumet.tex('block_thermese')},
    is_ground_content = false,
    groups={cracky=3, level=2},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = thblock_id,
    recipe = terumet.recipe_3x3(thcrys_id)
}

minetest.register_craft{ type = 'shapeless', output = terumet.id('item_thermese', 9),
    recipe = {thblock_id}
}