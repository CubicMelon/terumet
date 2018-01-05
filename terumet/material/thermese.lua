local thcrys_id = terumet.id('item_thermese')
local thblock_id = terumet.id('block_thermese')

minetest.register_craftitem( thcrys_id, {
    description = 'Thermese Crystal',
    inventory_image = terumet.tex(thcrys_id)
})

minetest.register_node( thblock_id, {
    description = 'Thermese Block',
    tiles = {terumet.tex('block_thermese')},
    is_ground_content = false,
    groups={cracky=3, level=2},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = thblock_id,
    recipe = terumet.recipe_3x3(thcrys_id)
}

minetest.register_craft{ type = 'shapeless', output = terumet.id('item_thermese', 9),
    recipe = {thblock_id}
}

local thblock_hot_id = terumet.id('block_thermese_hot')

minetest.register_node( thblock_hot_id, {
    description = 'Heated Thermese Block',
    tiles = {terumet.tex('block_thermese_hot')},
    is_ground_content = false,
    light_source=6,
    groups={cracky=2, level=2},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_abm{
    label = 'Thermese Block Heating',
    nodenames = {thblock_id},
    neighbors = {'default:lava_source'},
    interval = 3.0,
    chance = 1,
    catch_up = false,
    action = function(pos, node, active_obj_ct, active_obj_ct_wider)
        minetest.sound_play( 'terumet_heat_up', {
            pos = pos,
            gain = 1.0,
            max_hear_distance = 32
        })
        node.name = thblock_hot_id
        minetest.swap_node(pos, node)
    end
}