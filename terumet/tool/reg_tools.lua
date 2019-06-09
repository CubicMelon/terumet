local id = terumet.id
local tex = terumet.tex
local opts = terumet.options.tools
local FMT = string.format

-- given a tool defintion, return a NEW definition with upgrade's changes
local TOOL_UPGRADES = {
    rng = function(orig)
        local new = table.copy(orig)
        new.range = opts.UPGRADES.rng.effect
        return new
    end,
    spd = function(orig)
        local new = table.copy(orig)
        new.tool_capabilities.full_punch_interval = math.max(0.25, new.tool_capabilities.full_punch_interval * opts.UPGRADES.spd.effect)
        for _,gdata in pairs(new.tool_capabilities.groupcaps) do
            for index,tool_time in ipairs(gdata.times) do
                gdata.times[index] = tool_time * opts.UPGRADES.spd.effect
            end
        end
        return new
    end,
    dur = function(orig)
        local new = table.copy(orig)
        for _,gdata in pairs(new.tool_capabilities.groupcaps) do
            local old_uses = gdata.uses
            gdata.uses = math.floor(old_uses * opts.UPGRADES.dur.effect)
        end
        return new
    end,
}

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

    if opts.UPGRADES then
        local each_tool = {pick=3,shovel=1,axe=3,sword=2}
        for tool_id,ingot_cost in pairs(each_tool) do
            local base_tool_id = id(FMT('tool_%s_%s', tool_id, mat_id))
            for up_id,upgrade in pairs(opts.UPGRADES) do
                local upgraded_tool_id = base_tool_id .. '_up' .. up_id
                local upgraded_tool_def = TOOL_UPGRADES[up_id](minetest.registered_tools[base_tool_id])
                upgraded_tool_def.inventory_image = FMT('%s^%s', upgraded_tool_def.inventory_image, tex(FMT('toolup_%s_%s', tool_id, up_id)))
                upgraded_tool_def.description = FMT('%s\n%s', minetest.colorize(upgrade.color, FMT('%s %s', upgrade.nametag, upgraded_tool_def.description)), upgrade.xinfo)

                minetest.register_tool(upgraded_tool_id, upgraded_tool_def)
                terumet.register_alloy_recipe{input={base_tool_id, upgrade.item}, result=upgraded_tool_id, time=(upgrade.time or 5), flux=(upgrade.flux or 4)}
                terumet.register_repairable_item(upgraded_tool_id, math.floor(ingot_repair_value * ingot_cost * (upgrade.repmult or 1.5)))
            end
        end
    end
end