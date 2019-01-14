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
    data.def = data.def or 1
    data.defhi = data.defhi or 2
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
        armor_groups = {fleshy=data.defhi},
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
        armor_groups = {fleshy=data.defhi},
        damage_groups = data.dgroups,
    })
    reg_recipe_legs(legs_id, data.mat)
end

-- Tercopper: 8x2 + 5x2 = 26 defense
reg_terumet_armor{suffix='tcop', name='Terucopper', mat=terumet.id('ingot_tcop'), def=5, defhi=8, heal=0, uses=500}
-- Terutin: 5x2 + 4x2 = 18 defense | 5x4 = 20% heal
reg_terumet_armor{suffix='ttin', name='Terutin', mat=terumet.id('ingot_ttin'), def=4, defhi=5, heal=5, speed=0.1, xinfo='[Speed++]', uses=300}
-- Terusteel: 18x2 + 12x2 = 60 defense
reg_terumet_armor{suffix='tste', name='Terusteel', mat=terumet.id('ingot_tste'), def=12, defhi=18, heal=0, speed=-0.05, xinfo='[Speed-]', uses=1000}
-- Teruchalcum: 14x2 + 9x2 = 46 defense | 6x4 = 24% heal
reg_terumet_armor{suffix='tcha', name='Teruchalcum', mat=terumet.id('ingot_tcha'), def=9, defhi=14, heal=6, uses=2000}
-- Terugold: 4x2 + 3x2 = 14 defense | 16x4 = 18x4 = 72% heal
reg_terumet_armor{suffix='tgol', name='Terugold', mat=terumet.id('ingot_tgol'), def=3, defhi=4, heal=18, jump=-0.05, gravity=-0.12, xinfo='[Float++]', uses=200}
-- Coreglass: 16x2 + 10x2 = 52 defense | 8x4 = 32% heal
reg_terumet_armor{suffix='cgls', name='Coreglass', mat=terumet.id('ingot_cgls'), def=10, defhi=16, heal=8, speed=0.05, jump=0.08, xinfo='[Speed+] [2-Block Jump]', uses=500}