local ingot_id = terumet.id('ingot_meson')
local meson_color = '#be61ff'

minetest.register_craftitem( ingot_id, {
    description = 'Fused Meson Ingot',
    inventory_image = terumet.tex(ingot_id),
    groups = {ingot = 1},
})

local toolstat = {times={1.3, 1.1, 0.9}, uses=0, maxlevel=5}

minetest.register_tool( terumet.id('tool_meson'), {
    description = minetest.colorize(meson_color, 'Fused Meson Omni-tool'),
    inventory_image = terumet.tex('tool_meson'),
    wield_scale={x=1.8, y=1.8, z=1.4},
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 99,
        groupcaps = {
            cracky = toolstat,
            crumbly = toolstat,
            choppy = toolstat,
            snappy = toolstat,
        },
        damage_groups = {fleshy=4},
    },
})

--[[
Meson Fusion Reactor

Accepts items that yield repair material to create a critical mass. This mass is then superheated and Meson Fusion is attempted.

The chance of successful fusion is based on:
    - The quality of materials used (the fewer items used -> higher chance)
    - The time taken to reach the necessary heat (less time -> higher chance)

For 1 attempt at fusion the following is needed:
    60 x 50 = 3500 RMP (repair material points) -- This averages to approx. 50 between alloyed iron and gold.
    500000 HU -- assuming an average of 10000/second, averages to 50 seconds
]]