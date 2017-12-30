
local asmelt = {}
asmelt.full_id = terumet.id('mach_asmelt')

asmelt.inactive_formspec = 'size[8,8.5]'

function asmelt.start_timer(pos)
    minetest.get_node_timer(pos):start(1.0)
end

function asmelt.generate_active_formspec()
end

function asmelt.init(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string('formspec', asmelt.inactive_formspec)
    local inv = meta:get_inventory()
    inv:set_size('teru', 1)
    inv:set_size('fuel', 1)
    inv:set_size('in', 2)
    inv:set_size('dst', 4)
end

function asmelt.can_dig(pos, player)
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory()
    return inv:is_empty("teru") and inv:is_empty("fuel") and inv:is_empty("in") and inv:is_empty("dst")
end

function asmelt.on_blast(pos)
    local drops = {}
    default.get_inventory_drops(pos, "teru", drops)
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "in", drops)
    default.get_inventory_drops(pos, "dst", drops)
    drops[#drops+1] = asmelt.full_id
    minetest.remove_node(pos)
end

function asmelt.tick()
end

asmelt.nodedef = {
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
    legacy_facedir_simple = true,
    can_dig = asmelt.can_dig,
    on_construct = asmelt.init,
    on_metadata_inventory_move = asmelt.start_timer,
    on_metadata_inventory_put = asmelt.start_timer,
    on_timer = asmelt.tick,
    on_blast = asmelt.on_blast
}

minetest.register_node(asmelt.full_id, asmelt.nodedef)

minetest.register_craft{ output = asmelt.full_id, recipe = {
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')},
    {'bucket:bucket_empty', 'default:copperblock', 'bucket:bucket_empty'},
    {terumet.id('ingot_raw'), 'default:furnace', terumet.id('ingot_raw')}
}}