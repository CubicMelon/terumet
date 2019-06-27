local heater_id = terumet.id('item_heater_basic')
minetest.register_craftitem( heater_id, {
    description = 'Terumetal Heating Unit',
    inventory_image = terumet.tex(heater_id)
})

minetest.register_craft{ output = heater_id,
    recipe = {
        {'basic_materials:heating_element'},
        {terumet.id('item_coil_raw')},
        {'basic_materials:heating_element'},
    }
}

-- =============================================

local therm_elem_id = terumet.id('item_helem_therm')
minetest.register_craftitem( therm_elem_id, {
    description = 'Thermese Heating Element',
    inventory_image = terumet.tex(therm_elem_id)
})

minetest.register_craft{output = therm_elem_id .. ' 2',
    recipe = {{ terumet.id('ingot_tcop'), terumet.id('item_thermese'), terumet.id('ingot_tcop') }},
}

-- =============================================

local heater2_id = terumet.id('item_heater_therm')
minetest.register_craftitem( heater2_id, {
    description = 'Thermese Heating Unit',
    inventory_image = terumet.tex(heater2_id)
})

minetest.register_craft{ output = heater2_id,
    recipe = {
        {therm_elem_id},
        {terumet.id('item_coil_tgol')},
        {therm_elem_id},
    }
}

-- =============================================

local htg_id = terumet.id('item_htglass')
minetest.register_craftitem( htg_id, {
    description = 'Heat-transference Glass',
    inventory_image = terumet.tex(htg_id)
})

minetest.register_craft{ output = htg_id .. ' 3',
    recipe = {
        {'', 'default:obsidian_glass', ''},
        {terumet.id('item_cryst_tin'), terumet.id('item_glue'), terumet.id('item_cryst_tin')},
        {'', terumet.id('item_dust_ob'), ''}
    }
}

-- =============================================

local emit_id = terumet.id('item_heatunit')

minetest.register_craftitem( emit_id, {
    description = 'High Energy Alpha-wave Transmission Unit',
    inventory_image = terumet.tex(emit_id)
})

minetest.register_craft{ output = emit_id,
    recipe = {
        {terumet.id('ingot_tgol'), 'default:obsidian_glass', terumet.id('ingot_tgol')},
        {terumet.id('item_thermese'), 'default:mese_crystal', terumet.id('item_thermese')},
        {terumet.id('item_ceramic'), terumet.id('item_coil_tgol'), terumet.id('item_ceramic')}
    }
}

-- =============================================

local press_id = terumet.id('item_press')
minetest.register_craftitem( press_id, {
    description = 'Terutin Expansion Press',
    inventory_image = terumet.tex(press_id)
})

minetest.register_craft{ output = press_id,
    recipe = {
        {'default:stone', terumet.id('block_ttin'), 'default:stone'},
        {terumet.id('ingot_tcha'), terumet.id('ingot_tcha'), terumet.id('ingot_tcha')},
        {terumet.id('ingot_ttin'), terumet.id('ingot_ttin'), terumet.id('ingot_ttin')}
    }
}

-- =============================================

local cryscham_id = terumet.id('item_cryscham')
minetest.register_craftitem( cryscham_id, {
    description = 'Crystal Growth Chamber',
    inventory_image = terumet.tex(cryscham_id)
})

minetest.register_craft{ output = cryscham_id,
    recipe = {
        {'default:obsidian_glass', 'default:obsidian_glass', 'default:obsidian_glass'},
        {terumet.id('item_dust_ob'), terumet.id('item_dust_ob'), terumet.id('item_dust_ob')},
        {terumet.id('ingot_tcha'), 'bucket:bucket_water', terumet.id('ingot_tcha')}
    },
    replacements={{'bucket:bucket_water','bucket:bucket_empty'}}
}
