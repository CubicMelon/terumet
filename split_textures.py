from wand.image import Image

SOURCE_FILE = 'texsource.png'
MOD_NAME = 'terumet'
DEST = 'split_textures/'

def MT(basename):
    return MOD_NAME + '_' + basename + '.png'

TEXTURE_FILES = [
    [MT('ore_raw'), MT('htr_furnace_front_unlit'), MT('raw_sides_unlit'), MT('htr_furnace_front_lit'), MT('raw_sides_lit'), MT('raw_mach_bot'), MT('raw_mach_top'), MT('asmelt_front_unlit'), MT('asmelt_front_lit')],
    [MT('lump_raw'), MT('ingot_raw'), MT('block_raw'), MT('tool_pick_raw'), MT('tool_shovel_raw'), MT('tool_axe_raw'), MT('tool_sword_raw'), MT('item_coil_raw')],
    [MT('item_cryst'), MT('ingot_tcop'), MT('block_tcop'), MT('tool_pick_tcop'), MT('tool_shovel_tcop'), MT('tool_axe_tcop'), MT('tool_sword_tcop'), MT('item_coil_tcop')],
    [MT('item_cryst_bg'), MT('ingot_tste'), MT('block_tste'), MT('tool_pick_tste'), MT('tool_shovel_tste'), MT('tool_axe_tste'), MT('tool_sword_tste')],
    [MT('item_ceramic'), MT('ingot_tgol'), MT('block_tgol'), MT('tool_pick_tgol'), MT('tool_shovel_tgol'), MT('tool_axe_tgol'), MT('tool_sword_tgol'), MT('item_coil_tgol')],
    [MT('block_ceramic'), MT('ingot_cgls'), MT('block_cgls'), MT('tool_pick_cgls'), MT('tool_shovel_cgls'), MT('tool_axe_cgls'), MT('tool_sword_cgls')],
    [MT('thermobox'), MT('item_thermese'), MT('block_thermese'), MT('frame_tste'), MT('frame_cgls'), MT('frame_raw'), MT('block_thermese_hot'), MT('item_solar')],
    [MT('htfurn_front'), MT('htfurn_top_unlit'), MT('htfurn_sides'), MT('htfurn_top_lit'), MT('vulcan_sides'), MT('vulcan_top'), MT('htr_solar_top')],
    [None, MT('ingot_tcha'), MT('block_tcha'), MT('tool_pick_tcha'), MT('tool_shovel_tcha'), MT('tool_axe_tcha'), MT('tool_sword_tcha'), MT('tool_ore_saw')]
]

with Image(filename=SOURCE_FILE) as source:
    for row in range(len(TEXTURE_FILES)):
        for col in range(len(TEXTURE_FILES[row])):
            if TEXTURE_FILES[row][col] != None:
                clone = source.clone()
                clone.crop(left=col*16, top=row*16, width=16, height=16)
                clone.save(filename=DEST + TEXTURE_FILES[row][col])
