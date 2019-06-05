
local rloot = dungeon_loot.register
local id = terumet.id

local BOTTOM = -32768
local TOP = 32768

-- still a WIP on balance/items put into loot

rloot{name=id('item_col_raw'), chance=0.7, count={3,9}, y={-32, TOP}}
rloot{name=id('item_col_tcop'), chance=0.8, count={3,9}, y={-256, 0}}
rloot{name=id('item_col_tgol'), chance=0.9, count={3,9}, y={BOTTOM, -32}}

rloot{name=id('lump_raw'), chance=0.8, count={2,6}, y={0, TOP}}
rloot{name=id('ingot_raw'), chance=0.7, count={1,4}, y={0, TOP}}
rloot{name=id('lump_raw'), chance=0.85, count={6,12}, y={BOTTOM, 0}}
rloot{name=id('ingot_raw'), chance=0.75, count={3,8}, y={BOTTOM, 0}}

rloot{name=id('item_glue'), chance=0.95, count={3,24}, y={-16, TOP}}
rloot{name=id('item_coke'), chance=0.85, count={1,10}, y={BOTTOM, -32}}
rloot{name=id('item_tarball'), chance=0.75, count={1,10}, y={BOTTOM, -64}}

rloot{name=id('block_pwood'), chance=0.85, count={8,24}, y={BOTTOM, 128}}
rloot{name=id('block_conmix'), chance=0.65, count={8,24}, y={BOTTOM, 128}}
rloot{name=id('block_asphalt'), chance=0.75, count={8,24}, y={BOTTOM, 48}}

rloot{name=id('item_ceramic'), chance=0.65, count={2,10}, y={-8, TOP}}
rloot{name=id('item_ceramic'), chance=0.85, count={6,24}, y={BOTTOM, -8}}
rloot{name=id('block_ceramic'), chance=0.45, count={1,3}, y={BOTTOM, -128}}

rloot{name=id('item_batt_cop_full'), chance=0.10, y={BOTTOM, -64}}
rloot{name=id('item_batt_therm_full'), chance=0.05, y={BOTTOM, -256}}

rloot{name=id('item_htglass'), chance=0.5, count={1,3}, y={BOTTOM, 0}}
rloot{name=id('item_entropy'), chance=0.2, y={BOTTOM, -128}}

rloot{name=id('repmat_drop'), chance=0.5, count={4,24}, y={BOTTOM, -8}}

-- TODO: weight alloys by value
for _,alloy_data in pairs(terumet.alloys) do
    rloot{name=alloy_data.ingot, chance=0.30, count={1,4}, y={16, TOP}}
    rloot{name=alloy_data.ingot, chance=0.50, count={3,9}, y={-64, 16}}
    rloot{name=alloy_data.ingot, chance=0.70, count={6,12}, y={BOTTOM, -64}}
end