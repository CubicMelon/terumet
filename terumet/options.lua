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
        SOLAR_GAIN_RATES = { 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 3, 4, 6, 12 },
        -- Maximum HUs Solar Heater can transfer per tick
        HEAT_TRANSFER_RATE = 100,
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
        {result='terumet:ingot_tste', flux=2, time=3.5, input={'default:iron_ingot'}},
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
    RAY_PARTICLES_PER_NODE = 4,
    -- show crosshair of ray target-seeking
    SEEKING_VISIBLE = false
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