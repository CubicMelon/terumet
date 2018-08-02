from wand.image import Image

SOURCE_FILE = 'texsource.png'
MOD_NAME = 'terumet'
DEST = 'terumet/textures/'

def MT(basename):
    return MOD_NAME + '_' + basename + '.png'

TEXTURE_FILES = [
    ['ore_raw', 'htr_furnace_front_unlit', 'raw_sides_unlit', 'htr_furnace_front_lit', 'raw_sides_lit', 'raw_mach_bot', 'raw_mach_top', 'asmelt_front_unlit', 'asmelt_front_lit', 'lavam_top'],
    ['lump_raw', 'ingot_raw', 'block_raw', 'tool_pick_raw', 'tool_shovel_raw', 'tool_axe_raw', 'tool_sword_raw', 'item_coil_raw', 'upg_base', 'lavam_front_unlit'],
    ['item_cryst', 'ingot_tcop', 'block_tcop', 'tool_pick_tcop', 'tool_shovel_tcop', 'tool_axe_tcop', 'tool_sword_tcop', 'item_coil_tcop', 'upg_ext_input', 'lavam_front_lit'],
    ['item_cryst_bg', 'ingot_tste', 'block_tste', 'tool_pick_tste', 'tool_shovel_tste', 'tool_axe_tste', 'tool_sword_tste', 'upg_ext_output', 'upg_max_heat', 'meseg_top', 'repm_front'],
    ['item_ceramic', 'ingot_tgol', 'block_tgol', 'tool_pick_tgol', 'tool_shovel_tgol', 'tool_axe_tgol', 'tool_sword_tgol', 'item_coil_tgol', 'upg_heat_xfer'],
    ['block_ceramic', 'ingot_cgls', 'block_cgls', 'tool_pick_cgls', 'tool_shovel_cgls', 'tool_axe_cgls', 'tool_sword_cgls', 'upg_gen_up', 'upg_speed_up'],
    ['item_entropy', 'item_thermese', 'block_thermese', 'frame_tste', 'frame_cgls', 'frame_raw', 'block_thermese_hot', 'item_htg', 'upg_cryst'],
    ['htfurn_front', 'htfurn_top_unlit', 'htfurn_sides', 'htfurn_top_lit', 'vulcan_sides', 'vulcan_top', 'htr_solar_top', 'vulcan_front', 'upg_cheat'],
    ['item_heatunit', 'ingot_tcha', 'block_tcha', 'tool_pick_tcha', 'tool_shovel_tcha', 'tool_axe_tcha', 'tool_sword_tcha', 'tool_ore_saw', 'block_entropy'],
    ['hray_sides', 'hray_front', 'hray_back', 'rayref_sides', 'rayref_front', 'rayref_back', 'tbox_sides', 'tbox_front', 'tbox_back'],
    ['tdis_sides', 'tdis_front', 'tdis_back', 'raw_heater_sides', 'tste_heater_sides', 'cgls_heater_sides', 'htr_entropy_top']
]

with Image(filename=SOURCE_FILE) as source:
    for row in range(len(TEXTURE_FILES)):
        for col in range(len(TEXTURE_FILES[row])):
            if TEXTURE_FILES[row][col] != None:
                clone = source.clone()
                clone.crop(left=col*16, top=row*16, width=16, height=16)
                clone.save(filename=DEST + MT(TEXTURE_FILES[row][col]))