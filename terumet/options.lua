terumet.options = {}

terumet.options.tools = {
    --
    -- TOOL SETTINGS
    --
    sword_damage = {
        -- damage inflicted by each type of sword
        TERUMETAL = 8,
        COPPER_ALLOY = 7,
        IRON_ALLOY = 8,
        GOLD_ALLOY = 9,
        BRONZE_ALLOY = 9,
        COREGLASS = 10
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

terumet.options.smelter = {
    --
    -- TERUMETAL ALLOY SMELTER SETTINGS
    --
    -- Maximum HUs smelter can contain
    MAX_HEAT = 2000,
    -- Maximum size (in item count) of an alloy smelter's flux tank
    -- (note if greater than 99, some flux could be lost when breaking a smelter -- only up to 99 flux will be dropped)
    FLUX_MAXIMUM = 50,
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
        {result='default:bronze_ingot 9', flux=0, time=8.0, input={'default:copper_lump 8', 'default:tin_lump'}},
        {result='default:bronze_ingot 9', flux=0, time=6.0, input={'default:copper_ingot 8', 'default:tin_ingot'}},
        {result='default:bronzeblock 9', flux=0, time=40.5, input={'default:copperblock 8', 'default:tinblock'}},
        {result='default:bronze_ingot 9', flux=0, time=2.0, input={'terumet:item_cryst_copper 8', 'terumet:item_cryst_tin'}},
    -- Terucopper
        {result='terumet:ingot_tcop', flux=1, time=3.0, input={'default:copper_lump'}},
        {result='terumet:ingot_tcop', flux=1, time=2.5, input={'default:copper_ingot'}},
        {result='terumet:block_tcop', flux=8, time=22.5, input={'default:copperblock'}},
        {result='terumet:ingot_tcop', flux=1, time=1.0, input={'terumet:item_cryst_copper'}},
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
    -- Teruchalchum
        {result='terumet:ingot_tcha 3', flux=9, time=6.0, input={'default:bronze_ingot', 'default:tin_lump 2'}},
        {result='terumet:ingot_tcha 3', flux=9, time=4.0, input={'default:bronze_ingot', 'default:tin_ingot 2'}},
        {result='terumet:block_tcha 3', flux=75, time=54.0, input={'default:bronzeblock', 'default:tinblock 2'}},
        {result='terumet:ingot_tcha 3', flux=9, time=3.0, input={'default:bronze_ingot', 'terumet:item_cryst_tin 2'}},
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
    COST_COOKING_HU = 3,
    -- Multiplier applied to normal cooking time
    TIME_MULT = 0.5,
}

terumet.options.vulcan = { 
    --
    -- CRYSTAL VULCANIZER SETTINGS
    --
    recipes = {}, -- populated when crystals are registered, don't change
    -- Maximum HUs vulcanizer can contain
    MAX_HEAT = 6000,
    -- Heat cost per tick of vulcanizing
    COST_VULCANIZE = 10,
    -- Time to process one item (in seconds)
    PROCESS_TIME = 10.0,
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
    -- Maximum efficiency rating (at this rating, progress is 100% of possible rate)
    MAX_EFFIC = 1000,
    -- Efficiency gained every second heated and seeded
    EFFIC_GAIN = 5,
    
    SEED_ITEM = 'default:mese_crystal',
    PRODUCE_ITEM = 'default:mese_crystal_fragment',
    -- Implement a 1/SEED_LOSS_CHANCE chance to lose one seed crystal with a successful shard production. 
    -- Set to false or nil to disable.
    SEED_LOSS_CHANCE = 30,
    -- sound to play at Garden node when a seed is lost (nil for none)
    SEED_LOSS_SOUND = 'default_break_glass'
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