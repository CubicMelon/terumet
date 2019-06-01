local coke_id = terumet.id('item_coke')

minetest.register_craftitem( coke_id, {
    description = 'Coke Lump',
    inventory_image = terumet.tex(coke_id),
    groups = {coal = 1, flammable = 1},
})

minetest.register_craft({
	type = "fuel",
	recipe = coke_id,
	burntime = 80,
})

local coke_block_id = terumet.id('block_coke')

minetest.register_node( coke_block_id, {
    description = 'Coke Block',
    tiles = {terumet.tex(coke_block_id)},
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	type = "fuel",
	recipe = coke_block_id,
	burntime = 740,
})

minetest.register_craft{ output = coke_block_id,
    recipe = terumet.recipe_3x3(coke_id)
}

minetest.register_craft{ type = 'shapeless', output = coke_id .. ' 9',
    recipe = {coke_block_id},
}

local tarball_id = terumet.id('item_tarball')

minetest.register_craftitem( tarball_id, {
    description = 'Tarball',
    inventory_image = terumet.tex(tarball_id),
    groups = {glue=1}
})

minetest.register_craft({
	type = "fuel",
	recipe = tarball_id,
	burntime = 20,
})

local rubber_bar_id = terumet.id('item_rubber')

minetest.register_craft({
	type = 'cooking',
	output = rubber_bar_id,
	recipe = tarball_id,
	cooktime = 60,
})

minetest.register_craftitem( rubber_bar_id, {
    description = 'Synthetic Rubber Bar',
    inventory_image = terumet.tex(rubber_bar_id)
})

local rsuit_mat = terumet.id('item_rsuitmat')

minetest.register_craftitem( rsuit_mat, {
    description = 'Vulcansuit Plate',
    inventory_image = terumet.tex(rsuit_mat)
})

terumet.register_alloy_recipe{result=rsuit_mat, flux=8, time=10.0, input={rubber_bar_id, 'terumet:ingot_tcha'}}