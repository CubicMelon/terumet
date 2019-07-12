local opts = terumet.options.ore_saw

local function saw_use_function(use_count)
    return function (itemstack, user, pointed_thing)
        if pointed_thing.type == 'node' and pointed_thing.under then
            local npos = pointed_thing.under
            local node_id = minetest.get_node(npos).name
            if opts.VALID_ORES[node_id] and not minetest.is_protected(npos, user:get_player_name()) then
                terumet.give_player_item(user.pos, user, node_id)
                minetest.remove_node(npos)
                minetest.sound_play( 'terumet_saw', {
                    pos = npos,
                    gain = 0.3,
                    max_hear_distance = 12
                })
                itemstack:add_wear(65535 / use_count)
            else
                minetest.sound_play( 'terumet_saw_fail', {
                    pos = npos,
                    gain = 0.3,
                    max_hear_distance = 12
                })
            end
        end
        return itemstack
    end
end

local basic_id = terumet.id('tool_ore_saw')
local advanced_id = terumet.id('tool_ore_saw_adv')

minetest.register_tool( basic_id, {
    description = terumet.description('Ore-cutting Saw', 'Excavates ore blocks'),
    inventory_image = terumet.tex(basic_id),
    range = 2,
    tool_capabilities = {},
    wield_scale={x=1.5, y=1.5, z=1.0},
    sound = {breaks = 'default_tool_breaks'},
    on_use = saw_use_function(opts.BASIC_USES)
})

local blade_item = terumet.id('ingot_tcha')
local handle_item = terumet.id('ingot_tste')

minetest.register_craft{ output = basic_id,
    recipe = {
        {blade_item, blade_item, handle_item},
        {blade_item, blade_item, handle_item},
        {'', handle_item, ''}
}}

terumet.register_repairable_item(basic_id, 240) -- 4x value of ingot_tcha

minetest.register_tool( advanced_id, {
    description = terumet.description('Advanced Ore-cutting Saw', 'Excavates ore blocks (more durable & better range)'),
    inventory_image = terumet.tex(advanced_id),
    range = 4,
    tool_capabilities = {},
    wield_scale={x=1.8, y=1.8, z=1.4},
    sound = {breaks = 'default_tool_breaks'},
    on_use = saw_use_function(opts.ADVANCED_USES)
})

terumet.register_alloy_recipe{input={basic_id, terumet.id('item_rubber', 3), terumet.id('ingot_cgls')}, result=advanced_id, time=10, flux=6}

terumet.register_repairable_item(advanced_id, 400) -- basic + coreglass + 40
