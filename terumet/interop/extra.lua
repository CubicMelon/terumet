local food_opts = terumet.options.vac_oven.VAC_FOOD

-- add farming foods to vac-food whitelist if it's active
if food_opts and food_opts.ACTIVE then
    local foods = {
        'potato_crisps', 'french_fries', 'onion_rings', 'blooming_onion', 'fish_sticks', 'grilled_patty', 'hamburger', 'cheeseburger',
        'corn_dog', 'meatloaf', 'flour_tortilla', 'taco', 'super_taco', 'quesadilla', 'pepperoni', 'garlic_bread', 'spaghetti', 'lasagna', 'cheese_pizza',
        'salsa', 'pepperoni_pizza', 'deluxe_pizza', 'pineapple_pizza', 'cornbread'
    }

    for _,id in ipairs(foods) do
        food_opts.WHITELIST[string.format('extra:%s', id)]=1
    end
end