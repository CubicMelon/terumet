-- add armor when 3darmor mod is also active

function gen_armor_groups(type, data)
    local grps = {
        armor_use=data.uses, 
        armor_heal=data.heal, 
        physics_speed=data.speed, 
        physics_gravity=data.gravity,
        physics_jump=data.jump,
    }
    grps[type]=1
    return grps
end

function reg_recipe_boots(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, '', mat},
        {mat, '', mat}
    }}
end

function reg_recipe_legs(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, mat, mat},
        {mat, '', mat},
        {mat, '', mat}
    }}
end

function reg_recipe_chest(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, '', mat},
        {mat, mat, mat},
        {mat, mat, mat}
    }}
end

function reg_recipe_helm(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, mat, mat},
        {mat, '', mat},
    }}
end

function reg_terumet_armor(data)
    if not data or not data.suffix or not data.mat then error('Missing data on registering Terumetal armor') end
    data.uses = data.uses or 500
    data.def = data.def or 10
    data.heal = data.heal or 0
    data.speed = data.speed or 0
    data.gravity = data.gravity or 0
    data.jump = data.jump or 0
    data.dgroups = data.dgroups or {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
    data.name = data.name or data.suffix

    local boots_id = terumet.id('armor_boots_'..data.suffix)
    local desc = data.name..' Boots'
    if data.xinfo then desc=desc..'\n'..data.xinfo end
    armor:register_armor(boots_id, {
        description= desc,
        inventory_image = terumet.tex('invboots_'..data.suffix),
        texture = terumet.tex('armboots_'..data.suffix),
        preview = terumet.tex('prvboots_'..data.suffix),
        groups = gen_armor_groups('armor_feet', data),
        armor_groups = {fleshy=data.def},
        damage_groups = data.dgroups,
    })
    reg_recipe_boots(boots_id, data.mat)

    local helm_id = terumet.id('armor_helm_'..data.suffix)
    desc = data.name..' Helmet'
    if data.xinfo then desc=desc..'\n'..data.xinfo end
    armor:register_armor(helm_id, {
        description= desc,
        inventory_image = terumet.tex('invhelm_'..data.suffix),
        texture = terumet.tex('armhelm_'..data.suffix),
        preview = terumet.tex('prvhelm_'..data.suffix),
        groups = gen_armor_groups('armor_head', data),
        armor_groups = {fleshy=data.def},
        damage_groups = data.dgroups,
    })
    reg_recipe_helm(helm_id, data.mat)

    local chest_id = terumet.id('armor_chest_'..data.suffix)
    desc = data.name..' Chestplate'
    if data.xinfo then desc=desc..'\n'..data.xinfo end
    armor:register_armor(chest_id, {
        description= desc,
        inventory_image = terumet.tex('invchest_'..data.suffix),
        texture = terumet.tex('armchest_'..data.suffix),
        preview = terumet.tex('prvchest_'..data.suffix),
        groups = gen_armor_groups('armor_torso', data),
        armor_groups = {fleshy=(data.def * 1.5)},
        damage_groups = data.dgroups,
    })
    reg_recipe_chest(chest_id, data.mat)

    local legs_id = terumet.id('armor_legs_'..data.suffix)
    desc = data.name..' Greaves'
    if data.xinfo then desc=desc..'\n'..data.xinfo end
    armor:register_armor(legs_id, {
        description= desc,
        inventory_image = terumet.tex('invlegs_'..data.suffix),
        texture = terumet.tex('armlegs_'..data.suffix),
        preview = terumet.tex('prvlegs_'..data.suffix),
        groups = gen_armor_groups('armor_legs', data),
        armor_groups = {fleshy=(data.def * 1.5)},
        damage_groups = data.dgroups,
    })
    reg_recipe_legs(legs_id, data.mat)
end

reg_terumet_armor{suffix='tcop', name='Terucopper', mat=terumet.id('ingot_tcop'), def=12, heal=0, uses=500}
reg_terumet_armor{suffix='ttin', name='Terutin', mat=terumet.id('ingot_ttin'), def=8, heal=5, speed=0.1, xinfo='[Speed++]', uses=300}
reg_terumet_armor{suffix='tste', name='Terusteel', mat=terumet.id('ingot_tste'), def=20, heal=0, speed=-0.05, xinfo='[Speed-]', uses=1000}
reg_terumet_armor{suffix='tcha', name='Teruchalcum', mat=terumet.id('ingot_tcha'), def=14, heal=10, uses=2000}
reg_terumet_armor{suffix='tgol', name='Terugold', mat=terumet.id('ingot_tgol'), def=10, heal=20, gravity=-0.15, xinfo='[Float++]', uses=200}
reg_terumet_armor{suffix='cgls', name='Coreglass', mat=terumet.id('ingot_cgls'), def=24, heal=5, speed=0.05, jump=0.08, xinfo='[Speed+] [Jump+]', uses=500}