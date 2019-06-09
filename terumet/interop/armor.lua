-- add armor when 3darmor mod is also active
local opts = terumet.options.armor

local function gen_armor_groups(type, data)
    local grps = {
        armor_use=data.uses,
        armor_heal=(data.heal or 0),
        armor_water=(data.breathing or 0),
        armor_fire=data.fire,
        physics_speed=(data.speed or 0),
        physics_gravity=(data.gravity or 0),
        physics_jump=(data.jump or 0),
    }
    if data.fire and not armor.config.fire_protect then
        data.xinfo = '(NO FUNCTION - turn on 3d_armor fire protection)'
        minetest.log('warning', 'terumet: Armor with fire protection WILL NOT FUNCTION - 3d armor config option for fire protection is disabled!!')
    end
    grps[type]=1
    return grps
end

local function reg_recipe_boots(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, '', mat},
        {mat, '', mat}
    }}
end

local function reg_recipe_legs(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, mat, mat},
        {mat, '', mat},
        {mat, '', mat}
    }}
end

local function reg_recipe_chest(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, '', mat},
        {mat, mat, mat},
        {mat, mat, mat}
    }}
end

local function reg_recipe_helm(id, mat)
    minetest.register_craft{output=id, recipe={
        {mat, mat, mat},
        {mat, '', mat},
    }}
end

local function format_desc(fullname, xinfo)
    if xinfo then
        return string.format("%s\n%s", fullname, minetest.colorize(opts.EFFECTS_TEXTCOLOR, xinfo))
    else
        return fullname
    end
end

local function reg_terumet_armor(data)
    if not data or not data.suffix or not data.mat then error('Missing data on registering Terumetal armor') end
    data.uses = data.uses or 500
    data.mrv = data.mrv or 10 -- material repair value of 1x mat
    data.dgroups = data.dgroups or {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
    data.name = data.name or data.suffix

    local low_def = data.total_def / 6
    local hi_def = data.total_def / 3

    data.heal = data.total_heal / 4
    data.speed = data.weight / -100
    data.gravity = data.weight / 200

    local boots_id = terumet.id('armboots_'..data.suffix)
    armor:register_armor(boots_id, {
        description= format_desc(data.name..' Boots', data.xinfo),
        inventory_image = terumet.tex('invboots_'..data.suffix),
        texture = terumet.tex('armboots_'..data.suffix),
        preview = terumet.tex('prvboots_'..data.suffix),
        groups = gen_armor_groups('armor_feet', data),
        armor_groups = {fleshy=low_def},
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
        armor_groups = {fleshy=low_def},
        damage_groups = data.dgroups,
    })
    reg_recipe_helm(helm_id, data.mat)
    terumet.register_repairable_item(helm_id, data.mrv*5)

    local chest_id = terumet.id('armchest_'..data.suffix)
    armor:register_armor(chest_id, {
        description= format_desc(data.name..' Chestpiece', data.xinfo),
        inventory_image = terumet.tex('invchest_'..data.suffix),
        texture = terumet.tex('armchest_'..data.suffix),
        preview = terumet.tex('prvchest_'..data.suffix),
        groups = gen_armor_groups('armor_torso', data),
        armor_groups = {fleshy=hi_def},
        damage_groups = data.dgroups,
    })
    reg_recipe_chest(chest_id, data.mat)
    terumet.register_repairable_item(chest_id, data.mrv*8)

    local legs_id = terumet.id('armlegs_'..data.suffix)
    armor:register_armor(legs_id, {
        description= format_desc(data.name..' Leggings', data.xinfo),
        inventory_image = terumet.tex('invlegs_'..data.suffix),
        texture = terumet.tex('armlegs_'..data.suffix),
        preview = terumet.tex('prvlegs_'..data.suffix),
        groups = gen_armor_groups('armor_legs', data),
        armor_groups = {fleshy=hi_def},
        damage_groups = data.dgroups,
    })
    reg_recipe_legs(legs_id, data.mat)
    terumet.register_repairable_item(legs_id, data.mrv*7)
end

-- enable terumet bracers
if opts.BRACERS then
    -- I would love to colorize every texture rather than require a seperate armor & preview texture for every bracer
    -- but it seems that 3d_armor textures do NOT support texture generation with ^ layering and ^[multiply :(
    local function bracer_inv_texture(color)
        if color then
            return string.format('(%s^(%s^[multiply:%s))', terumet.tex('invbrcr_base'), terumet.tex('invbrcr_color'), color)
        else
            return terumet.tex('invbrcr_base')
        end
    end

    local function core_texture(color)
        return string.format('%s^[multiply:%s', terumet.tex('item_brcrcrys'), color)
    end

    table.insert(armor.elements, "terumet_brcr")

    local brcrcrys_id = terumet.id('item_brcrcrys')
    minetest.register_craftitem( brcrcrys_id, {
        description = 'Blank Bracer Core',
        inventory_image = terumet.tex(brcrcrys_id)
    })
    -- add vulcan crystallizer recipe for blank bracer core
    terumet.options.vulcan.recipes[opts.BRACER_CRYSTAL_ITEM] = {brcrcrys_id, 2}

    local function reg_terumet_band(data)
        if not data or not data.suffix then error('Missing data on registering Terumetal bracer') end
        data.uses = data.uses or 500
        data.def = data.def or 0
        data.dgroups = data.dgroups or {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
        data.name = data.name or data.suffix
        -- generate groups now to update xinfo if necessary before registering it
        local groups = gen_armor_groups('armor_terumet_brcr', data)

        local band_id = terumet.id('brcr_'..data.suffix)
        armor:register_armor(band_id, {
            description= format_desc(data.name..' Bracers', data.xinfo),
            inventory_image = bracer_inv_texture(data.color),
            texture = terumet.tex('armbrcr_'..data.suffix),
            preview = terumet.tex('prvbrcr_'..data.suffix),
            groups = groups,
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
                description = data.name..' Bracer Core',
                inventory_image = core_texture(data.color)
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
    total_def=45, total_heal=4, weight=0, uses=1400}
reg_terumet_armor{suffix='ttin', name='Terutin', mat=terumet.id('ingot_ttin'), mrv=21,
    total_def=38, total_heal=24, weight=-2, xinfo='Weight -2', uses=1000}
reg_terumet_armor{suffix='tste', name='Terusteel', mat=terumet.id('ingot_tste'), mrv=40,
    total_def=56, total_heal=12, weight=1, xinfo='Weight +1', uses=2000}
reg_terumet_armor{suffix='tcha', name='Teruchalcum', mat=terumet.id('ingot_tcha'), mrv=60,
    total_def=64, total_heal=8, weight=2, xinfo='Weight +2', uses=1500}
reg_terumet_armor{suffix='tgol', name='Terugold', mat=terumet.id('ingot_tgol'), mrv=80,
    total_def=24, total_heal=65, weight=-1, xinfo='Weight -1', uses=600}
reg_terumet_armor{suffix='cgls', name='Coreglass', mat=terumet.id('ingot_cgls'), mrv=120,
    total_def=78, total_heal=36, weight=3, xinfo='Weight +3', uses=3000}

reg_terumet_armor{suffix='rsuit', name='Vulcansuit', mat=terumet.id('item_rsuitmat'), mrv=180,
    total_def=78, total_heal=50, weight=-5, xinfo='Weight -5', uses=3000}