local biomat_item = terumet.id('item_dust_bio')
local biomat_block = terumet.id('block_dust_bio')

local woodmulch_item = terumet.id('item_dust_wood')

local glue_item = terumet.id('item_glue')

minetest.register_craftitem( terumet.id('item_dust_ob'), {
    description = 'Obsidian Grit',
    inventory_image = terumet.tex('item_dust_ob')
})

-- ========================================================

minetest.register_craftitem( woodmulch_item, {
    description = 'Wood Mulch',
    inventory_image = terumet.tex('item_dust_wood')
})

minetest.register_craft({
    type = 'fuel',
    recipe = woodmulch_item,
    burntime = 10,
})

minetest.register_craft{ output = 'default:paper',
    type = 'shapeless',
    recipe = {'bucket:bucket_water', woodmulch_item, woodmulch_item},
    replacements={{'bucket:bucket_water','bucket:bucket_empty'}}
}

local pwood_ytex = terumet.tex('block_pwood')
local pwood_xztex = terumet.tex('block_pwood_sides')
local pwood_tiles = {pwood_ytex, pwood_ytex, pwood_xztex}

minetest.register_node(terumet.id('block_pwood'), {
    description = "Pressed Wood",
    tiles = pwood_tiles,
    is_ground_content = false,
    groups = {choppy = 2, oddly_breakable_by_hand = 2, wood = 1},
    sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft{ output = terumet.id('block_pwood', 16),
    recipe = terumet.recipe_box(woodmulch_item, 'group:glue'),
}

if minetest.global_exists('stairs') then
    stairs.register_stair_and_slab(
        'terumet_pwood',
        terumet.id('block_pwood'),
        {choppy = 2, oddly_breakable_by_hand = 2},
        pwood_tiles,
        'Pressed Wood Stair',
        'Pressed Wood Slab',
        default.node_sound_wood_defaults()
    )
end

-- =======================================================

minetest.register_craftitem( biomat_item, {
    description = 'Biomatter',
    inventory_image = terumet.tex('item_dust_bio')
})

minetest.register_craft{
    type = 'fuel',
    recipe = biomat_item,
    burntime = 30,
}

minetest.register_node( biomat_block, {
    description = 'Biomatter Block',
    tiles = {terumet.tex('block_dust_bio')},
    is_ground_content = false,
    groups={crumbly=3, oddly_breakable_by_hand=2, flammable=1},
    sounds = default.node_sound_leaves_defaults()
})

minetest.register_craft{
    type = 'fuel',
    recipe = biomat_block,
    burntime = 280,
}

minetest.register_craft{ output = biomat_block,
    recipe = terumet.recipe_3x3(biomat_item)
}

minetest.register_craft{ output = biomat_item..' 9',
    type = 'shapeless',
    recipe = {biomat_block}
}

-- =======================================================

minetest.register_craftitem( glue_item, {
    description = 'Plant Glue',
    groups = {glue=1},
    inventory_image = terumet.tex('item_glue')
})

minetest.register_craft{ output = glue_item,
    type = 'shapeless',
    recipe = {'bucket:bucket_water', biomat_item},
    replacements={{'bucket:bucket_water','bucket:bucket_empty'}}
}

minetest.register_craft{ output = glue_item .. ' 9',
    type = 'shapeless',
    recipe = {'bucket:bucket_water', biomat_block},
    replacements={{'bucket:bucket_water','bucket:bucket_empty'}}
}

minetest.register_craft{ output = glue_item .. ' 8',
    type = 'shapeless',
    recipe = {'bucket:bucket_water', 'farming:flour'},
    replacements={{'bucket:bucket_water','bucket:bucket_empty'}}
}