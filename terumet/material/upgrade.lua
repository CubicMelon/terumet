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

function terumet.register_machine_upgrade(upgrade_id, desc, xinfo, xmach, recipe)
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

    if recipe then
        if recipe.no_base then
            recipe.no_base = nil
        else
            table.insert(recipe, upg_base_id)
        end
        minetest.register_craft{ output=item_id, recipe=recipe, type='shapeless' }
    end

    return item_id
end

local gear_id = 'basic_materials:gear_steel'
local motor_id = 'basic_materials:motor'
local thermese_id = id('item_thermese')
local xfercoil_id = id('item_coil_tgol')
local heater_id = id('item_heater_therm')
local superheater_id = id('item_heater_array')
local encrys_id = 'basic_materials:energy_crystal_simple'
local entropy_id = id('item_entropy')
local cryscham_id = id('item_cryscham')

local in_up = terumet.register_machine_upgrade('ext_input', 'External Input Upgrade', 'Item input from adjacent block', 'Any machine with input', {gear_id, motor_id, gear_id})
local out_up = terumet.register_machine_upgrade('ext_output', 'External Output Upgrade', 'Item output to adjacent block', 'Any machine with output', {motor_id, gear_id, motor_id})
terumet.register_machine_upgrade('max_heat', 'Maximum Heat Upgrade', 'Double machine HU storage', 'Any machine', {thermese_id, thermese_id, thermese_id})
terumet.register_machine_upgrade('heat_xfer', 'Heat Transfer Upgrade', 'Send and recieve HU faster', 'Any machine', {xfercoil_id, xfercoil_id, xfercoil_id})
terumet.register_machine_upgrade('gen_up', 'Heat Generation Upgrade', 'Generate more HU', 'Any Heater (Furnace/Solar/EEE)', {heater_id, heater_id, heater_id})
terumet.register_machine_upgrade('speed_up', 'Speed Upgrade', 'Double machine processing speed', 'Any machine', {superheater_id, encrys_id, encrys_id, encrys_id, id('item_cryst_dia'), id('item_cryst_dia'), id('item_cryst_dia')})
terumet.register_machine_upgrade('cryst', 'Crystallization Upgrade', '+1 yield for triple cost/time', 'Crystal Vulcanizer only', {superheater_id, encrys_id, encrys_id, encrys_id, entropy_id, entropy_id, entropy_id, cryscham_id})
terumet.register_machine_upgrade('tmcrys', 'Terumetal Specialization Upgrade', '+2 yield for double cost/time\nMachine can only process Terumetal', 'Crystal Vulcanizer only', {heater_id, cryscham_id, cryscham_id, id('item_cryst_raw'), id('item_cryst_raw'), id('item_cryst_raw')})

terumet.register_machine_upgrade('ext_both', 'External Input/Output Upgrade', 'Item input and output to adjacent block(s)', 'Any machine with input/output', {no_base=true, in_up, out_up, 'group:glue', id('item_thermese')})

terumet.register_machine_upgrade('cheat', 'Infinite Heat Upgrade', 'Testing or cheating tool', 'Any machine')


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