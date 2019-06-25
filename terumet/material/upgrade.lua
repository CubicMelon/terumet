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

function terumet.register_machine_upgrade(upgrade_id, desc, source, source2, src_pattern, xinfo, xmach)
    local item_id = id('item_upg_'..upgrade_id)

    if xmach then
        desc = desc .. '\nUsable: ' .. minetest.colorize(terumet.options.misc.TIP_UPGRADE_MACHINE_COLOR, xmach)
    end
    if xinfo then
        desc = terumet.item_desc(desc, xinfo)
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
    elseif src_pattern == 'simple' then
        rec=source
        shapeless=true
    elseif src_pattern == 'none' then
        return
    end

    if shapeless then
        minetest.register_craft{ output=item_id, recipe=rec, type='shapeless' }
    else
        minetest.register_craft{ output=item_id, recipe=rec}
    end
    return item_id
end

local in_up = terumet.register_machine_upgrade('ext_input', 'External Input Upgrade', 'default:chest', id('item_coil_tcop'), 'left', 'Item input from adjacent block', 'Any machine with input')
local out_up = terumet.register_machine_upgrade('ext_output', 'External Output Upgrade', 'default:chest', id('item_coil_tcop'), 'right', 'Item output to adjacent block', 'Any machine with output')
terumet.register_machine_upgrade('max_heat', 'Maximum Heat Upgrade', id('ingot_tste'), id('item_thermese'), nil, 'Double machine HU storage', 'Any machine')
terumet.register_machine_upgrade('heat_xfer', 'Heat Transfer Upgrade', id('item_coil_tgol'), id('item_cryst_gold'), nil, 'Send and recieve HU faster', 'Any machine')
terumet.register_machine_upgrade('gen_up', 'Heat Generation Upgrade', id('item_coil_tgol'), id('item_cryst_mese'), nil, 'Generate more HU', 'Any Heater (Furnace/Solar/EEE)')
terumet.register_machine_upgrade('speed_up', 'Speed Upgrade', id('ingot_cgls'), id('item_cryst_dia'), nil, 'Double machine processing speed', 'Any machine')
terumet.register_machine_upgrade('cryst', 'Crystallization Upgrade', id('item_cryst_dia'), id('item_entropy'), nil, '+1 yield for triple cost/time', 'Crystal Vulcanizer only')
terumet.register_machine_upgrade('tmcrys', 'Terumetal Specialization Upgrade', id('ingot_tste'), id('item_cryst_raw'), nil, '+2 yield for double cost/time\nMachine can only process Terumetal', 'Crystal Vulcanizer only')

terumet.register_machine_upgrade('ext_both', 'External Input/Output Upgrade', {in_up, out_up, 'group:glue', id('item_thermese')}, nil, 'simple', 'Item input and output to adjacent block(s)', 'Any machine with input/output')

terumet.register_machine_upgrade('cheat', 'Infinite Heat Upgrade', nil, nil, 'none', 'Testing or cheating tool', 'Any machine')


local SETS = {
    ALL={cheat=1, max_heat=1, heat_xfer=1, speed_up=1},
    heater={gen_up=1},
    input={ext_input=1, ext_both=1, tubelib=1},
    output={ext_output=1, ext_both=1, tubelib=1},
    crystal={cryst=1, tmcrys=1},
}
-- given a list of "upgrade sets" defined above, return all upgrades in those set(s) plus ALL
function terumet.valid_upgrade_sets(set_list)
    local list = table.copy(SETS.ALL)
    if set_list and type(set_list) == 'table' then
        for _,set in ipairs(set_list) do
            for upgrade,_ in pairs(SETS[set]) do
                list[upgrade] = 1
            end
        end
    end
    return list
end