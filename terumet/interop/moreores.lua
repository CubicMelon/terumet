
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