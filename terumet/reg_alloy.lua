function terumet.reg_alloy(name, id, block_level, source_list)
    if (not source_list) or (type(source_list) ~= 'table') then error('invalid source list for alloy') end
    source_list.flux = source_list.flux or 1
    source_list.result_count = source_list.result_count or 2
    source_list.time = source_list.time or 1.0

    local ingot_id = 'ingot_alloy_' .. id
    local block_id = 'block_alloy_' .. id
    local ingot_full_id = terumet.id(ingot_id)

    minetest.register_craftitem( ingot_full_id, {
        description = name .. ' Ingot',
        inventory_image = terumet.tex_file(ingot_id),
        groups = {ingot=1}
    })

    local block_full_id = terumet.id(block_id)
    minetest.register_node( terumet.id(block_id), {
        description = name .. ' Block',
        tiles = {terumet.tex_file(block_id)},
        is_ground_content = false,
        groups = {cracky=1, level=block_level},
        sounds = default.node_sound_metal_defaults()
    })

    minetest.register_craft{ output = block_full_id,
    recipe = {
        {ingot_full_id, ingot_full_id, ingot_full_id},
        {ingot_full_id, ingot_full_id, ingot_full_id},
        {ingot_full_id, ingot_full_id, ingot_full_id}}
    }

    minetest.register_craft{ type = 'shapeless', output = terumet.id(ingot_id, 9),
        recipe = {block_full_id}
    }

    terumet.alloy_recipes[ingot_full_id] = source_list
end