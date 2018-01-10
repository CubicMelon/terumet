terumet.options = {}

--
-- GENERAL MACHINE SETTINGS
--
local machine = {} -- do not remove
-- Heat sources that can be used directly in any machine
machine.basic_heat_sources = {
    ['bucket:bucket_lava']={ hus=2000, return_item='bucket:bucket_empty' },
    ['terumet:block_thermese_hot']={ hus=400, return_item='terumet:block_thermese'}
}
-- Whether machines emit particles or not while working
machine.PARTICLES = true

machine.HEAT_TRANSFER_MODE_NAMES = {
    [0]='Disabled',
    [1]='Accept',
    [2]='Only Provide',
}

terumet.options.machine = machine -- do not remove


local heater = {
    furnace={},
    solar={}
} -- do not remove
--
-- FURNACE HEATER SETTINGS
--
heater.furnace.MAX_HEAT = 500
heater.furnace.HEAT_TRANSFER_RATE = 10
--
-- SOLAR HEATER SETTINGS
--
heater.solar.MAX_HEAT = 4000
heater.solar.SOLAR_GAIN_RATES = { 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 4, 5, 10, 20 }
heater.solar.HEAT_TRANSFER_RATE = 100

terumet.options.heater = heater -- do not remove

--
-- ALLOY SMELTER SETTINGS
--
local smelter = {} -- do not remove

-- Maximum HUs smelter can contain
smelter.MAX_HEAT = 2000

-- Maximum size (in item count) of an alloy smelter's flux tank
-- (note if greater than 99, some flux could be lost when breaking a smelter -- only up to 99 flux will be dropped)
smelter.FLUX_MAXIMUM = 50
-- Heat expended per tick melting flux
smelter.COST_FLUX_MELTING_HU = 2
-- Heat expended per tick alloying
smelter.COST_FLUX_ALLOYING_HU = 1
-- Default items usable as flux
smelter.flux_items = { 
    ['terumet:lump_raw']={time=3.0},
    ['terumet:item_cryst_raw']={time=1.0}
}
-- Default alloy-making recipes
smelter.recipes = {
-- Terucopper
    {result='terumet:ingot_tcop', flux=1, time=3.0, input={'default:copper_lump'}},
    {result='terumet:block_tcop', flux=7, time=35.0, input={'default:copperblock'}},
    {result='terumet:ingot_tcop', flux=1, time=1.0, input={'terumet:item_cryst_copper'}},
-- Terusteel
    {result='terumet:ingot_tste', flux=2, time=4.0, input={'default:iron_lump'}},
    {result='terumet:block_tste', flux=15, time=45.0, input={'default:steelblock'}},
    {result='terumet:ingot_tste', flux=2, time=1.5, input={'terumet:item_cryst_iron'}},
-- Terugold
    {result='terumet:ingot_tgol', flux=3, time=4.0, input={'default:gold_lump'}},
    {result='terumet:block_tgol', flux=24, time=60.0, input={'default:goldblock'}},
    {result='terumet:ingot_tgol', flux=3, time=2.0, input={'terumet:item_cryst_gold'}},
-- Teruchalchum
    {result='terumet:ingot_tcha', flux=3, time=4.5, input={'default:bronze_ingot', 'default:tin_lump 2'}},
    {result='terumet:block_tcha', flux=26, time=80.0, input={'default:bronzeblock', 'default:tinblock 2'}},
    {result='terumet:ingot_tcha', flux=3, time=2.5, input={'default:bronze_ingot', 'terumet:item_cryst_tin 2'}},
-- Coreglass
    {result='terumet:ingot_cgls', flux=5, time=10.0, input={'default:diamond', 'default:obsidian_shard'}},
    {result='terumet:block_cgls', flux=30, time=180.0, input={'default:diamondblock', 'default:obsidian'}},
    {result='terumet:ingot_cgls', flux=5, time=3.5, input={'terumet:item_cryst_dia', 'terumet:item_cryst_ob'}},
-- Teruceramic
    {result='terumet:item_ceramic', flux=2, time=2.0, input={'default:clay_lump'}},
-- Thermese
    {result='terumet:item_thermese', flux=4, time=10.0, input={'default:mese_crystal'}},
}

terumet.options.smelter = smelter -- do not remove

--
-- HT FURNACE SETTINGS
--
local furnace = {} -- do not remove
-- Maximum HUs ht-furnace can contain
furnace.MAX_HEAT = 3000
-- Heat cost per tick of cooking
furnace.COST_COOKING_HU = 3
-- Multiplier applied to normal cooking time
furnace.TIME_MULT = 0.5
terumet.options.furnace = furnace -- do not remove

--
-- CRYSTAL VULCANIZER SETTINGS
--

local vulcan = {} -- do not remove
vulcan.recipes = {} -- do not remove - populated when crystals are registered
-- Maximum HUs vulcanizer can contain
vulcan.MAX_HEAT = 6000
-- Heat cost per tick of vulcanizing
vulcan.COST_VULCANIZE = 10
-- Time to process one item (in seconds)
vulcan.PROCESS_TIME = 10.0
terumet.options.vulcan = vulcan