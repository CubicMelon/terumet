-- VERY much a WIP!
local tbox_id = terumet.id('mach_thermobox')

minetest.register_node( tbox_id, {
    description = 'Thermobox',
    tiles = {terumet.tex(tbox_id)},
    is_ground_content = false,
    groups={cracky=1, level=2},
    sounds = default.node_sound_glass_defaults(),
    on_construct = function(pos)
        minetest.get_meta(pos):set_string('infotext', 'WIP - Nonfunctional')
    end
})

minetest.register_craft{ output = tbox_id,
    recipe = {
        {terumet.id('item_coil_tgol'), terumet.id('item_thermese'), terumet.id('item_coil_tgol')},
        {terumet.id('item_thermese'), terumet.id('block_ceramic'), terumet.id('item_thermese')},
        {terumet.id('item_coil_tgol'), terumet.id('item_thermese'), terumet.id('item_coil_tgol')}
    }
}
