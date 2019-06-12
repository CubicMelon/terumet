local id = terumet.id
local tex = terumet.tex

local upg_base_id = id('item_upg_base')

minetest.register_craftitem( upg_base_id, {
    description = 'Machine Upgrade Base',
    inventory_image = tex('upg_base')
})

minetest.register_craft{ output = upg_base_id, recipe = {
    {terumet.id('item_ceramic'), terumet.id('item_glue'), terumet.id('item_ceramic')},
    {terumet.id('item_coil_raw'), terumet.id('item_coil_raw'), terumet.id('item_coil_raw')},
}}

function terumet.register_machine_upgrade(upgrade_id, desc, source, source2, src_pattern, xinfo)
    local item_id = id('item_upg_'..upgrade_id)

    if xinfo then
        desc = string.format('%s\n%s', desc, minetest.colorize(terumet.options.armor.EFFECTS_TEXTCOLOR, xinfo))
    end

    minetest.register_craftitem( item_id, {
        description = desc,
        inventory_image = tex('upg_'..upgrade_id),
        _terumach_upgrade_id = upgrade_id
    })

    if not src_pattern then src_pattern = 'default' end
    local rec
    local shapeless=false
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
    elseif src_pattern == 'single' then
        rec={upg_base_id, source}
        shapeless=true
    elseif src_pattern == 'none' then
        return
    end

    if shapeless then
        minetest.register_craft{ output=item_id, recipe=rec, type='shapeless' }
    else
        minetest.register_craft{ output=item_id, recipe=rec}
    end
end

terumet.register_machine_upgrade('ext_input', 'External Input Upgrade', 'default:chest', id('item_coil_tcop'), 'left', 'Item input from block immediately to left')
terumet.register_machine_upgrade('ext_output', 'External Output Upgrade', 'default:chest', id('item_coil_tcop'), 'right', 'Item output to block immediately to right')
terumet.register_machine_upgrade('max_heat', 'Maximum Heat Upgrade', id('ingot_tste'), id('item_thermese'), nil, 'Double machine HU storage')
terumet.register_machine_upgrade('heat_xfer', 'Heat Transfer Upgrade', id('item_coil_tgol'), id('item_cryst_gold'), nil, 'Send and recieve HU faster')
terumet.register_machine_upgrade('gen_up', 'Heat Generation Upgrade', id('item_coil_tgol'), id('item_cryst_mese'), nil, '[Heaters only] Generate more HU')
terumet.register_machine_upgrade('speed_up', 'Speed Upgrade', id('ingot_cgls'), id('item_cryst_dia'), nil, 'Double machine processing speed')
terumet.register_machine_upgrade('cryst', 'Crystallization Upgrade', id('item_cryst_dia'), id('item_entropy'), nil, '[Crystal Vulcanizer only] +1 yield for triple cost/time')
terumet.register_machine_upgrade('tmcrys', 'Terumetal Specialization Upgrade', id('ingot_tste'), id('item_cryst_raw'), nil, '[Crystal Vulcanizer only] +2 yield for double cost/time\nMachine can only process Terumetal')

terumet.register_machine_upgrade('cheat', 'Infinite Heat Upgrade', nil, nil, 'none', 'Testing or cheating tool')