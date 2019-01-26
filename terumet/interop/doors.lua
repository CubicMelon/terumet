-- order door type can be converted
local type_order = {'full', 'mesh', 'slat', 'vert'}
local type_names = {
    full='Solid %s Door',
    mesh='Meshed %s Door',
    slat='Slatted %s Door',
    vert='Fancy %s Door'
}

local materials = {
    tcop={
        item=terumet.id('ingot_tcop'),
        name='Terucopper',
        level=1
    },
    ttin={
        item=terumet.id('ingot_ttin'),
        name='Terutin',
        level=1
    },
    tste={
        item=terumet.id('ingot_tste'),
        name='Terusteel',
        level=2
    },
    tcha={
        item=terumet.id('ingot_tcha'),
        name='Teruchalcum',
        level=2
    },
    tgol={
        item=terumet.id('ingot_tgol'),
        name='Terugold',
        level=3
    },
    cgls={
        item=terumet.id('ingot_cgls'),
        name='Coreglass',
        level=4
    }
}

for mat_id, mat_data in pairs(materials) do
    local first_door_id = nil
    local prev_door_id = nil
    for _, type_id in pairs(type_order) do
        local type_name = type_names[type_id]
        local door_id = terumet.id(string.format('door%s_%s', type_id, mat_id))
        local door_tex = terumet.tex(string.format('door%s_%s', type_id, mat_id))
        local door_invtex = terumet.tex(string.format('dinv%s_%s', type_id, mat_id))
        local door_recipe = nil
        if not prev_door_id then
            door_recipe = {
                {mat_data.item, mat_data.item},
                {mat_data.item, mat_data.item},
                {mat_data.item, mat_data.item}
            }
        end
        doors.register(door_id, {
            tiles = {{name = door_tex, backface_culling = true}},
            description = string.format(type_name, mat_data.name),
            inventory_image = door_invtex,
            protected = true,
            groups = {cracky = 1, level = mat_data.level},
            sounds = default.node_sound_metal_defaults(),
            sound_open = 'doors_steel_door_open',
            sound_close = 'doors_steel_door_close',
            recipe = door_recipe
        })

        if prev_door_id then
            minetest.register_craft{ type='shapeless', output=door_id, recipe={prev_door_id} }
        end

        if not first_door_id then first_door_id = door_id end
        prev_door_id = door_id
    end
    minetest.register_craft{ type='shapeless', output=first_door_id, recipe={prev_door_id} }
end
