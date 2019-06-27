
local crys_mithril = terumet.register_crystal{
    suffix='mith',
    color='#6161d5',
    name='Crystallized Mithril',
    cooking_result='moreores:mithril_ingot'
}
terumet.register_vulcan_result('moreores:mithril_lump', crys_mithril)
terumet.register_vulcan_result('moreores:mineral_mithril', crys_mithril, 1)

local crys_silver = terumet.register_crystal{
    suffix='silv',
    color='#d3fffb',
    name='Crystallized Silver',
    cooking_result='moreores:silver_ingot'
}
terumet.register_vulcan_result('moreores:silver_lump', crys_silver)
terumet.register_vulcan_result('moreores:mineral_silver', crys_silver, 1)


terumet.crystal_ids.mitril = crys_mithril
terumet.crystal_ids.silver = crys_silver

terumet.register_alloy_recipe{result='basic_materials:brass_ingot 3', flux=0, time=4.0, input={'default:copper_lump 2', 'moreores:silver_lump'}}
terumet.register_alloy_recipe{result='basic_materials:brass_ingot 3', flux=0, time=8.0, input={'default:copper_ingot 2', 'moreores:silver_ingot'}}
terumet.register_alloy_recipe{result='basic_materials:brass_block 3', flux=0, time=40.0, input={'default:copperblock 2', 'moreores:silver_block'}}
terumet.register_alloy_recipe{result='basic_materials:brass_ingot 3', flux=0, time=2.0, input={'terumet:item_cryst_copper 2', crys_silver}}
