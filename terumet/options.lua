terumet.options = {}

terumet.options.protection = {
    -- List of potential external mods that will handle machine protection in lieu of the default owner system
    -- If any of these mods are found on load, the default protection system will NOT be active
    -- and all machine protection will be based on mintest.is_protected implemented by external mods
    -- (1 has no specific meaning, only to provide a value)
    EXTERNAL_MODS = {
        ['areas']=1
    }
}

terumet.options.cosmetic = {
    -- Set to false/nil for Terumetal Glass to be streaky similar to default Minetest glass
    CLEAR_GLASS = true,
    -- Style of reinforced blocks:
    -- 1 = rebar on top/bottom only
    -- 2 = rebar on all faces
    -- false/nil = not visible (reinforced blocks look exact same as original block)
    REINFORCING_VISIBLE = 1,
    -- Set to false/nil for heatline blocks to not have visible ports
    BLOCK_HEATLINE_VISIBLE = true,
}

terumet.options.misc = {
    -- Groups to remove from converted blocks (heatline/reinforced blocks)
    -- ex: 'wood' prevents wood planks with heatlines/reinforcing from being used as wood in general recipes
    -- if any other groups cause problems when transferred over to a block, add it here
    -- (1 has no specific meaning, only to provide a value)
    BLOCK_REMOVE_GROUPS = {
        ['wood']=1,
        ['stone']=1,
        ['flammable']=1,
    }
}

terumet.options.tools = {
    --
    -- TOOL SETTINGS
    --
    sword_damage = {
        -- damage inflicted by each type of sword
        TERUMETAL = 6,
        COPPER_ALLOY = 8,
        IRON_ALLOY = 9,
        GOLD_ALLOY = 7,
        BRONZE_ALLOY = 10,
        COREGLASS = 12
    }
}

terumet.options.machine = {
    --
    -- GENERAL MACHINE SETTINGS
    --
    -- Heat sources that can be used in fuel slots of machines
    BASIC_HEAT_SOURCES = {
        ['bucket:bucket_lava']={ hus=2000, return_item='bucket:bucket_empty' },
        ['terumet:block_thermese_hot']={ hus=400, return_item='terumet:block_thermese'}
    },
    -- Whether machines emit smoke particles or not while working
    PARTICLES = true,
    -- Text descriptions of heat transfer modes of machines
    HEAT_TRANSFER_MODE_NAMES = {
        [0]='Disabled',
        [1]='Accept',
        [2]='Provide',
    },
    -- Sound played by overheated machines, (nil to disable)
    OVERHEAT_SOUND = 'terumet_venting'
}

