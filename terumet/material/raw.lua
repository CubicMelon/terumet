local id = terumet.id
local tex = terumet.tex

-- standard stone
minetest.register_node( id('ore_raw'), {
    description = 'Terumetal Ore',
    tiles = {terumet.tex_comp('default_stone.png', 'ore_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = id('lump_raw'),
    sounds = default.node_sound_stone_defaults()
})

-- desert stone
minetest.register_node( id('ore_raw_desert'), {
    description = 'Desert Terumetal Ore',
    tiles = {terumet.tex_comp('default_desert_stone.png', 'ore_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = id('lump_raw',2),
    sounds = default.node_sound_stone_defaults()
})

minetest.register_craftitem( id('lump_raw'), {
    description = 'Raw Terumetal Lump',
    inventory_image = tex('lump_raw'),
    groups = {lump=1}
})

minetest.register_craftitem( id('ingot_raw'), {
    description = 'Pure Terumetal Ingot',
    inventory_image = tex('ingot_raw'),
    groups = {ingot=1}
})

minetest.register_node( id('block_raw'), {
    description = 'Pure Terumetal Block',
    tiles = {tex('block_raw')},
    is_ground_content = false,
    groups = {cracky=1},
    sounds = default.node_sound_metal_defaults()
})

minetest.register_craft{ type = 'cooking', 
    output = id('ingot_raw'),
    recipe = id('lump_raw'),
    cooktime = 10
}

minetest.register_craft{ output = id('block_raw'),
    recipe = terumet.recipe_3x3(id('ingot_raw'))
}

minetest.register_craft{ type = 'shapeless', output = id('ingot_raw', 9),
    recipe = {id('block_raw')}
}

minetest.register_ore{
    ore_type = 'scatter',
    ore = id('ore_raw'),
    wherein = 'default:stone',
    clust_scarcity = 12 * 12 * 12,
    clust_num_ores = 6,
    clust_size = 4,
    y_min = -30000,
    y_max = 8
}
minetest.register_ore{
    ore_type = 'scatter',
    ore = id('ore_raw_desert'),
    wherein = 'default:desert_stone',
    clust_scarcity = 12 * 10 * 8,
    clust_num_ores = 6,
    clust_size = 6,
    y_min = -30000,
    y_max = 64
}
