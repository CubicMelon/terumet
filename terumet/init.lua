-- Terumet v1.1

-- Mod for open-source voxel game Minetest (https://www.minetest.net/)
-- Written for Minetest version 0.4.16
-- Creates a new ore in the world which can be used to make useful alloys
-- from many already available materials.

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
terumet.version = {major=1, minor=1, patch=0}
local ver = terumet.version
terumet.version_text = ver.major .. '.' .. ver.minor .. '.' .. ver.patch
terumet.mod_name = "terumet"

function terumet.format_time(t)
    return string.format('%.1f s', t or 0)
end

function terumet.lua_file(name)
    return minetest.get_modpath(terumet.mod_name) .. '/' .. name .. '.lua'
end

function terumet.id(item_name, count)
    if count then
        return terumet.mod_name .. ':' .. item_name .. ' ' .. count
    else
        return terumet.mod_name .. ':' .. item_name
    end
end

function terumet.tex_file(tex_name)
    return terumet.mod_name .. "_" .. tex_name .. '.png'
end

function terumet.tex_composite(base_tex, overlay_name)
    return base_tex .. '^' .. terumet.tex_file(overlay_name)
end

function terumet.reg_item(item_id, texture, name)
    minetest.register_craftitem( terumet.id(item_id), {
        description = name,
        inventory_image = terumet.tex_file(texture)
    })
end

-- will hold alloys creatable by alloy smelter in the format {result={teru=X, constituent_1, constituent_2, etc.}}
-- X = number of raw terumetal lumps required
terumet.alloy_recipes = {}
dofile(terumet.lua_file('options'))
dofile(terumet.lua_file('machine'))
dofile(terumet.lua_file('reg_metal'))
dofile(terumet.lua_file('reg_alloy'))
dofile(terumet.lua_file('reg_tools'))

terumet.reg_metal('Terumetal', 'raw')
minetest.register_ore{
    ore_type = 'scatter',
    ore = terumet.id('ore_raw'),
    wherein = 'default:stone',
    clust_scarcity = 12 * 12 * 12,
    clust_num_ores = 6,
    clust_size = 4,
    y_min = -30000,
    y_max = 8
}
minetest.register_ore{
    ore_type = 'scatter',
    ore = terumet.id('ore_raw_desert'),
    wherein = 'default:desert_stone',
    clust_scarcity = 12 * 10 * 8,
    clust_num_ores = 6,
    clust_size = 6,
    y_min = -30000,
    y_max = 64
}

local opts = terumet.options.alloys
terumet.reg_alloy('Terucopper', 'tcop', 1, opts.COPPER)
terumet.reg_alloy('Terusteel', 'tste', 2, opts.IRON)
terumet.reg_alloy('Terugold', 'tgol', 3, opts.GOLD)
terumet.reg_alloy('Coreglass', 'cgls', 4, opts.COREGLASS)

terumet.alloy_recipes[terumet.id('block_alloy_tcop')] = opts.COPPER_BLOCK
terumet.alloy_recipes[terumet.id('block_alloy_tste')] = opts.IRON_BLOCK
terumet.alloy_recipes[terumet.id('block_alloy_tgol')] = opts.GOLD_BLOCK
terumet.alloy_recipes[terumet.id('block_alloy_cgls')] = opts.COREGLASS_BLOCK

terumet.reg_tools('Terumetal', 'traw',
    terumet.id('ingot_raw'),
    {2.0}, 10, 2
)
terumet.reg_tools('Terucopper', 'tcop', 
    terumet.id('ingot_alloy_tcop'),
    {3.2, 1.4, 0.8}, 40, 1 
)
terumet.reg_tools('Terusteel', 'tste', 
    terumet.id('ingot_alloy_tste'),
    {2.9, 1.3, 0.7}, 50, 2
)
terumet.reg_tools('Terugold', 'tgol', 
    terumet.id('ingot_alloy_tgol'),
    {2.7, 1.2, 0.63}, 60, 3
)
terumet.reg_tools('Coreglass', 'cgls',
    terumet.id('ingot_alloy_cgls'),
    {2.5, 1.2, 0.7}, 75, 4
)

dofile(terumet.lua_file('asmelt'))
