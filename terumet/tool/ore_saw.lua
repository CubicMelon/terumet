local id = terumet.id
local saw_id = id('tool_ore_saw')

minetest.register_tool( saw_id, {
    description = 'Ore-Carving Saw',
    inventory_image = terumet.tex(saw_id),
    tool_capabilities = {}, -- does not function like normal tool
    sound = {breaks = 'default_tool_breaks'},
    on_use = function (itemstack, user, pointed_thing)
        minetest.chat_send_all(dump(user)..'used saw on '..dump(pointed_thing))
    end
})

minetest.register_craft{ output = saw_id,
    recipe = {
        {id('ingot_cgls'), id('ingot_cgls'), id('ingot_tste')},
        {id('ingot_cgls'), id('ingot_tste'), id('ingot_cgls')},
        {id('ingot_tste'), id('ingot_cgls'), id('ingot_cgls')}
}}