-- Terumet v2.3

-- Mod for open-source voxel game Minetest (https://www.minetest.net/)
-- Written for Minetest IN-DEV version 5.0.0
-- Creates a new ore in the world which can be used to make useful alloys
-- and heat-powered machines.

-- By Terumoc [https://github.com/Terumoc]
-- and with contributions from:
--  > RSL-Redstonier [https://github.com/RSL-Redstonier]
--  > Chem871 [https://github.com/Chemguy99] for many ideas and requests

--[[ Copyright (C) 2017-2018 Terumoc (Scott Horvath)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>. ]]

terumet = {}
terumet.version = {major=2, minor=3, patch=0}
local ver = terumet.version
terumet.version_text = ver.major .. '.' .. ver.minor .. '.' .. ver.patch
terumet.mod_name = "terumet"

terumet.RAND = PcgRandom(os.time())

function terumet.chance(pct)
    if pct <= 0 then return false end
    if pct >= 100 then return true end
    return terumet.RAND:next(1,100) <= pct
end

-- function for a node's on_blast callback to be removed with a pct% chance
function terumet.blast_chance(pct, id)
    return function(pos)
        if terumet.chance(pct) then
            minetest.remove_node(pos)
            return {id}
        else
            return nil
        end
    end
end

-- empty function useful for where a callback is necessary but using nil would cause undesired default behavior
terumet.NO_FUNCTION = function() end
terumet.EMPTY = {}
terumet.ZERO_XYZ = {x=0,y=0,z=0}

function terumet.recipe_3x3(i)
    return { 
        {i, i, i}, {i, i, i}, {i, i, i}
    }
end

function terumet.recipe_box(outer, inner)
    return {
        {outer, outer, outer}, {outer, inner, outer}, {outer, outer, outer}
    }
end

function terumet.recipe_plus(i)
    return {
        {'', i, ''}, {i, i, i}, {'', i, ''}
    }
end

function terumet.random_velocity(max_tenths)
    return {
        x = terumet.RAND:next(-max_tenths,max_tenths) / 10,
        y = terumet.RAND:next(-max_tenths,max_tenths) / 10,
        z = terumet.RAND:next(-max_tenths,max_tenths) / 10
    }
end

function terumet.particle_stream(pointA, pointB, density, particle_data, player)
    local dist_vector = {x=(pointB.x-pointA.x), y=(pointB.y-pointA.y), z=(pointB.z-pointA.z)}
    local dist = vector.length(dist_vector)
    local pcount = dist * density
    if pcount < 1 then return end -- guard against div/0
    local step = {x=(dist_vector.x/pcount), y=(dist_vector.y/pcount), z=(dist_vector.z/pcount)}
    local ppos = vector.new(pointA)
    for pnum = 1,pcount do
        ppos = util3d.pos_plus(ppos, step)
        minetest.add_particle{
            pos = vector.new(ppos),
            velocity=terumet.random_velocity(5),
            expirationtime=(particle_data.expiration or 1),
            size=(particle_data.size or 1),
            glow=(particle_data.glow or 1),
            playername=player,
            texture=particle_data.texture,
            animation=particle_data.animation
        }
    end
end

function terumet.format_time(t)
    return string.format('%.1f s', t or 0)
end

function terumet.do_lua_file(name)
    dofile(minetest.get_modpath(terumet.mod_name) .. '/' .. name .. '.lua')
end

-- create a copy of node groups from an unlit machine for lit version of machine
function terumet.create_lit_node_groups(unlit_groups)
    local new_groups = {not_in_creative_inventory=1}
    for k,v in pairs(unlit_groups) do new_groups[k] = v end
    return new_groups
end

function terumet.itemstack_desc(stack)
    local stack_desc = stack:get_definition().description
    -- use only what is before a newline if one is in the description
    if stack_desc:find('\n') then stack_desc = stack_desc:match('(.*)\n') end
    if stack:get_count() > 1 then 
        return string.format('%s (x%d)', stack_desc, stack:get_count())
    else
        return stack_desc
    end
end

-- given a table with 'group:XXX' keys and a node/item definition with groups, return the
-- (first) value in the table where node/item has a group key of XXX, otherwise nil
function terumet.match_group_key(table, def)
    if not def then return nil end
    for group_name,_ in pairs(def.groups) do
        local grp_key = 'group:'..group_name
        if table[grp_key] then
            return table[grp_key]
        end
    end
    return nil
end

function terumet.id(id, number)
    if number then
        return string.format('%s:%s %d', terumet.mod_name, id, number)
    else
        return string.format('%s:%s', terumet.mod_name, id)
    end
end

function terumet.give_player_item(pos, player, stack)
    local inv = player:get_inventory()
    local leftover = inv:add_item("main", stack)
    if leftover and not leftover:is_empty() then
        minetest.item_drop(leftover, player, player:get_pos())
    end
end

function terumet.tex(id)
    -- accepts both base ids (assuming this mod) and full mod ids
    -- ex: terumet.tex('ingot_raw') -> 'terumet_ingot_raw.png'
    --     terumet.tex('default:cobble') -> 'default_cobble.png'
    if id:match(':') then
        return string.format('%s.png', id:gsub(':', '_'))
    else
        return string.format('%s_%s.png', terumet.mod_name, id)
    end
end

function terumet.crystal_tex(color)
    return string.format('%s^(%s^[multiply:%s)',terumet.tex('item_cryst_bg'),terumet.tex('item_cryst_fg'),color)
end

function terumet.tex_comp(base_tex, overlay_id)
    return base_tex .. '^' .. terumet.tex(overlay_id)
end

function terumet.tex_trans(id, rot)
    return terumet.tex(id) .. '^[transform' .. rot
end

terumet.do_lua_file('util3d')

terumet.do_lua_file('interop/terumet_api')
terumet.do_lua_file('options')
terumet.do_lua_file('machine/generic/machine')
terumet.do_lua_file('material/raw')
terumet.do_lua_file('material/reg_alloy')
terumet.do_lua_file('material/upgrade')
terumet.do_lua_file('material/entropy')

-- reg_alloy(name, id, block hardness level, repair material value)
terumet.reg_alloy('Terucopper', 'tcop', 1, 20)
terumet.reg_alloy('Terutin', 'ttin', 1, 15)
terumet.reg_alloy('Terusteel', 'tste', 2, 40)
terumet.reg_alloy('Terugold', 'tgol', 3, 80)
terumet.reg_alloy('Coreglass', 'cgls', 4, 120)
terumet.reg_alloy('Teruchalcum', 'tcha', 2, 60)

terumet.do_lua_file('material/ceramic')
terumet.do_lua_file('material/thermese')
terumet.do_lua_file('material/coil')
terumet.do_lua_file('material/crushed')
terumet.do_lua_file('material/pwood')
terumet.do_lua_file('material/tglass')
terumet.do_lua_file('material/rebar')
terumet.do_lua_file('material/misc')

terumet.do_lua_file('material/crystallized')

local id = terumet.id
local tex = terumet.tex

-- register raw terumetal ingot as weak repair-material
terumet.register_repair_material(id('ingot_raw'), 10)

terumet.do_lua_file('tool/reg_tools')

local sword_opts = terumet.options.tools.sword_damage

terumet.reg_tools('Pure Terumetal', 'raw',
    id('ingot_raw'),
    {2.0}, 10, 2, sword_opts.TERUMETAL, 10
)
terumet.reg_tools('Terucopper', 'tcop', 
    id('ingot_tcop'),
    {3.2, 1.4, 0.8}, 40, 1, sword_opts.COPPER_ALLOY, 20
)
terumet.reg_tools('Terusteel', 'tste', 
    id('ingot_tste'),
    {2.9, 1.3, 0.7}, 50, 2, sword_opts.IRON_ALLOY, 40
)
terumet.reg_tools('Terugold', 'tgol', 
    id('ingot_tgol'),
    {2.7, 1.2, 0.63}, 60, 3, sword_opts.GOLD_ALLOY, 80
)
terumet.reg_tools('Coreglass', 'cgls',
    id('ingot_cgls'),
    {2.5, 1.2, 0.7}, 75, 4, sword_opts.COREGLASS, 120
)
terumet.reg_tools('Teruchalcum', 'tcha',
    id('ingot_tcha'),
    {1.8, 0.7, 0.45}, 90, 2, sword_opts.BRONZE_ALLOY, 60
)

-- register default tools as repairable
-- default metal values of 1 ingot:
local dmv_values = {steel=10, bronze = 30, mese = 90, diamond = 100}
-- each type of tool based on ingots used to make
for dmat, value in pairs(dmv_values) do
    terumet.register_repairable_item("default:pick_"..dmat, value*3)
    terumet.register_repairable_item("default:axe_"..dmat, value*3)
    terumet.register_repairable_item("default:shovel_"..dmat, value)
    terumet.register_repairable_item("default:sword_"..dmat, value*2)
end

terumet.do_lua_file('tool/ore_saw')

terumet.do_lua_file('machine/heater/furnace_htr')
terumet.do_lua_file('machine/heater/solar_htr')
terumet.do_lua_file('machine/heater/entropic_htr')
terumet.do_lua_file('machine/asmelt')
terumet.do_lua_file('machine/htfurnace')
terumet.do_lua_file('machine/vulcan')
terumet.do_lua_file('machine/thermobox')
terumet.do_lua_file('machine/thermdist')
terumet.do_lua_file('machine/lavam')
terumet.do_lua_file('machine/meseg')
terumet.do_lua_file('machine/repm')
terumet.do_lua_file('machine/crusher')

terumet.do_lua_file('machine/transfer/heatray')
terumet.do_lua_file('machine/transfer/hline')
terumet.do_lua_file('machine/transfer/hline_in')

-- register default blocks that can be converted into heatline or reinforced blocks
terumet.register_convertable_block('default:stone', 'stone')
terumet.register_convertable_block('default:cobble', 'cobble')
terumet.register_convertable_block('default:stonebrick', 'stonebrick')
terumet.register_convertable_block('default:stone_block', 'stoneblock')
terumet.register_convertable_block('default:desert_stone', 'desertstone')
terumet.register_convertable_block('default:desert_cobble', 'desertcobble')
terumet.register_convertable_block('default:desert_stonebrick', 'desertstonebrick')
terumet.register_convertable_block('default:wood', 'wood')
terumet.register_convertable_block('default:junglewood', 'junglewood')
terumet.register_convertable_block('default:pine_wood', 'pinewood')
terumet.register_convertable_block('default:acacia_wood', 'acaciawood')
terumet.register_convertable_block('default:aspen_wood', 'aspenwood')
terumet.register_convertable_block('terumet:block_pwood', 'pwood')

if minetest.global_exists('unified_inventory') then 
    terumet.do_lua_file('interop/unified_inventory')
end

if minetest.global_exists('tubelib') then
    terumet.do_lua_file('interop/tubelib')
end