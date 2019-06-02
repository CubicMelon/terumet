local FMT = string.format

function terumet.register_battery(data)
    local battery_id = terumet.id('item_batt_'..data.id)
    local full_battery_id = terumet.id('item_batt_'..data.id..'_full')

    minetest.register_craftitem( battery_id, {
        description = FMT('%s Heat Battery (Empty)', data.name),
        inventory_image = terumet.tex(battery_id),
        groups={_terumetal_battery=1},
    })

    local battery_recipe_row = {data.cover_item_id, data.core_item_id, data.cover_item_id}

    minetest.register_craft{ output = battery_id,
    recipe = {
        battery_recipe_row, battery_recipe_row, battery_recipe_row
    }}

    minetest.register_craftitem( full_battery_id, {
        description = FMT('%s Heat Battery (Full)\n[%d HUs]', data.name, data.hus),
        inventory_image = terumet.tex(full_battery_id),
        groups={_terumetal_battery=2},
    })

    minetest.register_craft{ type = 'cooking',
        output = full_battery_id,
        recipe = battery_id,
        cooktime = data.heat_time
    }

    terumet.options.machine.BASIC_HEAT_SOURCES[full_battery_id] = {hus=data.hus, return_item=battery_id}
end

-- 100HU/tick
-- 40 ticks = 1 piece of coal (by default)
terumet.register_battery{ id='cop', name='Copper', cover_item_id='terumet:ingot_raw', core_item_id='default:copper_ingot', heat_time=40, hus=4000 }

terumet.register_battery{ id='therm', name='Thermese', cover_item_id='terumet:item_ceramic', core_item_id='terumet:item_thermese', heat_time=200, hus=20000 }