terumet.options.heater = {
    furnace={
        --
        -- FURNACE HEATER SETTINGS
        --
        -- Maximum HUs Furnace Heater can store
        MAX_HEAT = 500,
        -- Maximum HUs Furnace Heater can transfer per tick
        HEAT_TRANSFER_RATE = 20,
        -- Base heat generation per second of burn time
        HEAT_GEN = 10
    },
    solar={
        --
        -- SOLAR HEATER SETTINGS
        --
        -- Maximum HUs Solar Heater can store
        MAX_HEAT = 4000,
        -- HUs Solar Heater generates per tick based on sunlight level
        SOLAR_GAIN_RATES = { 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 3, 4, 6, 12, 24 },
        -- Maximum HUs Solar Heater can transfer per tick
        HEAT_TRANSFER_RATE = 100,
    },
    entropy={
        --
        -- ENTROPIC HEATER SETTINGS
        --
        MAX_HEAT = 20000,
        HEAT_TRANSFER_RATE = 500,
        -- the maximum extent the heater "scans" from the main machine
        MAX_RANGE = {x=5, y=5, z=5},
        -- if a node time is not defined, use this time
        DEFAULT_DRAIN_TIME = 1.0,
        EFFECTS = {
            ['default:water_source']={change='default:ice', time=5.0, hups=100}, -- 500 HU total
            ['default:water_flowing']={change='default:ice', time=2.5, hups=120}, -- 300 HU total
            ['default:lava_source']={change='default:obsidian', time=2.0, hups=1000}, -- 2000 HU total
            ['default:lava_flowing']={change='default:obsidian', time=1.0, hups=500}, -- 500 HU total
            ['default:dirt_with_grass']={change='default:dirt', hups=100},
            ['default:sandstone']={change='default:sand', hups=300},
            ['default:silver_sandstone']={change='default:silver_sand', hups=300},
            ['default:stone']={change='default:cobble', time=3.0, hups=100}, -- 300 HU total
            ['default:cobble']={change='default:gravel', time=3.0, hups=80}, -- 240 HU total
            ['default:gravel']={change='default:silver_sand', time=3.0, hups=50}, -- 150 HU total
            ['default:coalblock']={change='default:stone_with_coal', time=60.0, hups=150}, -- 9000 HU total
            ['default:stone_with_coal']={change='default:stone', time=10.0, hups=150}, -- 1500 HU total
            ['default:mossycobble']={change='default:cobble', time=15.0, hups=50}, -- 750 HU total
            ['default:clay']={change='default:dirt', time=5.0, hups=50}, -- 250 HU total
            ['default:cactus']={change='air', time=10.0, hups=20}, -- 200 HU total
            ['default:papyrus']={change='air', time=20.0, hups=20}, -- 400 HU total
            ['group:flora']={change='default:dry_shrub', time=6.0, hups=15}, -- 90 hu total
            ['default:dry_shrub']={change='air', time=3.0, hups=15}, -- 45 HUs total
            ['fire:basic_flame']={change='air', time=0.5, hups=1000}, -- 500 HU total
            ['fire:permanent_flame']={change='air', time=0.5, hups=1000}, -- 500 HU total
            ['air']={time=1.0, hups=5}, -- 10 HU total
            ['group:tree']={change='air', time=12.0, hups=30}, -- 360 HU total
            ['group:sapling']={change='air', time=4.0, hups=40}, -- 160 HU total
            ['group:wood']={change='air', time=9.0, hups=10}, --  90 HU total
            ['group:leaves']={change='air', time=4.0, hups=20}, -- 80 HU total
        }
    }
}

terumet.options.crusher = {
    --
    -- CRUSHER SETTINGS
    --

    MAX_HEAT = 500,

    COST_HEATING = 20, -- per sec.
    TIME_HEATING = 4.0, -- in sec.
    TIME_COOLING = 6.0, -- in sec.

    recipes = {
        ['default:stone']='default:cobble',
        ['default:cobble']='default:gravel',
        ['default:gravel']='default:silver_sand',
        ['default:obsidian']='default:obsidian_shard 9',
        ['default:obsidian_shard']='terumet:item_dust_ob',
        ['default:sandstone']='default:sand',
        ['default:silver_sandstone']='default:silver_sand',
        ['default:coalblock']='default:coal_lump 9',
        ['default:apple']='terumet:item_dust_bio 2',
        ['default:papyrus']='terumet:item_dust_bio 3',
        ['group:flora']='terumet:item_dust_bio',
        ['group:leaves']='terumet:item_dust_bio',
        ['group:sapling']='terumet:item_dust_bio',
        ['group:tree']='terumet:item_dust_wood 4',
        ['group:wood']='terumet:item_dust_wood 1',
        ['bushes:BushLeaves1']='terumet:item_dust_bio',
        ['bushes:BushLeaves2']='terumet:item_dust_bio',
        ['dryplants:grass']='terumet:item_dust_bio',
        ['vines:vines']='terumet:item_dust_bio'
    }
}
terumet.do_lua_file('interop/farming') -- see interop/farming.lua, adds farming crops to crusher

terumet.options.thermobox = {
    --
    -- THERMOBOX SETTINGS
    --
    MAX_HEAT = 20000,
    HEAT_TRANSFER_RATE = 250
}

terumet.options.thermdist = {
    --
    -- THERMAL DISTRIBUTOR SETTINGS
    MAX_HEAT = 2000,
    HEAT_TRANSFER_RATE = 250
}

