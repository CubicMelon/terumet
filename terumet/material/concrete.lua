local CONCRETE_COLORS = {
    '#FFF',--white
    '#AAA',--grey
    '#666',--dark grey
    '#333',--black
    '#722ed4',--violet
    '#2e56d4',--blue
    '#2ec2d4',--cyan
    '#135918',--dark green
    '#3ad42e',--green
    '#d4c12e',--yellow
    '#592e13',--brown
    '#d4652e',--orange
    '#d42e2e',--red
    '#d80481',--magenta
    '#ff7272',--pink
}
local mix_base = terumet.id('block_conmix')
local block_base = terumet.id('block_con')

local FMT = string.format

local function mix_id(dye_index)
    return FMT("%s_%s", mix_base, dye.dyes[dye_index][1])
end
function terumet.concrete_block_id(dye_index)
    return FMT("%s_%s", block_base, dye.dyes[dye_index][1])
end

local NAMEFORMATS = {
    mix="%s Concrete Mix",
    block="%s Concrete Block",
    door="%s Concrete Door",
    wall="%s Concrete Wall",
    stair="%s Concrete Stair",
    slab="%s Concrete Slab"
}

local function make_name(name, dye_index)
    return FMT(NAMEFORMATS[name], dye.dyes[dye_index][2])
end

local function texture(base, dye_index)
    return FMT("%s^[multiply:%s", base, CONCRETE_COLORS[dye_index])
end
local function mix_texture(dye_index)
    return texture(terumet.tex('block_conmix'), dye_index)
end
local function block_texture(dye_index)
    return texture(terumet.tex('block_con'), dye_index)
end
local function door_texture(dye_index)
    return texture(terumet.tex('door_con'), dye_index)
end
local function door_item_texture(dye_index)
    return texture(terumet.tex('dinv_con'), dye_index)
end

local HARDEN_LIST = {}
local MIXES_LIST = {}

for index,dye_info in ipairs(dye.dyes) do
    local con_id = 'con_'..dye_info[1]

    minetest.register_node(mix_id(index), {
        description = make_name('mix', index),
        tiles = {mix_texture(index)},
        is_ground_content = false,
        groups = {crumbly=2, falling_node=1},
        sounds = default.node_sound_sand_defaults(),
    })

    local block_id = terumet.concrete_block_id(index)

    minetest.register_node(block_id, {
        description = make_name('block', index),
        tiles = {block_texture(index)},
        is_ground_content = false,
        groups = {cracky = 2, level = 1},
        sounds = default.node_sound_stone_defaults(),
    })

    if index ~= 1 then
        local dye_id = "group:dye,color_"..dye_info[1]
        local basic_powder = mix_id(1)
        minetest.register_craft{
            output = mix_id(index)..' 8',
            recipe = terumet.recipe_box(basic_powder, dye_id)
        }

        minetest.register_craft{
            output = mix_id(index)..' 8',
            recipe = terumet.recipe_box(basic_powder, 'dye:'..dye_info[1])
        }
    end

    HARDEN_LIST[mix_id(index)] = block_id
    table.insert(MIXES_LIST, mix_id(index))

    terumet.register_convertible_block(block_id, con_id)

    walls.register(terumet.id('wall_'..con_id), make_name('wall', index), block_texture(index), block_id, default.node_sound_stone_defaults())

    doors.register(terumet.id('door_'..con_id), {
        tiles = {{name = door_texture(index), backface_culling = true}},
        description = make_name('door', index),
        inventory_image = door_item_texture(index),
        protected = true,
        groups = {cracky = 2, level = 1},
        sounds = default.node_sound_stone_defaults(),
        sound_open = 'doors_steel_door_open',
        sound_close = 'doors_steel_door_close',
        recipe = {
            {block_id},
            {'doors:door_steel'},
            {block_id},
        }
    })

    if minetest.get_modpath('stairs') then
        stairs.register_stair_and_slab(con_id, block_id,
            {cracky = 2, level = 1},
            {block_texture(index)},
            make_name('stair',index), make_name('slab', index),
            default.node_sound_stone_defaults(),
            false
        )
    end
end

minetest.register_abm{
    label = 'Concrete mix hardening',
    nodenames = MIXES_LIST,
    neighbors = {'default:water_source', 'default:water_flowing'},
    interval = 3.0, -- Run every 3 seconds
    chance = 1, -- always
    action = function(pos, node, active_object_count, active_object_count_wider)
        local harden_id = HARDEN_LIST[node.name]
        if harden_id then
            minetest.set_node(pos, {name = harden_id})
        end
    end
}

local gravel_id = 'default:gravel'
local any_sand = 'group:sand'

minetest.register_craft{
    output = mix_id(1)..' 8',
    recipe = {
        {any_sand, gravel_id, any_sand},
        {gravel_id, '', gravel_id},
        {any_sand, gravel_id, any_sand}
    }
}