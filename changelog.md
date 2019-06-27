## Terumetal mod changelog
Newer versions listed first

## Version 3.2
* Terumet now depends on the basic_materials mod and integrates many of its materials and recipes with it.
    * The Expansion Crusher now makes basic_materials Oil Extract from leaves rather than Biomatter.
    * The Alloy Smelter can now create Brass (if moreores is also active)
    * Creating coke lumps from coal via the Vacuum Oven also results in Oil Extract as well.
* A fully optional Texture Pack is provided with the mod to retexture most of the basic_materials items to look more Terumetal-style
    * To use it:
        1. Copy/move the "terubasmat" folder inside basic_materials_texturepack to your Minetest textures folder
        2. Then, activate the texture pack under the "Content" tab in Minetest
    * Additionally, if you wish to use this texture pack for everyone on a server, you can copy the contents of the texture pack folder into the mod's "textures" folder as well.

## Version 3.1
* Renamed Concrete Mix/Blocks to Sandcrete Mix/Blocks to differentiate it from other mods' concrete.
* Machines will now only accept upgrades that apply to that machine.
* For balance, vacuum-packed food changed by default to only use 1 item and provide 1.5x effect.
    * These settings were added to options.lua where they can be changed freely.
* Various minor oversights fixed.

# Version 3.0
* **MAJOR VERSION CHANGE**: ALL MACHINE FUNCTIONALITY IS NOW SCALED PER SECOND RATHER THAN PER TICK. -- MOST IMPORTANTLY: **HEAT COSTS**
    * This is way overdue, especially since Minetest 5.0 seems to not call node ticks as uniformly as it used to.
    * This change in turn greatly encouraged this modification due to scaling: ALL old Heat Unit values have been **universally multiplied by 10**.
    * While it may cause some issues with upgrading (I apologize!) this means no longer will things be more expensive than expected because of long server ticks.
    * **IMPORTANT**: A huge portion of options.lua has changed to reflect this; if you have custom options I suggest making note of your changes, placing the new default options.lua in place, then re-adding your changes. Remember any old HU modifications you did should be now be multiplied by 10!
