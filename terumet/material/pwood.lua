local pwood_ytex = terumet.tex('block_pwood')
local pwood_xztex = terumet.tex('block_pwood_sides')
local pwood_tiles = {pwood_ytex, pwood_ytex, pwood_xztex}

local pwood_id = terumet.id('block_pwood')

minetest.register_node(pwood_id, {
    description = "Pressed Wood",
    tiles = pwood_tiles,
    is_ground_content = false,
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft{ output = pwood_id..' 16',
    recipe = terumet.recipe_box(terumet.id('item_dust_wood'), 'group:glue'),
}

if minetest.global_exists('stairs') then
    stairs.register_stair_and_slab(
        'terumet_pwood',
        pwood_id,
        {choppy = 2, oddly_breakable_by_hand = 2},
        pwood_tiles,
        'Pressed Wood Stair',
        'Pressed Wood Slab',
        default.node_sound_wood_defaults()
    )
end

if minetest.global_exists('walls') then
    walls.register(terumet.id('walls_pwood'), 'Pressed Wood Wall', pwood_tiles,
		pwood_id, default.node_sound_stone_defaults())
end