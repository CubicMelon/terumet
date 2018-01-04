local reg_coil = function(name, mat)
    local coil_id = terumet.id('item_coil_'..mat)
    minetest.register_craftitem( coil_id, {
        description = name,
        inventory_image = terumet.tex(coil_id)
    })
    minetest.register_craft{ output=coil_id .. ' 8',
        recipe = terumet.recipe_box(terumet.id('ingot_'..mat), 'default:stick')
    }
end

reg_coil('Pure Terumetal Coil', 'raw')
reg_coil('Terucopper Coil', 'tcop')
reg_coil('Terugold Coil', 'tgol')

