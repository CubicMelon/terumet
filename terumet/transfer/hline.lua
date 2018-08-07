local LINE_SIZE = 1/6

-- Special thanks to Elepower (https://gitlab.icynet.eu/evert/elepower) by IcyDiamond on the forums
-- for revealing to me the magic of drawtype "nodebox", type "connected"
minetest.register_node( terumet.id('xfer_hline'), {
    description = 'Heatline',
    tiles = {terumet.tex('hline')},
    
    groups={cracky=3, oddly_breakable_by_hand=3, teruhline=1},

    drawtype = "nodebox",
    paramtype = 'light',
    node_box = {
        type = "connected",
        fixed = {-LINE_SIZE, -LINE_SIZE, -LINE_SIZE, LINE_SIZE, LINE_SIZE, LINE_SIZE},
        connect_front = {-LINE_SIZE, -LINE_SIZE, -1/2, LINE_SIZE, LINE_SIZE, -LINE_SIZE},
        connect_back = {-LINE_SIZE, -LINE_SIZE, LINE_SIZE, LINE_SIZE, LINE_SIZE, 1/2},
        connect_top = {-LINE_SIZE, LINE_SIZE, -LINE_SIZE, LINE_SIZE, 1/2, LINE_SIZE},
        connect_bottom = {-LINE_SIZE, -1/2, -LINE_SIZE, LINE_SIZE, -LINE_SIZE, LINE_SIZE},
        connect_left = {-1/2, -LINE_SIZE, -LINE_SIZE, LINE_SIZE, LINE_SIZE, LINE_SIZE},
        connect_right = {LINE_SIZE, -LINE_SIZE, -LINE_SIZE, 1/2, LINE_SIZE, LINE_SIZE},
    },
    connect_sides = { "top", "bottom", "front", "left", "back", "right" },
    is_ground_content = false,
    connects_to = {
        "group:terumach",
        "group:teruhline",
    },
})
