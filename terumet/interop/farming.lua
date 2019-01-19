
-- add crushing recipes for each farming redo crop (by farming:X id)

-- small crops turn into 2 biomatter
local small_crops = {
    'wheat', 'peas', 'barley', 'beans', 'pepper', 'beetroot', 'chili_pepper', 'blueberries',
    'cucumber', 'grapes', 'garlic', 'onion', 'pea_pod', 'pineapple_ring', 'pineapple_top', 'potato',
    'raspberries', 'tomato', 'corn', 'rhubarb'
}

for _,crop in ipairs(small_crops) do
    terumet.options.crusher.recipes['farming:'..crop] = 'terumet:item_dust_bio 2'
end

-- big crops turn into 5 biomatter
local big_crops = {
    'pumpkin', 'pineapple', 'melon_8'
}

for _,crop in ipairs(big_crops) do
    terumet.options.crusher.recipes['farming:'..crop] = 'terumet:item_dust_bio 5'
end