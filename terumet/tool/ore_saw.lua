local id = terumet.id
local saw_id = id('tool_ore_saw')
local opts = terumet.options.ore_saw

minetest.register_tool( saw_id, {
    description = 'Ore-cutting Saw\nEasily excavates ore nodes',
    inventory_image = terumet.tex(saw_id),
    tool_capabilities = {},
    sound = {breaks = 'default_tool_breaks'},
    on_use = function (itemstack, user, pointed_thing)
        if pointed_thing.type == 'node' and pointed_thing.under then
            local npos = pointed_thing.under
            local node_id = minetest.get_node(npos).name
            if opts.VALID_ORES[node_id] then
                terumet.give_player_item(user.pos, user, node_id)
                minetest.remove_node(npos)
                minetest.sound_play( 'terumet_saw', {
                    pos = npos,
                    gain = 0.3,
                    max_hear_distance = 12
                })
                itemstack:add_wear(65535 / opts.USES)
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
})

minetest.register_craft{ output = saw_id,
    recipe = {
        {id('ingot_tcha'), id('ingot_tcha'), id('ingot_tste')},
        {id('ingot_tcha'), id('ingot_tcha'), id('ingot_tste')},
        {'', id('ingot_tste'), ''}
}}