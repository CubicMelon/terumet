local id=terumet.id

terumet.register_crystal{
    suffix='raw',
    color='#dd859c',
    name='Crystallized Terumetal',
    source=id('lump_raw'),
    cooking_result=id('ingot_raw')
}
terumet.register_crystal{
    suffix='copper',
    color='#ebba5d',
    name='Crystallized Copper',
    source='default:copper_lump',
    cooking_result='default:copper_ingot'
}
terumet.register_crystal{
    suffix='tin',
    color='#dafbff',
    name='Crystallized Tin',
    source='default:tin_lump',
    cooking_result='default:tin_ingot'
}
terumet.register_crystal{
    suffix='iron',
    color='#a95230',
    name='Crystallized Iron',
    source='default:iron_lump',
    cooking_result='default:steel_ingot'
}
terumet.register_crystal{
    suffix='gold',
    color='#ffcb15',
    name='Crystallized Gold',
    source='default:gold_lump',
    cooking_result='default:gold_ingot'
}
-- following are WIP, will be created from custom items not yet implemented
terumet.register_crystal{
    suffix='ob',
    color='#1f2631',
    name='Crystallized Obsidian',
    source='nothing_yet',
    cooking_result='default:obsidian'
}
terumet.register_crystal{
    suffix='mese',
    color='#fffb81',
    name='Crystallized Mese',
    source='nothing_yet',
    cooking_result='default:mese_crystal'
}
terumet.register_crystal{
    suffix='dia',
    color='#66f6ff',
    name='Crystallized Diamond',
    source='nothing_yet',
    cooking_result='default:diamond'
}