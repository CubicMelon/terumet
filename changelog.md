## Terumetal mod changelog
Newer versions listed first

### Version 1.9
* "Solar Glass" is now "Heat-transference Glass" to reflect its expanded use.
* Some overdue graphic cleanup and changes have been made.
* The Teruchalcum is always greener on the other version.
    * More seriously, the look of Teruchalcum was changed slightly to be shinier and greenier.
* The ore-cutting saw is now a proper size when wielded.
* Overdue but finally: You can use pure terumetal ingots in the Alloy Smelter as flux. Smelting terumetal lumps no longer makes them useless for alloying! This should have been the case since multiple flux items were implemented, but...

### Version 1.8
* **POTENTIALLY BREAKING CHANGE**: Machines in the world before 1.8 will not appear to have any input slots because of a inventory list-name change due to new API update. Re-placing the machine should fix this but will not drop items in 'old' input slots. I suggest removing any input items left in the slots before updating to 1.8 to prevent losing any items.
* API Expansion: now submods can easily create new custom heat machines that can process items. see 'custom_sample' included with the development files for a simple example of how to use this new API. While the example works, there may still be bugs in custom machines. Please report any if you run into them!

### Version 1.7
* New alloy added that uses the remaining minetest metals: Teruchalcum, made from standard minetest Bronze, additional Tin, and Terumetal flux in the Alloy Smelter! Mostly an excellent mid-tier tool metal at this point that creates fast and extremely long-lasting tools for usual exploring and mining.
* All machines now 'save' their heat when broken! If a machine has been placed in the world before, it will state 'Heat: X%' in its tooltip and will retain that amount when re-placed. **REMEMBER** though: if a machine is in the middle of processing something and you break it, what was being processed will be lost! Any items in the input and output slots will be dropped, but anything mid-process will not!
* The Solar Heater is now much more difficult to exploit with artificial light. ONLY sunlight will do now.
* Ore-cutting Saw (name was changed since WIP stage) is now implemented and effective. With this tool you can instantly excavate any ore node to collect them whole. Mostly useful for Diamond Ore and Mese Ore, which can be Vulcanized into Crystallized Diamonds/Mese (thus doubling the usual mining yield)
    * Ore-cutting Saw as a method to get whole ore nodes are also shown in unified_inventory
* Damage of alloy Swords changed to more appropriate values, and can now be easily changed in options.lua
* Fixed duplication exploit of Terumetal via breaking Alloy Smelters and recrystallizing the dropped lumps: alloy smelter now drops crystallized terumetal instead

### Version 1.6
* Furnace Heater added: use standard furnace fuel for generating heat
* Solar Heater added: use (sun)light for generating heat
* Heat transfer between machines implemented, currently only adjacently. Either heater will send heat to any adjacent heat machines that need it, split evenly.
* A lot of internal work on moving code out of specific machines and into general use
* Furnace heater looks like old alloy smelter, Alloy Smelter has new appearance
* Machines now react instantly to items being inserted/removed rather than with a delay

### Version 1.5
* Unified_inventory support expanded: Flux items for smelter and crystal vulcanizer recipes added
* API for other mods to easily add new recipes to the alloy smelter and define new crystals for vulcanizer to create added under interop/terumet_api.lua
* Crystallized forms of metals added. Similar to the classic concept of 'grinding' ore into dusts to multiply yield, a Crystal Vulcanizer machine now exists that takes ore lumps or other raw materials and purifies and crystallizes them through extreme temperature processing. Currently Vulcanizer provides 2 crystallized metals for 1 input, but this is planned to be based on machine setup in future.
* Internal structure of alloy smelter recipes rewritten -- old system turned out to be flawed because multiple ways to create the same item were impossible. This has been fixed but I'm sorry if it broke anything RSL_Redstonier :(
* A new heating method other than buckets of lava is now available: heated thermese blocks. Place a block of thermese adjacent to lava in the world and it will heat up enough to use as a small heat boost in a machine. Renewable because it doesn't consume the lava! (much more to come when it comes to providing heat to machines)

### Version 1.4
* Alloy items ID change (sorry if anything breaks!)
* Addition of machine frames, node design contributed by RSL-Redstonier
* Alloy smelter has new recipe based on new machine frames
* Addition of high-temperature furnace! (still using smeltery gui mostly though)
* Change to lightning effects for machinery, now lights when in use rather than when heated

### Version 1.3
* Reorganized file structure (minimal gameplay effects)
* Added textures for future items
* Implemented support for mod unified_inventory - now alloy smelter recipes are listed along with the required flux and time it takes. This was much easier than I thought it would be!

### Version 1.2
* Made particle effects functional - smelter smokes when working. Uses a texture from default mod presently but this should be changed...eventually
* Added new items and alloying recipes for creating them: Teruceramic and Thermese, from clay and mese respectively. Currently both are only usable to create blocks and back, but both will be important materials for future machines and tools.

### Version 1.1
* What the Smelter is currently processing now displays on the GUI in the center, rather than just in text.
* To make it feel a bit less pointless, when the lava in the Smelter is fully used up you now get regular stone (aka smooth stone) back instead of cobblestone. Saves you a little cooking cobblestone I guess?
* The smelter now lights up and changes textures when there is heat.
* The groundwork for particle effects is there but still not apparently functional. TODO.
* It's no longer possible to theoretically get a Smelter 'stuck' without heat and not showing the fuel slot because the heat-using system was completely rewritten.
* Because of the new heat system, a bucket of lava will not be consumed until the Smelter needs it to process something.
* A lot of under-the-hood stuff to make future new machines much easier to make
