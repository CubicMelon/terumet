local id = terumet.id
local tex = terumet.tex

local function items(item, count)
    return item .. ' ' .. count
end

local ore_stone = id('ore_raw')
local ore_stone_dense = id('ore_dense_raw')

local ore_desert_stone = id('ore_raw_desert')
local ore_desert_stone_dense = id('ore_raw_desert_dense')

local lump = id('lump_raw')
local ingot = id('ingot_raw')
local block = id('block_raw')

-- standard stone
minetest.register_node( ore_stone, {
    description = 'Terumetal Ore',
    tiles = {terumet.tex_comp('default_stone.png', 'ore_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = lump,
    sounds = default.node_sound_stone_defaults()
})

-- standard stone dense
minetest.register_node( ore_stone_dense, {
    description = 'Terumetal Dense Ore',
    tiles = {terumet.tex_comp('default_stone.png', 'ore_dense_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = items(lump, 5),
    sounds = default.node_sound_stone_defaults()
})

-- desert stone
minetest.register_node( ore_desert_stone, {
    description = 'Desert Terumetal Ore',
    tiles = {terumet.tex_comp('default_desert_stone.png', 'ore_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = items(lump, 2),
    sounds = default.node_sound_stone_defaults()
})

-- desert stone dense
minetest.register_node( ore_desert_stone_dense, {
    description = 'Desert Terumetal Dense Ore',
    tiles = {terumet.tex_comp('default_desert_stone.png', 'ore_dense_raw')},
    is_ground_content = true,
    groups = {cracky=2},
    drop = items(lump, 8),
    sounds = default.node_sound_stone_defaults()
})


minetest.register_craftitem( lump, {
    description = 'Raw Terumetal Lump',
    inventory_image = tex(lump),
    groups = {lump=1}
})

minetest.register_craftitem( ingot, {
    description = 'Pure Terumetal Ingot',
    inventory_image = tex(ingot),
    groups = {ingot=1}
})

minetest.register_node( block, {
    description = 'Pure Terumetal Block',
    tiles = {tex(block)},
    is_ground_content = false,
    groups = {cracky=1},
    sounds = default.node_sound_metal_defaults()
})

minetest.register_craft{ type = 'cooking',
    output = ingot,
    recipe = lump,
    cooktime = 6
}

minetest.register_craft{ output = block,
    recipe = terumet.recipe_3x3(ingot)
}

minetest.register_craft{ type = 'shapeless', output = ingot..' 9',
    recipe = {block}
}

minetest.register_ore{
    ore_type = 'scatter',
    ore = ore_stone,
    wherein = 'default:stone',
    clust_scarcity = 12 * 12 * 12,
    clust_num_ores = 6,
    clust_size = 4,
    y_min = -30000,
    y_max = 8
}

minetest.register_ore{
    ore_type = 'scatter',
    ore = ore_stone_dense,
    wherein = 'default:stone',
    clust_scarcity = 16 * 16 * 16,
    clust_num_ores = 4,
    clust_size = 3,
    y_min = -30000,
    y_max = -64
}

minetest.register_ore{
    ore_type = 'scatter',
    ore = ore_desert_stone,
    wherein = 'default:desert_stone',
    clust_scarcity = 12 * 10 * 8,
    clust_num_ores = 5,
    clust_size = 5,
    y_min = -30000,
    y_max = 64
}

minetest.register_ore{
    ore_type = 'scatter',
    ore = ore_desert_stone_dense,
    wherein = 'default:desert_stone',
    clust_scarcity = 16 * 14 * 10,
    clust_num_ores = 3,
    clust_size = 4,
    y_min = -30000,
    y_max = 0
}