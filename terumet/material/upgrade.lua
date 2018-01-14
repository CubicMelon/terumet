local id = terumet.id
local tex = terumet.tex

local upg_base_id = id('item_upg_base')

minetest.register_craftitem( upg_base_id, {
    description = 'Machine Upgrade Base',
    inventory_image = tex('upg_base')
})

minetest.register_craft{ output = upg_base_id, recipe = {
    {terumet.id('item_coil_raw'), terumet.id('item_ceramic'), terumet.id('item_coil_raw')},
    {terumet.id('item_ceramic'), terumet.id('item_ceramic'), terumet.id('item_ceramic')},
    {terumet.id('item_coil_raw'), terumet.id('item_ceramic'), terumet.id('item_coil_raw')}
}}

function terumet.register_machine_upgrade(suffix, desc, source, source2, src_pattern)
    local item_id = id('item_upg_'..suffix)
    minetest.register_craftitem( item_id, {
        description = desc,
        inventory_image = tex('upg_'..suffix),
        _upgradetype = suffix
    })

    if not src_pattern then src_pattern = 'default' end
    local rec
    if src_pattern == 'default' then
        rec={
            {source2 or '', source, source2 or ''},
            {source, upg_base_id, source},
            {source2 or '', source, source2 or ''}
        }
    elseif src_pattern == 'left' then
        rec={
            {source2, source2, source2},
            {source, upg_base_id, source2},
            {source2, source2, source2}
        }
    elseif src_pattern == 'right' then
        rec={
            {source2, source2, source2},
            {source2, upg_base_id, source},
            {source2, source2, source2}
        }
    end
    minetest.register_craft{ output=item_id, recipe = rec}
end

terumet.register_machine_upgrade('ext_input', 'External Input Upgrade', 'default:chest', id('item_coil_tcop'), 'left')
terumet.register_machine_upgrade('ext_output', 'External Output Upgrade', 'default:chest', id('item_coil_tcop'), 'right')
terumet.register_machine_upgrade('max_heat', 'Maximum Heat Upgrade', id('ingot_tste'), id('item_thermese'))
terumet.register_machine_upgrade('heat_xfer', 'Heat Transfer Upgrade', id('item_coil_tgol'), id('item_cryst_gold'))
terumet.register_machine_upgrade('speed_up', 'Speed Upgrade', id('ingot_cgls'), id('item_cryst_dia'))