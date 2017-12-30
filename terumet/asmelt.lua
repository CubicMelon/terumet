
local alloy_smelter_full_id = terumet.id('mach_asmelt')

local alloy_smelter_can_dig = function() return true end

local alloy_smelter_nodedef = {
    description = "Terumetal Alloy Smelter",
    tiles = {
        terumet.tex_file('block_raw'), terumet.tex_file('block_raw'),
        terumet.tex_file('asmelt_sides'), terumet.tex_file('asmelt_sides'),
        terumet.tex_file('asmelt_sides'), terumet.tex_file('asmelt_front')
    },
    paramtype2 = 'facedir',
    groups = {cracky=1},
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    can_dig = alloy_smelter_can_dig,
    legacy_facedir_simple = true,
    --on_construct =
    --on_blast (return drops)
}

minetest.register_node(alloy_smelter_full_id , alloy_smelter_nodedef)

minetest.register_craft{ output = alloy_smelter_full_id, recipe = {
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')},
    {'bucket:bucket_empty', 'default:copperblock', 'bucket:bucket_empty'},
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')}
}}