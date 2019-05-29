local rebar_id = terumet.id('item_rebar')

minetest.register_craftitem( rebar_id, {
    description = 'Teruchalcum Rebar',
    inventory_image = terumet.tex('item_rebar'),
})

minetest.register_craft{ output=rebar_id..' 5', recipe=terumet.recipe_plus('terumet:ingot_tcha') }

local desc = {'Reinforced %s', 'Double-reinforced %s', 'Triple-reinforced %s'}
local blchance = {40, 20, 3}

local function reinf_block_id(code, rlv)
    return minetest.get_current_modname()..':reinf_block_'..code..rlv
end

function terumet.register_reinforced_block(base, code)
    local base_def = minetest.registered_nodes[base]
    if not base_def then error('base '..base..' is not defined') end

    for rlv = 1,3 do
        local def = {}
        for k,v in pairs(base_def) do
            if k == 'groups' then
                def.groups = {}
                for gk,gv in pairs(v) do
                    if not terumet.options.misc.BLOCK_REMOVE_GROUPS[gk] then
                        def.groups[gk]=gv
                    end
                end
            else
                def[k] = v
            end
        end
        if not base_def.groups then
            def.groups = {level=(rlv+1)}
        else
            def.groups.level = (base_def.groups.level or 1) + rlv
        end
        local id = reinf_block_id(code, rlv)

        def.description = string.format(desc[rlv], base_def.description)

        local visibility = terumet.options.cosmetic.REINFORCING_VISIBLE
        if visibility then
            local tileov = terumet.tex('blockov_rebar'..rlv)
            if visibility == 1 then
                def.overlay_tiles = {tileov, tileov, '', '', '', ''}
            else
                def.overlay_tiles = {tileov}
            end
        end

        def.on_blast = terumet.blast_chance(blchance[rlv], id)

        minetest.register_node(id, def)

        local recbase
        if rlv == 1 then
            recbase = base
            minetest.register_craft{ output=id..' 4', recipe = {
                {rebar_id, recbase, rebar_id},
                {recbase, '', recbase},
                {rebar_id, recbase, rebar_id}
            }}
        elseif rlv == 2 then
            recbase = reinf_block_id(code, 1)
            minetest.register_craft{ output=id..' 4', recipe = {
                {rebar_id, recbase, rebar_id},
                {recbase, '', recbase},
                {rebar_id, recbase, rebar_id}
            }}
        else
            recbase = reinf_block_id(code, 2)
            minetest.register_craft{ output=id..' 4', recipe = {
                {rebar_id, recbase, rebar_id},
                {recbase, '', recbase},
                {rebar_id, recbase, rebar_id}
            }}
        end
    end
end
