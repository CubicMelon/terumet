## Terumetal mod changelog
Newer versions listed first

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
