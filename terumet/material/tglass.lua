local tglass_id = terumet.id('block_tglass')

local tiles, glowtiles

if terumet.options.cosmetic.CLEAR_GLASS then
    tiles = {terumet.tex('block_tglass_frame'), terumet.tex('blank')}
    glowtiles = {terumet.tex('block_tglassglow_frame'), terumet.tex('blank')}
else
    tiles = {terumet.tex('block_tglass_frame'), terumet.tex('block_tglass_streak')}
    glowtiles = {terumet.tex('block_tglassglow_frame'), terumet.tex('block_tglassglow_streak')}
end

minetest.register_node(tglass_id, {
    description = 'Terumetal Glass',
    drawtype= 'glasslike_framed_optional',
    paramtype = "light",
    tiles = tiles,
    is_ground_content = false,
    sunlight_propagates = true,
    groups = {cracky = 1, level = 3},
    sounds = default.node_sound_glass_defaults(),
	on_blast = terumet.blast_chance(30, tglass_id),
})

local tglass_glow_id = tglass_id..'glow'

minetest.register_node(tglass_glow_id, {
    description = 'Terumetal Glow Glass',
    drawtype= 'glasslike_framed_optional',
    paramtype = "light",
    tiles = glowtiles,
    is_ground_content = false,
    sunlight_propagates = true,
    light_source=13,
    groups = {cracky = 1, level = 3},
    sounds = default.node_sound_glass_defaults(),
	on_blast = terumet.blast_chance(15, tglass_glow_id),
})