terumet.options = {}

--
-- ALLOY RECIPES
--
terumet.options.alloys = {}
local alloys = terumet.options.alloys
-- flux = number of flux in tank required
-- time = in seconds (normal maximum granularity 0.5s = 1 tick)

alloys.COPPER = {flux=1, time=3.0, 'default:copper_lump'}
alloys.COPPER_BLOCK = {flux=7, time=35.0, 'default:copperblock'}

alloys.IRON = {flux=2, time=4.0, 'default:iron_lump'}
alloys.IRON_BLOCK = {flux=15, time=45.0, 'default:ironblock'}

alloys.GOLD = {flux=3, time=5.0, 'default:gold_lump'}
alloys.GOLD_BLOCK = {flux=24, time=60.0, 'default:goldblock'}

alloys.COREGLASS = {flux=5, time=10.0, 'default:diamond', 'default:obsidian_shard'}
alloys.COREGLASS_BLOCK = {flux=30, time=180.0, 'default:diamondblock', 'default:obsidian'}

--
-- ALLOY SMELTER SETTINGS
--
terumet.options.smelter = {}
local smelter = terumet.options.smelter
-- Item used as flux
smelter.FLUX_ITEM = terumet.id('lump_raw')
-- Time (in seconds) one piece of flux is melted
-- Heat cost will be equal to this time
smelter.FLUX_MELTING_TIME = 3.0
-- Maximum size (in item count) of an alloy smelter's flux tank
-- (note if greater than 99, some flux could be lost when breaking a smelter -- only up to 99 flux will be dropped)
smelter.FLUX_MAXIMUM = 99

-- Item used to start a smelter's heat cycle
smelter.FUEL_ITEM = 'bucket:bucket_lava'
-- Item returned after starting a heat cycle
smelter.FUEL_RETURN = 'bucket:bucket_empty'
-- Item provided after a full heat cycle is completed
smelter.FUEL_COMPLETE = 'default:cobble'
-- Heat Units provided by one cycle - melting flux is 2HU/tick and alloying is 1HU/tick
smelter.FULL_HEAT = 1000
