--[[ Terumet v3.2

Mod for open-source voxel game Minetest (https://www.minetest.net/)
Written for Minetest version 5.0.0
Now also supports Minetest 0.4.17

Creates a new ore in the world which can be used to make useful alloys
and heat-powered machines.

By Terumoc [https://github.com/Terumoc]
and with contributions from:
  > obl3pplifp (https://github.com/obl3pplifp) for bug reports, information, ideas, and other considerable contributions
  > RSL-Redstonier [https://github.com/RSL-Redstonier]
  > Chem871 [https://github.com/Chemguy99] for many ideas and requests

BIG Thanks to all contributors for their input!

]]--

--[[ Copyright (C) 2017-2019 Terumoc (Scott Horvath)

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
terumet.version = {major=3, minor=2, patch=1}
terumet.mod_name = "terumet"

-- inject global functions into mod namespace (do_lua_file, etc.)
dofile(minetest.get_modpath(terumet.mod_name) .. '/global.lua')(terumet)

-- this isn't the suggested way to check for game version but... it works for my purposes
terumet.legacy = minetest.get_version().string:find('0.4')
if terumet.legacy then
    minetest.log('[terumet] MTv0.4.* detected - in legacy mode!')
end

local FMT = string.format
minetest.register_chatcommand( 'item_info', {
    params = '',
    description = 'Get a complete description of the ItemStack in your hand',
    privs = {debug=true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local witem = player:get_wielded_item()
            if witem:is_empty() then
                return true, "You're not holding anything."
            else
                local def = witem:get_definition()
                local wear = witem:get_wear()
                local wear_pct = FMT('%.1f%%', wear / 65535 * 100.0)
                if def then
                    return true, FMT('%s "%s" #%s/%s w:%s (%s)',
                        minetest.colorize('#ff0', witem:get_name()),
                        def.description,
                        witem:get_count(),
                        minetest.colorize('#0ff', def.stack_max),
                        minetest.colorize('#f0f', wear),
                        minetest.colorize('#f0f', wear_pct)
                    )
                else
                    return true, FMT('*NO DEF* %s #%s w:%s (%s)',
                        minetest.colorize('#ff0', witem:get_name()),
                        witem:get_count(),
                        minetest.colorize('#f0f', wear),
                        minetest.colorize('#f0f', wear_pct)
                    )
                end
            end
        else
            return false, "You aren't a player somehow, sorry?!"
        end
    end
})

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

function terumet.format_time(t)
    return string.format('%.1f s', t or 0)
end

-- create a copy of node groups from an unlit machine for lit version of machine
function terumet.create_lit_node_groups(unlit_groups)
    local new_groups = {not_in_creative_inventory=1}
    for k,v in pairs(unlit_groups) do new_groups[k] = v end
    return new_groups
end

function terumet.description(name, xinfo)
    if xinfo then
        return string.format("%s\n%s", name, minetest.colorize(terumet.options.misc.TIP_COLOR, xinfo))
    else
        return name
    end
end

function terumet.crystal_tex(color)
    return string.format('%s^[multiply:%s', terumet.tex('item_cryst'), color)
end

function terumet.tex_trans(id, rot)
    return terumet.tex(id) .. '^[transform' .. rot
end

local HEAR_DIST = 12
terumet.squishy_node_sounds = {
    footstep = {name='terumet_squish_step', max_hear_distance=HEAR_DIST},
    dig = {name='terumet_squish_dig', max_hear_distance=HEAR_DIST},
    dug = {name='terumet_squish_dug', max_hear_distance=HEAR_DIST},
    place = {name='terumet_squish_place', max_hear_distance=HEAR_DIST},
}

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
terumet.do_lua_file('material/battery')

local id = terumet.id

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

terumet.do_lua_file('tool/ore_saw')

-- setup mesecon piston interop before machines are defined
if minetest.get_modpath('mesecon') then -- no 's'
    terumet.do_lua_file('interop/mesecons')
end

terumet.do_lua_file('machine/heater/furnace_htr')
terumet.do_lua_file('machine/heater/solar_htr')
terumet.do_lua_file('machine/heater/entropic_htr')
terumet.do_lua_file('machine/asmelt')
terumet.do_lua_file('machine/htfurnace')
terumet.do_lua_file('machine/vulcan')
terumet.do_lua_file('machine/lavam')
terumet.do_lua_file('machine/meseg')
terumet.do_lua_file('machine/repm')
terumet.do_lua_file('machine/crusher')
terumet.do_lua_file('machine/vacoven')

terumet.do_lua_file('machine/transfer/heatray')
terumet.do_lua_file('machine/transfer/hline')
terumet.do_lua_file('machine/transfer/hline_in')
terumet.do_lua_file('machine/transfer/thermobox')
terumet.do_lua_file('machine/transfer/thermdist')

-- register default blocks that can be converted into heatline or reinforced blocks
terumet.register_convertible_block('default:stone', 'stone')
terumet.register_convertible_block('default:cobble', 'cobble')
terumet.register_convertible_block('default:stonebrick', 'stonebrick')
terumet.register_convertible_block('default:stone_block', 'stoneblock')
terumet.register_convertible_block('default:desert_stone', 'desertstone')
terumet.register_convertible_block('default:desert_cobble', 'desertcobble')
terumet.register_convertible_block('default:desert_stonebrick', 'desertstonebrick')
terumet.register_convertible_block('default:wood', 'wood')
terumet.register_convertible_block('default:junglewood', 'junglewood')
terumet.register_convertible_block('default:pine_wood', 'pinewood')
terumet.register_convertible_block('default:acacia_wood', 'acaciawood')
terumet.register_convertible_block('default:aspen_wood', 'aspenwood')
terumet.register_convertible_block('terumet:block_pwood', 'pwood')

-- register repairable default tools and materials
-- {value of 1 item, item id}:
local dmv_values = {
    steel={10, 'default:steel_ingot'},
    bronze={30, 'default:bronze_ingot'},
    mese={90, 'default:mese_crystal'},
    diamond={100, 'default:diamond'}
}

for dmat, v in pairs(dmv_values) do
    terumet.register_repairable_item("default:pick_"..dmat, v[1]*3)
    terumet.register_repairable_item("default:axe_"..dmat, v[1]*3)
    terumet.register_repairable_item("default:shovel_"..dmat, v[1])
    terumet.register_repairable_item("default:sword_"..dmat, v[1]*2)
    terumet.register_repair_material(v[2], v[1])
end

terumet.do_lua_file('material/concrete')
terumet.do_lua_file('material/coalproc')

--experimental stuff
--terumet.do_lua_file('material/meson')

local INTEROPS = {'3d_armor', 'doors', 'unified_inventory', 'tubelib', 'dungeon_loot', 'moreores', 'farming', 'extra'}
for _,mod in ipairs(INTEROPS) do
    if minetest.get_modpath(mod) then terumet.do_lua_file('interop/'..mod) end
end

local vacfood_options = terumet.options.vac_oven.VAC_FOOD
if vacfood_options and vacfood_options.ACTIVE then terumet.do_lua_file('material/vacfood') end

terumet.do_lua_file('interop/crusher_misc')