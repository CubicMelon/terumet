local cplate_full_id = terumet.id('item_ceramic')
local cblock_full_id = terumet.id('block_ceramic')

terumet.reg_item('Teruceramic Plate', 'item_ceramic')

minetest.register_node( cblock_full_id, {
    description = 'Teruceramic Block',
    tiles = {terumet.tex_file('block_ceramic')},
    is_ground_content = false,
    groups={cracky=1, level=1},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = cblock_full_id,
recipe = {
    {cplate_full_id, cplate_full_id, cplate_full_id},
    {cplate_full_id, cplate_full_id, cplate_full_id},
    {cplate_full_id, cplate_full_id, cplate_full_id}
}}

minetest.register_craft{ type = 'shapeless', output = terumet.id('item_ceramic', 9),
    recipe = {cblock_full_id}
}

terumet.alloy_recipes[cplate_full_id] = terumet.options.alloys.CERAMIC_PLATE