terumet.options.heatline = {
    --
    -- HEATLINE SETTINGS
    --
    -- Maximum HUs heatline input can contain
    MAX_HEAT = 5000,
    -- Maximum distance over a heatline input can send (in blocks of heatline)
    -- when a heatline extends beyond this, it will occasionally display smoke particles to warn
    MAX_DIST = 36,
    -- Every RECHECK_LINKS_TIMER seconds, recheck the heatline network on an input
    RECHECK_LINKS_TIMER = 4.0,
    -- Max heat transferred every tick (divided among all connected machines in order of distance)
    HEAT_TRANSFER_MAX = 250,
    -- whether /heatlines chat command is available to list all heatline network info
    DEBUG_CHAT_COMMAND = false,
}

terumet.options.heat_ray = {
    --
    -- HEAT RAY EMITTER SETTINGS
    --
    -- Maximum HUs emitter can contain
    MAX_HEAT = 2000,
    -- HUs sent in one ray
    SEND_AMOUNT = 1000,
    -- maximum number of nodes emitter will seek before giving up
    MAX_DISTANCE = 100,
    -- set to zero to disable particle display of ray
    RAY_PARTICLES_PER_NODE = 6
}

terumet.options.smelter = {
    --
    -- TERUMETAL ALLOY SMELTER SETTINGS
    --
    -- Maximum HUs smelter can contain
    MAX_HEAT = 2000,
    -- Amount of flux value (FV) one item is worth
    FLUX_VALUE = 2,
    -- Maximum stored FV of an alloy smelter's flux tank
    -- NOTE: if FLUX_MAXIMUM / FLUX_VALUE > 99, flux could be lost on breaking a smelter
    -- (only a maximum of 1 stack of Crystallized Terumetal will be dropped)
    -- also if stored flux < FLUX_VALUE, that amount will be lost (minimum 1 Crystallized Terumetal dropped)
    FLUX_MAXIMUM = 100,
    -- Heat expended per tick melting flux
    COST_FLUX_MELTING_HU = 2,
    -- Heat expended per tick alloying
    COST_FLUX_ALLOYING_HU = 1,
    -- Default items usable as flux
    FLUX_ITEMS = {
        ['terumet:lump_raw']={time=3.0},
        ['terumet:ingot_raw']={time=2.0},
        ['terumet:item_cryst_raw']={time=1.0},
    },
    -- Default alloy-making recipes
    recipes = {
    -- Standard Bronze
    -- Note these are first in the recipe list to override single terucopper/terutin if all elements for bronze are available
        {result='default:bronze_ingot 9', flux=0, time=8.0, input={'default:copper_lump 8', 'default:tin_lump'}},
        {result='default:bronze_ingot 9', flux=0, time=6.0, input={'default:copper_ingot 8', 'default:tin_ingot'}},
        {result='default:bronzeblock 9', flux=0, time=40.5, input={'default:copperblock 8', 'default:tinblock'}},
        {result='default:bronze_ingot 9', flux=0, time=2.0, input={'terumet:item_cryst_copper 8', 'terumet:item_cryst_tin'}},
    -- Terumetal Glass
        {result='terumet:block_tglass 4', flux=1, time=8.0, input={'default:glass 4', 'default:silver_sand'}},
    -- Terumetal Glow Glass
        {result='terumet:block_tglassglow 4', flux=1, time=8.0, input={'terumet:block_tglass 4', 'default:mese_crystal'}},
    -- Teruchalchum
        {result='terumet:ingot_tcha 3', flux=9, time=6.0, input={'default:bronze_ingot', 'default:tin_lump 2'}},
        {result='terumet:ingot_tcha 3', flux=9, time=4.0, input={'default:bronze_ingot', 'default:tin_ingot 2'}},
        {result='terumet:block_tcha 3', flux=75, time=54.0, input={'default:bronzeblock', 'default:tinblock 2'}},
        {result='terumet:ingot_tcha 3', flux=9, time=3.0, input={'default:bronze_ingot', 'terumet:item_cryst_tin 2'}},
    -- Terucopper
        {result='terumet:ingot_tcop', flux=1, time=3.0, input={'default:copper_lump'}},
        {result='terumet:ingot_tcop', flux=1, time=2.5, input={'default:copper_ingot'}},
        {result='terumet:block_tcop', flux=8, time=22.5, input={'default:copperblock'}},
        {result='terumet:ingot_tcop', flux=1, time=1.0, input={'terumet:item_cryst_copper'}},
    -- Terutin
        {result='terumet:ingot_ttin', flux=1, time=2.0, input={'default:tin_lump'}},
        {result='terumet:ingot_ttin', flux=1, time=1.5, input={'default:tin_ingot'}},
        {result='terumet:block_ttin', flux=8, time=15.0, input={'default:tinblock'}},
        {result='terumet:ingot_ttin', flux=1, time=0.5, input={'terumet:item_cryst_tin'}},
    -- Terusteel
        {result='terumet:ingot_tste', flux=2, time=4.5, input={'default:iron_lump'}},
        {result='terumet:ingot_tste', flux=2, time=3.5, input={'default:steel_ingot'}},
        {result='terumet:block_tste', flux=16, time=31.5, input={'default:steelblock'}},
        {result='terumet:ingot_tste', flux=2, time=2.0, input={'terumet:item_cryst_iron'}},
    -- Terugold
        {result='terumet:ingot_tgol', flux=3, time=5.0, input={'default:gold_lump'}},
        {result='terumet:ingot_tgol', flux=3, time=4.0, input={'default:gold_ingot'}},
        {result='terumet:block_tgol', flux=25, time=36.0, input={'default:goldblock'}},
        {result='terumet:ingot_tgol', flux=3, time=2.5, input={'terumet:item_cryst_gold'}},
    -- Coreglass
        {result='terumet:ingot_cgls', flux=5, time=10.0, input={'default:diamond', 'default:obsidian_shard'}},
        {result='terumet:block_cgls', flux=30, time=90.0, input={'default:diamondblock', 'default:obsidian'}},
        {result='terumet:ingot_cgls', flux=5, time=5.0, input={'terumet:item_cryst_dia', 'terumet:item_cryst_ob'}},
    -- Teruceramic
        {result='terumet:item_ceramic', flux=2, time=3.0, input={'default:clay_lump'}},
    -- Thermese
        {result='terumet:item_thermese', flux=4, time=8.0, input={'default:mese_crystal'}},
    },
}