* Because of the above update, a new (and similarly overdue) item was added: **Heat Batteries**
    * Most usefully, the basic Copper battery can be used as a starting point for alloying -- you no longer HAVE to seek out elusive natural lava to start using this mod.
    * Batteries can be cooked via any normal means (vanilla Furnace, etc.) and will provide a small amount of HU to a heat machine when put in its Fuel slot.
    * For technical reasons, The High-Temp furnace's standard speed bonus does not apply when heating batteries. Sorry!
        * (It's because you could easily double Heat this way; its heat costs are purely based on how long it takes to heat an item)
    * Because of this addition, the old heating feature of Thermese blocks is removed as it has been superseded by the more useful function of batteries.
    * A special **Void "Battery"** is also available which acts as a battery but destroys any heat in a machine it is placed in. This is useful for EEE Heaters being used for its side effects rather than for gathering HU.
* Machines that had a "Fuel" slot now have a "Heat In" slot where lava buckets and full batteries can be inserted to transfer into the machine.
    * Additionally, generating/storage machines now have a "Heat Out" slot where empty heat batteries can be inserted and filled from its storage.
* Moved cosmetic blocks **Concrete Mix & Concrete** from my other mod into Terumetal.
    * Make concrete mix with sand & gravel, when Concrete Mix in world comes in contact with water it hardens to Concrete.
    * White concrete mix can be dyed into any of the 14 other standard dye colors.
    * (Yes, just like another crafty game)
    * Concrete can be made into doors, slabs, walls, stairs, etc.
* Upgraded tools can be made via the Alloy Smelter
    * Reach distance upgrades via Crystallized Mese
    * Speed upgrades via Crystallized Diamond
    * Durability upgrades via Synthetic Rubber
* Added Fireproof Bracer
    * Functions only if 3d_armor's fire protection option is turned on (wherein it overrides fire/lava functions itself)
* Added combined External Input/Output Upgrade
* Input/Output upgrades now allow changing which side of machine is used
* Added **Vacuum Oven** - Tier 3 processing machine that can turn Coal into **Coke & Tarballs**
    * Coke is a more long-burning fuel than plain Coal
    * Tarballs can be used where plant glue is, or further combined with Biomatter and vulcanized into **Synthetic Rubber Bars**
    * Tarballs can also be used to make **Asphalt** - a cosmetic block.
    * Also upgrades food items - vacuum two food items to create a condensed and packaged version that restores 3 times as much health/stamina.
        * Food items are items that are of the group "food_*" and have an on_use (presumably minetest.item_eat)
        * To ensure all food items are seen, any mods that add foods must be added as a dependent mod to Terumet
        * Specific white/blacklists for food items is in options.lua
* Added **Vulcansuit Armor** set, made from Vulcansuit Plates
    * **Vulcansuit Plates** are made by alloying Synthetic Rubber Bars with Teruchalcum
    * The Vulcansuit is excellent full-body protection and the best overall armor available from the mod.
* Redesigned machine interfaces with some Minetest 5.0 features. Each tier has its own appearance.
* The Furnace Heater no longer halves the burn time of the fuel it burns.
    * Necessary to keep balance of Furnace Heater -> High-Temp Furnace -> Battery
* The Solar Heater has had its generation rates reduced significantly, especially with this new x10 change.
* Now depends on more minetest default game mods (doors, stairs, walls) -- shouldn't be a problem in 5.0
* All armor and bracer effects rebalanced
    * Big thanks to obl3pplifp (https://github.com/obl3pplifp) for all of their work and assitance!
* Added mod-related items to dungeon loot

## Version 2.4
* Added support to run under (currently) stable Minetest 0.4.17 -- those asking for it rejoice!
* Added support for other mods plants/crops being used in the Expansion Crusher
    * bushes
    * farming (farming redo ver.)
    * Papyrus
* Reduced node level of Terumetal Glass - now level 2
* Added a multiplier to the value of Terumetal Flux in the Alloy Smelter -- x2 by default. Having to constantly farm Raw Terumetal proved to be quite tedious in testing, so now each item is worth 2 units of flux by default. Also doubled the max size of the flux tank to accomodate.
    * When a smelter that contains flux is broken it now drops Flux Tank / Multiplier Crystallized Terumetal, to prevent duplication. It rounds down, so if less than the multiplier is in the tank you will lose that flux, but it is a very minor loss in comparison.
* Revamped how crystal vulcanizer recipes are defined. This change also allowed all ore nodes to now be crystallized to increase yield significantly. (Using ore saw to gather 1 iron ore node can now be vulcanized into 3 crystallized iron, 4 with upgrade)
    * External mods and dependent mods can determine the item IDs for default crystallized materials through `terumet.crystal_ids[X] where X can be 'iron', 'gold', 'diamond', etc...
* Machine processing formspecs now display a stack count when processing multiple items at once
* Added metal doors for all 6 alloys in 4 styles each. They are protected like iron doors and have a node level akin to their metal block levels.
* Added armors for all 6 alloys when [3d_armor](https://github.com/stujones11/minetest-3d_armor) mod is also active. Descriptions for each set follow. Higher "Weight" reduces movement speed and jump height.

|Armor Alloy  |Defense           |Heal      |Weight |Durability|
|-------------|------------------|----------|-------|----------|
|Terucopper   |  4x2 +  6x2=  20 |  2x4=  8 |    0  |     1200 |
|Terutin      |  3x2 +  5x2=  16 |  3x4= 12 | -2/ea |      500 |
|Terusteel    |  9x2 + 14x2=  46 |    0     |  7/ea |      800 |
|Teruchalcum  |  7x2 + 11x2=  36 |  4x4= 16 |  4/ea |     1500 |
|Terugold     |  2x2 +  3x2=  10 | 10x4= 40 |  5/ea |      300 |
|Coreglass    |  6x2 + 14x2=  40 |  6x4= 24 |  3/ea |      600 | 

* Added bracers when 3d_armor is active. Each act as a new armor slot ("terumet_brcr") and provide one powerful special effect.

## Version 2.3
* Added **Terumetal Glass** and **Terumetal Glow Glass**, made via the Alloy Smelter. Both are very hard, durable glasses that are not easily broken (even by explosion).
* Added **Teruchalcum Rebar** and various **Reinforced Blocks** -- each level of reinforcing increases the hardness of the block and the level of the tool required to break it. Each increased level of reinforcement also reduces the chance of the block being broken by explosion (Single: 40%, Double: 20%, Triple: 3%)
* Cosmetic options for glass and reinforced blocks are available in options.lua
* It should *finally* be much more difficult to insert more than one upgrade item into a machine's upgrade slot (multiple upgrades in a slot never did anything anyway)
* Machine access control has been simplified and Terumetal now supports nearly any mod that implements minetest.is_protected:
    * There's a list of external protection mods in the options.lua file now under options.protection
    * If any of these mods are active on loading, then Terumetal will NOT implement any special protection and rely on minetest.is_protected to handle access control.
    * If none of the listed mods are active, then Terumetal adds its old protection based on owner alone via minetest.is_protected
    * Right now the only mod that is listed by default is [areas](https://github.com/ShadowNinja/areas) by ShadowNinja, as requested and suggested by [Sires](https://forum.minetest.net/viewtopic.php?p=329194#p329194) on the Minetest forum. However, adding support for other mods is simple as adding its name to the options.protection.EXTERNAL_MODS section.
* Additionally, the default Terumetal machine protection will prevent non-owners from digging machines.
* Terumetal shovels and axes adjusted to dig faster

## Version 2.2
* Added support for [Techpack's tubelib](https://forum.minetest.net/viewtopic.php?f=11&t=19784). With a **Tube Support Upgrade** every machine with input/output can interact as expected with Tubelib's tubes. (Just combine a tube with a blank upgrade to get one)
* Rebalanced Furnace Heater generation and fixed a place it was rounding where it shouldn't have been. There is also now an option to alter base generation.
* Adjusted how Speed Upgrades work and also added Speed upgrade support to the Equipment Reformer. The way they work is completely uniform across all machines now. The time remaining for processing will always be "normal" time, but with an upgrade it will decrease at the increased rate. This new system works better for internal reasons, plus now inserting/removing Speed upgrades mid-process will have an effect now! (Before speed upgrades were only taken into account if in a machine at the start of a process)
* Several recipes have changed to use intermediate components such as a **Crystal Growth Chamber** or **Obsidian Grit**. The methods for obtaining them (see the Expansion Crusher) are also newly available.
* **Terutin** is now possible to alloy (with Tin only, exactly like it sounds) and is a necessary component to create the Expansion Crusher's presses as it is an alloy with exception thermal expansion properties.
* Connectors between machines to transfer heat are *finally* here! 
    * A **Heatline Distributor** is needed to act as the input and distributor for the heat energy to be sent. It acts like any other machine and can be provided heat from adjacent External Heaters, Thermoboxes, etc.
    * Connect a series of **Heatlines** from the Distributor to any number of machines and they will be supplied heat through the lines!
    * Heatlines have a default limit of a maximum effective distance of **36 blocks**. Beyond that point, nothing will be sent. Occasionally a puff of steam will be emitted from the heatline to indicate it is at its limit.
    * Heat is sent in order from nearest to farthest connected machine each tick. Far machines may be passed over if the distributor is low on heat.
    * These limitations can be changed in options.lua but they are in place for server friendliness.
    * For cosmetic purposes, you can also make **Heatline Blocks** from many default blocks like stone, bricks, cobblestone, and wood which act as heatlines but look like the original block (with a small visible heatline port).
* Added **Expansion Crusher**, a Tier 1 machine that crushes stuff exactly like it sounds. Beyond the usual utility of turning cobblestone to gravel or sand, it also:
    * Squeeze and dry many types of vegetation (and wheat) into useful **Biomatter** which can be burned for fuel almost as effectively as coal. Biomatter is also useful to create **Plant Glue**.
    * Crush **Wood Mulch** from wood and tree logs, which can be used to create paper and inexpensive **Pressed Wood**.
    * Crush **Obsidian Grit** out of obsidian shards, which has replaced a few places where Obsidian or Crystallized Obsidian was once necessary.

## Version 2.1
* **Breaking Change!!** Began moving the mod as a whole to the in-development Minetest 5.0.0. **It is no longer guaranteed to work in older versions like 0.4.16 or 0.4.17.x!**
* Changed the Ore-cutting Saw use sound to be way less annoying.
* Visibility of seeking particles of Heat Ray Emitter is now a per-machine option via a button on the interface, rather than an option of the mod overall. Time to put that control button section to good use!
* Internal refactoring of useful 3D-relation node functions into its own "module" util3d.lua to help (*very* slightly) cut down on the size of machine.lua
* The Solar Heater generates more heat (it is Tier 2 after all).
* Made the default speed of the Vulcan Crystallizer a bit faster after feedback and reconsideration. [Thanks, piecubed!](https://github.com/Terumoc/terumet/issues/12#issuecomment-410413992)
* Crystallized material has a new icon.
* Added **Lava Melter**, a simple but useful Tier 1 machine for creating lava in more convenient places. Provided a stone or cobblestone and a large amount of heat, the Lava Melter will melt that stone to create a lava source block in front of it (as shown by the round dispenser-looking side with orange output arrows)
* Added **Mese Garden**, a Tier 2 machine that grows new Mese Crystal Shards when seeded with Mese Crystals. The garden gains efficiency at growing new shards as long as it has heat to continue working and seed crystals, but rapidly declines when missing one of those needs. When a shard is created, there is a very small chance to lose a seed crystal.
* Added **Equipment Reformer**, a Tier 2 machine that can repair tools. The machine consumes ingots of terumetal alloys to store "repair material". When a valid tool is inserted that has damage, it will use that material to repair it. By default, Minetest bronze, steel, mese and diamond tools as well as all tools added by Terumetal are eligible for repair. See interop/terumet_api for how to register other mod tools as repairable. Why spend metal to repair when you can just make new tools? The unique feature of the Reformer is that any material can be used to repair any other material tool, just a ratio of more "cheaper" material required.

## Version 2.0
* **Breaking change** API for creating 'custom' heat machines has completely changed. Custom machines for versions prior to 2.0 will _not_ work in 2.0. See tmapisample/init.lua for a complete example of how the newer, much more flexible API works -- any type of machine is now possible to create. More info will be coming soon.
* The highest-tier heater has been added: the **Environmental Entropy Extraction Heater**! This powerful machine extracts latent entropy from the environment around it and creates Heat energy. To be more blunt, it will degrade and/or cool nodes in an area around it to create large amounts of heat for other machines.
    * For example: after being extracted, stone becomes cobblestone which will then become gravel then silver sand. Each step after a pass of the Extraction Heater will generate heat from the transformation. There are many possible transformations depending on the environment around the heater, and also Air nodes will provide a limitless supply of heat, though quite slowly.
    * By default, the machine operates in a 5x5x5 cube around itself. (see options.lua to change this)
    * This presently is the most expensive item to create in the mod, and for good reason as it can provide essentially limitless heat for machines.
* Major formspec design overhaul, both visually and under the hood. This was the bulk of the change in 2.0.
* Heat Generation Upgrades now have a function in general machines: 
    * When in any machine that has a fuel slot, this upgrade increases the heat gained from direct fuel by 30% (ex: lava bucket 2000 HU --> 2600 HU)

### Version 1.11
* All Terumetal Alloy Smelter recipies have been rebalanced and now ingots of base metals can be used (i.e. Gold Ingot can be inserted to alloy Terugold) -- ingot recipes are basically equivalent, just a bit faster to alloy.
* Since it is an alloy, basic Minetest Bronze can now be alloyed in the Alloy Smelter from 8 copper + 1 tin (just like the hand recipe). This recipe does not use any Terumetal flux.
    * To help avoid confusing or unintentional alloying of what you don't want now that there are two recipes that use copper, the Alloy Smelter now has a UI button that enables/disables zero-flux recipies. If you don't want to accidentally create bronze because there's no flux in the tank, deactivate zero-flux recipes.
* The new recipes made possible due to the fact the Smelter now can handle recipies with an output with stack sizes > 1.
    * For example, when alloying Teruchalcum you no longer get a bad deal out of it. Three ingots worth of stuff goes in and three ingots now come out.

### Version 1.10
* Upgrade system for machines implemented! Machines that support upgrades have slots for them on the right side of their GUI vertically. Only a single upgrade of a particular type has any effect, so adding mutiple of the same type or trying to force in a stack bigger than 1 accomplishes nothing. The following upgrades are implemented:
    * External Input Upgrade: Removes the input slots from the machine's GUI and instead pulls items from the node to the left of the machine (when viewed from the front). This includes chests and any other node that has a "main" inventory.
    * External Output Upgrade: Removes the output slots from the machine's GUI and instead places output items into the node to the right of the machine (when viewed from the front). This includes chests and any other node that has a "main" inventory.
    * Maximum Heat Upgrade: Increases the maximum heat the machine can store so it may run longer without needing reheating. If the upgrade is removed and heat is above the standard maximum, the machine will slowly vent excess heat until back to normal and will not act normally until that occurs.
    * Heat Transfer Upgrade: When placed in a machine that sends heat to others, greatly increases the amount of heat it can send at once. Additionally, when placed in a machine that receives heat from others, it increases the amount of heat it can receive from any other machine by a bit.
    * Heat Generation Upgrade: Roughly doubles the amount of heat Furnace Heaters and Solar Heaters can generate.
    * Speed Upgrade: A highly lucrative upgrade that generally halves the amount of time for any machine to do its process, though it will consume the same amount of heat. It also halves the time fuel in a Furnace Heater takes to burn, but additionally doubles the rate of heat generated to make it even.
    * Crystallization Upgrade: The most specialized upgrade but likely the most powerful. When placed in a Crystal Vulcanizer, the yield of crystals it creates increases from 2 per raw item to 3 crystals each, making it triple normal yield. However, the time and heat cost it takes also increases very considerably.
* The mystique of heat power and its measurement is now gone; the actual number of HU (heat units) in a machine are now shown on their GUIs, underneath the heat bar.
* The front of Crystal Vulcanizers now has a different texture to differentiate it from its sides.
* Last but not least, Thermoboxes finally function! They are a combination heat-storage device and also director of heat. Five of its six sides (blue marked ones) act as usual inputs from adjacent heaters, HEAT rays or even other thermoboxes, while its output (the orange-marked side) will send heat to an adjacent machine.
* To accompany the Thermobox, its slightly cheaper and opposite cousin the Thermal Distributor has been added as well. It doesn't store nearly as much heat, but given a heat input on its blue side it will equally distribute heat to machines at its orange sides.

### Version 1.9
* "Solar Glass" is now "Heat-transference Glass" to reflect its expanded use. Additionally, you now get 3 of them for one recipe.
* Some overdue graphic cleanup and changes have been made.
* The Teruchalcum is always greener on the other version.
    * More seriously, the look of Teruchalcum was changed slightly to be shinier and greenier.
* The ore-cutting saw is now a proper size when wielded.
* Overdue but finally: You can use pure terumetal ingots in the Alloy Smelter as flux. Smelting terumetal lumps no longer makes them useless for alloying! This should have been the case since multiple flux items were implemented, but...
* The first Coreglass Framed machine has now been added: HEAT Ray Emitters! This amazing device takes heat like any other machine but is made to transmit it over long distances. Using a standard screwdriver, rotate the emitter so its brightly-colored output side points to and is aligned with another machine far away. After a period where it seeks out a target (the longer distance, the longer it takes) it will fire a High Energy Alpha-wave Trasmission beam, sending a large amount of heat from its own storage to that machine.
    * You can change settings regarding the particle effects for the ray and whether it displays a "seeking" effect while searching in options.lua
* Additionally, a much less expensive HEAT Ray Reflector block was added to assist with sending HEAT Rays around corners. A Reflector points in only one direction, but any rays that strike it from any of the other sides will be sent through the direction it points. HEAT Ray Emitters take Reflectors into consideration automatically when seeking.

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
