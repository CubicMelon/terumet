function terumet.reg_tools(mat_name, mat_id, craft_head_item, dig_times, base_use_count, max_level)
    local pick_id = 'tool_pick_'..mat_id
    local shovel_id = 'tool_shovel_'..mat_id
    local axe_id = 'tool_axe_'..mat_id
    local sword_id = 'tool_sword_'..mat_id
    local stick = 'default:stick'

    minetest.register_tool( terumet.id(pick_id), {
        description = mat_name .. ' Pickaxe',
        inventory_image = terumet.tex_file(pick_id),
        tool_capabilities = {
            full_punch_interval = 1.0 - (max_level * 0.1),
            max_drop_level = max_level,
            groupcaps = {
                cracky = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=1+max_level}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = terumet.id(pick_id),
        recipe = {
            {craft_head_item, craft_head_item, craft_head_item},
            {'', stick, ''},
            {'', stick, ''}
    }}
    
    minetest.register_tool( terumet.id(shovel_id), {
        description = mat_name .. ' Shovel',
        inventory_image = terumet.tex_file(shovel_id),
        tool_capabilities = {
            full_punch_interval = 1.0 - (max_level * 0.1),
            max_drop_level = max_level,
            groupcaps = {
                crumbly = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=1+math.floor(max_level / 2)}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = terumet.id(shovel_id),
        recipe = {
            {craft_head_item},
            {stick},
            {stick}
    }}

    minetest.register_tool( terumet.id(axe_id), {
        description = mat_name .. ' Axe',
        inventory_image = terumet.tex_file(axe_id),
        tool_capabilities = {
            full_punch_interval = math.max(0.55, 1.0 - (max_level * 0.15)),
            max_drop_level = max_level,
            groupcaps = {
                choppy = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=2+max_level}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = terumet.id(axe_id),
        recipe = {
            {craft_head_item, craft_head_item},
            {craft_head_item, stick},
            {'', stick}
    }}
    minetest.register_craft{ output = terumet.id(axe_id),
    recipe = {
        {craft_head_item, craft_head_item},
        {stick, craft_head_item},
        {stick, ''}
    }}

    minetest.register_tool( terumet.id(sword_id), {
        description = mat_name .. ' Sword',
        inventory_image = terumet.tex_file(sword_id),
        tool_capabilities = {
            full_punch_interval = math.max(0.4, 1.2 - (max_level * 0.2)),
            max_drop_level = max_level,
            groupcaps = {
                snappy = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=1 + (2 * max_level)}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = terumet.id(sword_id),
        recipe = {
            {craft_head_item},
            {craft_head_item},
            {stick}
    }}
end