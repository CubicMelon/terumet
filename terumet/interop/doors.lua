-- WIP
--[[ local ingu = terumet.id('ingot_tste')

doors.register(terumet.id("door_tste"), {
    tiles = {{name = terumet.tex('door_tste'), backface_culling = true}},
    description = 'Terusteel Door',
    inventory_image = 'doors_item_steel',
    protected = true,
    groups = {cracky = 1, level = 2},
    sounds = default.node_sound_metal_defaults(),
    sound_open = 'doors_steel_door_open',
    sound_close = 'doors_steel_door_close',
    recipe = {
        {ingu, ingu},
        {ingu, ingu},
        {ingu, ingu},
    }
}) ]]