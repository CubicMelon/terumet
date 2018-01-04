terumet.options = {}

--
-- ALLOY RECIPES
--
terumet.options.alloys = {}
local alloys = terumet.options.alloys
-- flux = number of flux in tank required
-- time = in seconds (normal maximum granularity 0.5s = 1 tick)

alloys.COPPER_ALLOY = {flux=1, time=3.0, 'default:copper_lump'}
alloys.COPPER_ALLOY_BLOCK = {flux=7, time=35.0, 'default:copperblock'}

alloys.IRON_ALLOY = {flux=2, time=4.0, 'default:iron_lump'}
alloys.IRON_ALLOY_BLOCK = {flux=15, time=45.0, 'default:ironblock'}

alloys.GOLD_ALLOY = {flux=3, time=5.0, 'default:gold_lump'}
alloys.GOLD_ALLOY_BLOCK = {flux=24, time=60.0, 'default:goldblock'}

alloys.COREGLASS = {flux=5, time=10.0, 'default:diamond', 'default:obsidian_shard'}
alloys.COREGLASS_BLOCK = {flux=30, time=180.0, 'default:diamondblock', 'default:obsidian'}

alloys.CERAMIC_PLATE = {flux=3, time=1.0, 'default:clay_lump'}

alloys.THERMESE_CRYSTAL = {flux=10, time=20.0, 'default:mese_crystal'}

--
-- GENERAL MACHINE SETTINGS
--
terumet.options.machine = {}
local machine = terumet.options.machine
-- Heat sources that can be used directly in any machine
-- NOTE: only unstackable items should be used!
machine.basic_heat_sources = {
    ['bucket:bucket_lava']={ hus=1000, return_item='bucket:bucket_empty' }
}
-- Whether machines emit particles or not while working
machine.PARTICLES = true

--
-- ALLOY SMELTER SETTINGS
--
terumet.options.smelter = {}
local smelter = terumet.options.smelter
-- Maximum HUs smelter can contain
smelter.MAX_HEAT = 2000
-- Item used as flux
smelter.FLUX_ITEM = terumet.id('lump_raw')
-- Time (in seconds) one piece of flux is melted
-- Heat cost will be equal to this time
smelter.FLUX_MELTING_TIME = 3.0
-- Maximum size (in item count) of an alloy smelter's flux tank
-- (note if greater than 99, some flux could be lost when breaking a smelter -- only up to 99 flux will be dropped)
smelter.FLUX_MAXIMUM = 50
-- Heat expended per tick melting flux
smelter.COST_FLUX_MELT_HU = 2
-- Heat expended per tick alloying
smelter.COST_FLUX_ALLOYING_HU = 1