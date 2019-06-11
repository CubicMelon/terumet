local food_opts = terumet.options.vac_oven.VAC_FOOD

-- add farming foods to vac-food whitelist if it's active
if food_opts and food_opts.ACTIVE then
    local foods = {
        'baked_potato', 'potato_salad', 'pumpkin_bread', 'toast_sandwich', 'donut', 'donut_chocolate', 'donut_apple', 'porridge', 'turkish_delight',
        'chili_bowl', 'rhubarb_pie', 'garlic_bread', 'muffin_blueberry', 'chocolate_dark'
    }

    for _,id in ipairs(foods) do
        food_opts.WHITELIST[string.format('farming:%s', id)]=1
    end
end