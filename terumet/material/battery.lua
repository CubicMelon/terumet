local FMT = string.format

function terumet.register_battery(data)
    local battery_id = terumet.id('item_batt_'..data.id)
    local full_battery_id = terumet.id('item_batt_'..data.id..'_full')

    minetest.register_craftitem( battery_id, {
        description = FMT('%s Heat Battery (Empty)\n%s', data.name, minetest.colorize('#b0b0b0', FMT('Stores %d HU', data.hus))),
        stack_max = 1,
        inventory_image = terumet.tex(battery_id),
        groups={_terumetal_battery=1},
        _empty_battery_info={change_to=full_battery_id, fill=data.hus}
    })

    local battery_recipe_row = {data.cover_item_id, data.core_item_id, data.cover_item_id}

    minetest.register_craft{ output = battery_id,
    recipe = {
        battery_recipe_row, battery_recipe_row, battery_recipe_row
    }}

    minetest.register_craftitem( full_battery_id, {
        description = FMT('%s Heat Battery (Full)\n%s', data.name, minetest.colorize('#ffa2ba', FMT('Stores %d HU', data.hus))),
        stack_max = 1,
        inventory_image = terumet.tex(full_battery_id),
        groups={_terumetal_battery=2},
    })

    if data.heat_time then
        minetest.register_craft{ type = 'cooking',
            output = full_battery_id,
            recipe = battery_id,
            cooktime = data.heat_time
        }
    end

    terumet.options.machine.BASIC_HEAT_SOURCES[full_battery_id] = {hus=data.hus, return_item=battery_id}
end

local standard_rate = terumet.options.heater.furnace.GEN_HUPS

-- 40 sec = burn time of 1 coal (default)
terumet.register_battery{ id='cop', name='Copper', cover_item_id='terumet:ingot_raw', core_item_id='default:copper_ingot', heat_time=40, hus=(standard_rate * 40) }

-- 370 sec = burn time of 1 coal block (default)
terumet.register_battery{ id='therm', name='Thermese', cover_item_id='terumet:item_ceramic', core_item_id='terumet:item_thermese', heat_time=370, hus=(standard_rate * 370) }


local void_id = terumet.id('item_batt_void')

minetest.register_craftitem( void_id, {
    description = FMT('Void "Battery"\n%s', minetest.colorize('#b0b0b0', 'Voids HU from machine')),
    stack_max = 1,
    inventory_image = terumet.tex(void_id),
    groups={_terumetal_battery=1},
    _empty_battery_info={void=true}
})

minetest.register_craft{ output = void_id,
    recipe = {
        {'default:cobble', 'terumet:item_entropy', 'default:cobble'}
}}