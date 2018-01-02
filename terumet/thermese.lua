local therm_full_id = terumet.id('item_thermese')
local thblock_full_id = terumet.id('block_thermese')

terumet.reg_item('Thermese Crystal', 'item_thermese')
minetest.register_node( terumet.id('block_thermese'), {
    description = 'Thermese Block',
    tiles = {terumet.tex_file('block_thermese')},
    is_ground_content = false,
    groups={cracky=3, level=2},
    sounds = default.node_sound_glass_defaults()
})

minetest.register_craft{ output = thblock_full_id,
recipe = {
    {therm_full_id, therm_full_id, therm_full_id},
    {therm_full_id, therm_full_id, therm_full_id},
    {therm_full_id, therm_full_id, therm_full_id}
}}

minetest.register_craft{ type = 'shapeless', output = terumet.id('item_thermese', 9),
    recipe = {thblock_full_id}
}

terumet.alloy_recipes[therm_full_id] = terumet.options.alloys.THERMESE_CRYSTAL
