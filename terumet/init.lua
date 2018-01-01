
terumet = {}
terumet.version = {major=1, minor=0, patch=0}
local ver = terumet.version
terumet.version_text = ver.major .. '.' .. ver.minor .. '.' .. ver.patch
terumet.mod_name = "terumet"

-- will hold alloys creatable by alloy smelter in the format {result={teru=X, constituent_1, constituent_2, etc.}}
-- X = number of raw terumetal lumps required
terumet.alloy_recipes = {}

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

dofile(terumet.lua_file('reg_metal'))
dofile(terumet.lua_file('reg_alloy'))
dofile(terumet.lua_file('reg_tools'))

terumet.reg_metal('Terumetal', 'raw')
minetest.register_ore{
    ore_type = 'scatter',
    ore = terumet.id('ore_raw'),
    wherein = 'default:stone',
    clust_scarcity = 12 * 12 * 12,
    clust_num_ores = 4,
    clust_size = 4,
    y_min = -30000,
    y_max = 8
}
minetest.register_ore{
    ore_type = 'scatter',
    ore = terumet.id('ore_raw_desert'),
    wherein = 'default:desert_stone',
    clust_scarcity = 12 * 10 * 8,
    clust_num_ores = 4,
    clust_size = 6,
    y_min = -30000,
    y_max = 64
}

terumet.reg_alloy('Terucopper', 'tcop', 1, {flux=1, time=3.0, 'default:copper_lump'})
terumet.reg_alloy('Terusteel', 'tste', 2, {flux=2, time=4.0, 'default:iron_lump'})
terumet.reg_alloy('Terugold', 'tgol', 3, {flux=3, time=5.0, 'default:gold_lump'})
terumet.reg_alloy('Coreglass', 'cgls', 4, {flux=5, time=10.0, 'default:diamond', 'default:obsidian_shard'})

terumet.alloy_recipes[terumet.id('block_alloy_tcop')] = {flux=7, time=35.0, 'default:copperblock'}
terumet.alloy_recipes[terumet.id('block_alloy_tste')] = {flux=15, time=45.0, 'default:ironblock'}
terumet.alloy_recipes[terumet.id('block_alloy_tgol')] = {flux=24, time=60.0, 'default:goldblock'}
terumet.alloy_recipes[terumet.id('block_alloy_cgls')] = {flux=30, time=180.0, 'default:diamondblock', 'default:obsidian'}

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
