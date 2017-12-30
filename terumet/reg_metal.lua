function terumet.reg_metal(name, id)
    local ore_id = 'ore_' .. id
    local lump_id = 'lump_' .. id
    local ingot_id = 'ingot_' .. id
    local block_id = 'block_' .. id

    -- standard stone
    minetest.register_node( terumet.id(ore_id), {
        description = name .. ' Ore',
        tiles = {terumet.tex_composite('default_stone.png', ore_id)},
        is_ground_content = true,
        groups = {cracky=2},
        drop = terumet.id(lump_id),
        sounds = default.node_sound_stone_defaults()
    })

    -- desert stone
    minetest.register_node( terumet.id(ore_id..'_desert'), {
        description = 'Desert ' .. name .. ' Ore',
        tiles = {terumet.tex_composite('default_desert_stone.png', ore_id)},
        is_ground_content = true,
        groups = {cracky=2},
        drop = terumet.id(lump_id, 2),
        sounds = default.node_sound_stone_defaults()
    })

    minetest.register_craftitem( terumet.id(lump_id), {
        description = name .. ' Lump',
        inventory_image = terumet.tex_file(lump_id),
        groups = {lump=1}
    })

    local ingot_full_id = terumet.id(ingot_id)
    minetest.register_craftitem( ingot_full_id, {
        description = name .. ' Ingot',
        inventory_image = terumet.tex_file(ingot_id),
        groups = {ingot=1}
    })

    local block_full_id = terumet.id(block_id)
    minetest.register_node( block_full_id, {
        description = name .. ' Block',
        tiles = {terumet.tex_file(block_id)},
        is_ground_content = false,
        groups = {cracky=1},
        sounds = default.node_sound_metal_defaults()
    })

    minetest.register_craft{ type = 'cooking', 
        output = ingot_full_id,
        recipe = terumet.id(lump_id),
        cooktime = 10
    }

    minetest.register_craft{ output = block_full_id,
        recipe = {
            {ingot_full_id, ingot_full_id, ingot_full_id},
            {ingot_full_id, ingot_full_id, ingot_full_id},
            {ingot_full_id, ingot_full_id, ingot_full_id}}
    }

    minetest.register_craft{ type = 'shapeless', output = terumet.id(ingot_id, 9),
        recipe = {block_full_id}
    }
end