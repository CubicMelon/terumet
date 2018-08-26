local id = terumet.id
local tex = terumet.tex

function terumet.reg_tools(mat_name, mat_id, craft_item_id, dig_times, base_use_count, max_level, sword_damage, ingot_repair_value)
    local stick = 'default:stick'
    local pick_id = id('tool_pick_'..mat_id)
    local shovel_id = id('tool_shovel_'..mat_id)
    local axe_id = id('tool_axe_'..mat_id)
    local sword_id = id('tool_sword_'..mat_id)

    minetest.register_tool( pick_id, {
        description = mat_name .. ' Pickaxe',
        inventory_image = tex(pick_id),
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
    minetest.register_craft{ output = pick_id,
        recipe = {
            {craft_item_id, craft_item_id, craft_item_id},
            {'', stick, ''},
            {'', stick, ''}
    }}
    terumet.register_repairable_item(pick_id, ingot_repair_value*3)

    minetest.register_tool( shovel_id, {
        description = mat_name .. ' Shovel',
        inventory_image = tex(shovel_id),
        tool_capabilities = {
            full_punch_interval = math.max(0.4, 1.0 - (max_level * 0.15)),
            max_drop_level = max_level,
            groupcaps = {
                crumbly = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=1+math.floor(max_level / 2)}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = shovel_id,
        recipe = {
            {craft_item_id},
            {stick},
            {stick}
    }}
    terumet.register_repairable_item(shovel_id, ingot_repair_value)

    minetest.register_tool( axe_id, {
        description = mat_name .. ' Axe',
        inventory_image = tex(axe_id),
        tool_capabilities = {
            full_punch_interval = math.max(0.5, 1.0 - (max_level * 0.15)),
            max_drop_level = max_level,
            groupcaps = {
                choppy = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=2+max_level}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = axe_id,
        recipe = {
            {craft_item_id, craft_item_id},
            {craft_item_id, stick},
            {'', stick}
    }}
    minetest.register_craft{ output = axe_id,
    recipe = {
        {craft_item_id, craft_item_id},
        {stick, craft_item_id},
        {stick, ''}
    }}
    terumet.register_repairable_item(axe_id, ingot_repair_value*3)

    minetest.register_tool( sword_id, {
        description = mat_name .. ' Sword',
        inventory_image = tex(sword_id),
        tool_capabilities = {
            full_punch_interval = math.max(0.4, 1.2 - (max_level * 0.2)),
            max_drop_level = max_level,
            groupcaps = {
                snappy = {times=dig_times, uses=base_use_count, maxlevel=max_level},
            },
            damage_groups = {fleshy=sword_damage}
        },
        sound = {breaks = 'default_tool_breaks'}
    })
    minetest.register_craft{ output = sword_id,
        recipe = {
            {craft_item_id},
            {craft_item_id},
            {stick}
    }}
    terumet.register_repairable_item(sword_id, ingot_repair_value*2)
end