terumet.options.furnace = {
    --
    -- HIGH-TEMP FURNACE SETTINGS
    --
    -- Maximum HUs ht-furnace can contain
    MAX_HEAT = 3000,
    -- Heat cost per tick of cooking
    COST_COOKING_HU = 5,
    -- Multiplier applied to normal cooking time
    TIME_MULT = 0.5,
}

terumet.options.vulcan = {
    --
    -- CRYSTAL VULCANIZER SETTINGS
    --
    -- populated through registration, see interop/terumet_api.lua
    recipes = {}, -- DO NOT CHANGE
    -- Maximum HUs vulcanizer can contain
    MAX_HEAT = 6000,
    -- Heat cost per tick of vulcanizing
    COST_VULCANIZE = 10,
    -- Time to process one item (in seconds)
    PROCESS_TIME = 6.0,
    -- when true, crystalizing obsidian always produces exactly one crystal.
    -- this prevents easy infinite obsidian loops.
    LIMIT_OBSIDIAN = true,
}

terumet.options.lavam = {
    --
    -- LAVA MELTER SETTINGS
    --
    -- Maximum HUs melter can contain
    MAX_HEAT = 3000,
    -- Nodes that can be melted to lava
    -- related number is total required heat to melt
    VALID_STONES = {
        ['default:stone']=1500,
        ['default:cobble']=2000,
        ['default:desert_stone']=1400,
        ['default:desert_cobble']=1800
    },
    -- total time for 1 item required in seconds (best if required heat/MELT_TIME is a whole number)
    MELT_TIME = 200
}

