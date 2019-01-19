-- add armor when 3darmor mod is also active
local opts = terumet.options.armor

function gen_armor_groups(type, data)
    local grps = {
        armor_use=data.uses, 
        armor_heal=(data.heal or 0),
        armor_water=(data.breathing or 0),
        physics_speed=(data.speed or 0), 
        physics_gravity=(data.gravity or 0),
        physics_jump=(data.jump or 0),
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

function format_desc(fullname, xinfo)
    if xinfo then
        return string.format("%s\n%s", fullname, minetest.colorize(opts.EFFECTS_TEXTCOLOR, xinfo))
    else
        return fullname
    end
end

function reg_terumet_armor(data)
    if not data or not data.suffix or not data.mat then error('Missing data on registering Terumetal armor') end
    data.uses = data.uses or 500
    data.def = (data.def or 1)
    data.defhi = (data.defhi or 2)
    data.mrv = data.mrv or 10 -- material repair value of 1x mat
    data.dgroups = data.dgroups or {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
    data.name = data.name or data.suffix

    local boots_id = terumet.id('armboots_'..data.suffix)
    armor:register_armor(boots_id, {
        description= format_desc(data.name..' Boots', data.xinfo),
        inventory_image = terumet.tex('invboots_'..data.suffix),
        texture = terumet.tex('armboots_'..data.suffix),
        preview = terumet.tex('prvboots_'..data.suffix),
        groups = gen_armor_groups('armor_feet', data),
        armor_groups = {fleshy=data.def},
        damage_groups = data.dgroups,
    })
    reg_recipe_boots(boots_id, data.mat)
    terumet.register_repairable_item(boots_id, data.mrv*4)

    local helm_id = terumet.id('armhelm_'..data.suffix)
    armor:register_armor(helm_id, {
        description= format_desc(data.name..' Helmet', data.xinfo),
        inventory_image = terumet.tex('invhelm_'..data.suffix),
        texture = terumet.tex('armhelm_'..data.suffix),
        preview = terumet.tex('prvhelm_'..data.suffix),
        groups = gen_armor_groups('armor_head', data),
        armor_groups = {fleshy=data.def},
        damage_groups = data.dgroups,
    })
    reg_recipe_helm(helm_id, data.mat)
    terumet.register_repairable_item(helm_id, data.mrv*5)

    local chest_id = terumet.id('armchest_'..data.suffix)
    armor:register_armor(chest_id, {
        description= format_desc(data.name..' Chestplate', data.xinfo),
        inventory_image = terumet.tex('invchest_'..data.suffix),
        texture = terumet.tex('armchest_'..data.suffix),
        preview = terumet.tex('prvchest_'..data.suffix),
        groups = gen_armor_groups('armor_torso', data),
        armor_groups = {fleshy=data.defhi},
        damage_groups = data.dgroups,
    })
    reg_recipe_chest(chest_id, data.mat)
    terumet.register_repairable_item(chest_id, data.mrv*8)

    local legs_id = terumet.id('armlegs_'..data.suffix)
    armor:register_armor(legs_id, {
        description= format_desc(data.name..' Greaves', data.xinfo),
        inventory_image = terumet.tex('invlegs_'..data.suffix),
        texture = terumet.tex('armlegs_'..data.suffix),
        preview = terumet.tex('prvlegs_'..data.suffix),
        groups = gen_armor_groups('armor_legs', data),
        armor_groups = {fleshy=data.defhi},
        damage_groups = data.dgroups,
    })
    reg_recipe_legs(legs_id, data.mat)
    terumet.register_repairable_item(legs_id, data.mrv*7)
end

-- enable terumet bracers
if opts.BRACERS then
    table.insert(armor.elements, "terumet_brcr")

    local brcrcrys_id = terumet.id('item_brcrcrys')
    minetest.register_craftitem( brcrcrys_id, {
        description = 'Bracer Crystal',
        inventory_image = terumet.tex(brcrcrys_id)
    })
    -- add vulcan crystallizer recipe for bracer crystal
    terumet.options.vulcan.recipes[opts.BRACER_CRYSTAL_ITEM] = brcrcrys_id

    function reg_terumet_band(data)
        if not data or not data.suffix then error('Missing data on registering Terumetal bracer') end
        data.uses = data.uses or 500
        data.def = data.def or 0
        data.dgroups = data.dgroups or {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
        data.name = data.name or data.suffix

        local band_id = terumet.id('brcr_'..data.suffix)
        armor:register_armor(band_id, {
            description= format_desc(data.name..' Bracers', data.xinfo),
            inventory_image = terumet.tex('invbrcr_'..data.suffix),
            texture = terumet.tex('armbrcr_'..data.suffix),
            preview = terumet.tex('prvbrcr_'..data.suffix),
            groups = gen_armor_groups('armor_terumet_brcr', data),
            armor_groups = {fleshy=data.def},
            damage_groups = data.dgroups,
            on_equip = data.on_equip,
            on_unequip = data.on_unequip,
            on_damage = data.on_damage,
            on_punched = data.on_punched
        })

        if data.mat then
            local ecryst_id = terumet.id('item_brcrcrys_'..data.suffix)
            minetest.register_craftitem( ecryst_id, {
                description = data.name..' Bracer Crystal',
                inventory_image = terumet.tex(ecryst_id)
            })

            terumet.register_alloy_recipe{result=ecryst_id, flux=4, time=10.0, input={brcrcrys_id, data.mat}}

            terumet.register_alloy_recipe{result=band_id, flux=0, time=120.0, input={terumet.id('brcr_base'), ecryst_id .. ' 8'}}
        else
            local metal = terumet.id('item_cryst_raw')
            local coil = terumet.id('item_coil_tgol')
            minetest.register_craft{output=band_id, recipe={
                {coil, metal, coil},
                {metal, metal, metal},
                {coil, metal, coil}
            }}
        end

        terumet.register_repairable_item(band_id, data.rep or 80)
    end

    reg_terumet_band{suffix='base', name='Terumetal', xinfo='No effects', def=5, uses=500, rep=80}

    for band_id, band_data in pairs(opts.BRACERS) do
        band_data.suffix = band_id
        reg_terumet_band(band_data)
    end
end

reg_terumet_armor{suffix='tcop', name='Terucopper', mat=terumet.id('ingot_tcop'), mrv=20,
    def=4, defhi=6, heal=2, uses=1200}
reg_terumet_armor{suffix='ttin', name='Terutin', mat=terumet.id('ingot_ttin'), mrv=21,
    def=3, defhi=5, heal=3, speed=0.02, gravity=-0.01, xinfo='Weight -2', uses=500}
reg_terumet_armor{suffix='tste', name='Terusteel', mat=terumet.id('ingot_tste'), mrv=40, 
    def=9, defhi=14, heal=0, speed=-0.07, gravity=0.045, xinfo='Weight +7', uses=800}
reg_terumet_armor{suffix='tcha', name='Teruchalcum', mat=terumet.id('ingot_tcha'), mrv=60, 
    def=7, defhi=11, heal=4, speed=-0.04, gravity=0.02, xinfo='Weight +4', uses=1500}
reg_terumet_armor{suffix='tgol', name='Terugold', mat=terumet.id('ingot_tgol'), mrv=80, 
    def=2, defhi=3, heal=10, speed=-0.05, gravity=0.025, xinfo='Weight +5', uses=300}
reg_terumet_armor{suffix='cgls', name='Coreglass', mat=terumet.id('ingot_cgls'), mrv=120,
    def=6, defhi=14, heal=6, speed=-0.03, gravity=0.015, xinfo='Weight +3', uses=600}