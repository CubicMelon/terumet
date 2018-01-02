from wand.image import Image

SOURCE_FILE = 'texsource.png'
MOD_NAME = 'terumet'
DEST = 'split_textures/'

def MT(basename):
    return MOD_NAME + '_' + basename + '.png'

TEXTURE_FILES = [
    [MT('ore_raw'), MT('asmelt_front_unlit'), MT('asmelt_sides_unlit'), MT('asmelt_front_lit'), MT('asmelt_sides_lit'), MT('mach_bot'), MT('mach_top')],
    [MT('lump_raw'), MT('ingot_raw'), MT('block_raw'), MT('tool_pick_traw'), MT('tool_shovel_traw'), MT('tool_axe_traw'), MT('tool_sword_traw')],
    [MT('item_coil'), MT('ingot_alloy_tcop'), MT('block_alloy_tcop'), MT('tool_pick_tcop'), MT('tool_shovel_tcop'), MT('tool_axe_tcop'), MT('tool_sword_tcop')],
    [MT('item_ceramic'), MT('ingot_alloy_tste'), MT('block_alloy_tste'), MT('tool_pick_tste'), MT('tool_shovel_tste'), MT('tool_axe_tste'), MT('tool_sword_tste')],
    [MT('block_ceramic'), MT('ingot_alloy_tgol'), MT('block_alloy_tgol'), MT('tool_pick_tgol'), MT('tool_shovel_tgol'), MT('tool_axe_tgol'), MT('tool_sword_tgol')],
    [None, MT('ingot_alloy_cgls'), MT('block_alloy_cgls'), MT('tool_pick_cgls'), MT('tool_shovel_cgls'), MT('tool_axe_cgls'), MT('tool_sword_cgls')],
    [MT('block_thermbox'), MT('item_thermese'), MT('block_thermese')]
]

with Image(filename=SOURCE_FILE) as source:
    for row in range(len(TEXTURE_FILES)):
        for col in range(len(TEXTURE_FILES[row])):
            if TEXTURE_FILES[row][col] != None:
                clone = source.clone()
                clone.crop(left=col*16, top=row*16, width=16, height=16)
                clone.save(filename=DEST + TEXTURE_FILES[row][col])