terumet.options.meseg = {
    --
    -- MESE GARDEN SETTINGS
    --
    -- Maximum HUs garden can contain
    MAX_HEAT = 5000,
    -- HUs required to begin growing
    START_HEAT = 1000,
    -- HUs required per second when growing
    GROW_HEAT = 35,
    -- Multiplier applied to efficiency every second not heated or seeded
    EFFIC_LOSS_RATE = 0.75,
    -- Maximum efficiency "points" (at this level, progress is 100% of possible rate)
    -- Efficiency points increase by number of seed crystals each second until max
    MAX_EFFIC = 2000,
    -- Progress "points" needed to grow a new shard
    -- points gained each second = number of seed crystals x efficiency
    PROGRESS_NEED = 300,
    -- item id of seed crystal
    SEED_ITEM = 'default:mese_crystal',
    -- item id of produced item
    PRODUCE_ITEM = 'default:mese_crystal_fragment',
    -- Chance to lose a seed crystal each growth is 1/(SEED_LOSS_CHANCE-seed crystal count)
    -- so SEED_LOSS_CHANCE = 101 means:
    --  1 seed crystal = 1/100 chance (very low)
    --  99 seed crystals = 1/2 chance (coin flip)
    -- You can set to false or nil to disable losing seeds, even if it's overpowered.
    SEED_LOSS_CHANCE = 101,
    -- sound to play at Garden node when a seed is lost (nil for none)
    SEED_LOSS_SOUND = 'terumet_break',
    -- true if particle effects occur when a seed is lost (default machine PARTICLES option false will also disable)
    SEED_LOSS_PARTICLES = true
}

terumet.options.repm = {
    --
    -- EQUIPMENT REFORMER SETTINGS
    --
    MAX_HEAT = 5000,

    -- HUs/tick to melt repair material and repair material units processed per tick
    MELTING_HEAT = 10,
    MELTING_RATE = 10,
    -- HUs/tick to repair one item and repair material units applied to repairing per tick
    REPAIR_HEAT = 5,
    REPAIR_RATE = 10,
    -- maximum units of repair material that can be stored
    RMAT_MAXIMUM = 1000,

    -- items that can be turned into "repair-material" and how much
    -- populated through registration, see interop/terumet_api.lua
    repair_mats = {}, -- DO NOT CHANGE

    -- all items that can be repaired and how much "repair-material" is required to remove a full wear bar
    -- (TODO) mods can add addtional ones through the API terumet.register_repairable_item -- see interop/terumet_api.lua
    repairable = {}, -- DO NOT CHANGE
}

terumet.options.ore_saw = {
    --
    -- ORE SAW SETTINGS
    --
    -- Nodes that can be gathered directly via saw (1 is meaningless and just to provide a value)
    VALID_ORES = {
        ['default:stone_with_diamond']=1,
        ['default:stone_with_mese']=1,
        ['default:stone_with_copper']=1,
        ['default:stone_with_tin']=1,
        ['default:stone_with_iron']=1,
        ['default:stone_with_gold']=1,
        ['default:stone_with_coal']=1,
    },
    -- Number of times ore saw can be used before breaking
    USES = 50,
}

terumet.options.armor = {
    -- delete or comment out entire BRACERS = {...} block to disable all bracers
    BRACERS = { -- delete single line or comment out (add -- to start) to disable that type of bracer
        -- water-breathing bracer
        aqua={name='Aqua', mat='default:papyrus', xinfo='Underwater breathing', def=5, uses=500, rep=100, breathing=1},
        -- high jump bracer
        jump={name='Jump', mat='default:mese_crystal', xinfo='Increase jump height', def=5, uses=500, rep=150, jump=0.32},
        -- movement speed bracer
        spd={name='Speed', mat='terumet:item_cryst_dia', xinfo='Increase move speed', def=5, uses=500, rep=400, speed=0.4},
        -- anti-gravity bracer
        agv={name='Antigravity', mat='default:flint', xinfo='Reduce gravity', def=5, uses=500, rep=150, gravity=-0.6, jump=-0.2},
        -- high heal bracer
        heal={name='Heal', mat='default:apple', xinfo='Heal +30', heal=30, uses=400, rep=200},
        -- high defense bracer
        def={name='Defense', mat='default:obsidian', xinfo='Defense +30', def=33, uses=1000, rep=300},
    },
    -- Item used to create bracer crystals
    BRACER_CRYSTAL_ITEM = 'default:steelblock',
    -- tooltip text color for armor/bracer extra effects
    EFFECTS_TEXTCOLOR = '#ffa2ba'
}
