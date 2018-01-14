local id = terumet.id
local tex = terumet.tex

local upg_base_id = id('item_upg_base')

minetest.register_craftitem( upg_base_id, {
    description = 'Machine Upgrade Base',
    inventory_image = tex('upg_base')
})

minetest.register_craft{ output = upg_base_id, recipe = {
    {'', terumet.id('item_ceramic'), ''},
    {terumet.id('item_ceramic'), terumet.id('item_coil_raw'), terumet.id('item_ceramic')},
    {'', terumet.id('item_ceramic'), ''}
}}

function terumet.register_machine_upgrade(suffix, desc, source, source2)
    local item_id = id('item_upg_'..suffix)
    minetest.register_craftitem( item_id, {
        description = desc,
        inventory_image = tex('upg_'..suffix),
    })

    minetest.register_craft{ output=item_id, recipe = {
        {source2 or '', source, source2 or ''},
        {source, upg_base_id, source},
        {source2 or '', source, source2 or ''}
    }}
end

terumet.register_machine_upgrade('chest', 'Automation Upgrade', id('item_coil_tcop'), 'default:chest')
terumet.register_machine_upgrade('max_heat', 'Maximum Heat Upgrade', id('ingot_tste'), id('item_thermese'))
terumet.register_machine_upgrade('heat_xfer', 'Heat Transfer Upgrade', id('item_coil_tgol'), id('item_cryst_gold'))
terumet.register_machine_upgrade('speed_up', 'Speed Upgrade', id('ingot_cgls'), id('item_cryst_dia'))