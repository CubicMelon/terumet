-- this can be a machine! -> machines already automatically send heat to adjacent accepting machines
-- follow attached conn_hlines to target machine(s) and send heat

local PLUG_SIZE = 6/16
local LINE_SIZE = 3/16

minetest.register_node( terumet.id('conn_hline_in'), {
    description = 'Heatline Input (WIP)',

    groups={cracky=3, oddly_breakable_by_hand=3, teruhline=1},
    tiles = {terumet.tex('hline_in')},
    is_ground_content = false,
})