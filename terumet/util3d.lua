-- Utility functions for dealing with 3D math and node rotations/facing directions

-- "Facing" is the direction the top of the node points, i.e. the axis the node rotates around with a screwdriver.
-- "Rotation" is the direction the "front" of the node points, i.e. the face that rotates with a screwdriver.

-- The 6th texture in "tiles" of a facedir-type node is considered the "front" since that 
-- is the side that faces the player when placed.

-- by Terumoc

local THIS_VERSION = 1
-- don't overwrite a later version if its already loaded
if util3d then
    if util3d.version >= THIS_VERSION then return end
end

util3d = {}
util3d.version = THIS_VERSION

-- given a node pos plus another pos/offset, add them together
function util3d.pos_plus(pos, offset)
    return {
        x=pos.x + offset.x,
        y=pos.y + offset.y,
        z=pos.z + offset.z,
    }
end

-- given a facedir node's param2, return the FACING index
function util3d.param2_to_facing(param2)
    return math.floor(param2 / 4)
end

-- given a facedir node's param2, return the ROTATION index
function util3d.param2_to_rotation(param2)
    return param2 % 4
end

-- given a node rotation and position, get the position relative to its front
function util3d.get_front_pos(rot, pos)
    return util3d.pos_plus(pos, util3d.ROTATION_OFFSETS[rot].front)
end
function util3d.get_back_pos(rot, pos)
    return util3d.pos_plus(pos, util3d.ROTATION_OFFSETS[rot].back)
end
function util3d.get_leftside_pos(rot, pos)
    return util3d.pos_plus(pos, util3d.ROTATION_OFFSETS[rot].left)
end
function util3d.get_rightside_pos(rot, pos)
    return util3d.pos_plus(pos, util3d.ROTATION_OFFSETS[rot].right)
end

-- human-readable directions of facings
util3d.FACING_DIRECTION = {
    [0]='up', [1]='north', [2]='south', [3]='east', [4]='west', [5]='down'
}

-- x/y/z offsets for each human-readable direction
util3d.ADJACENT_OFFSETS = {
    east={x=1,y=0,z=0}, west={x=-1,y=0,z=0},
    up={x=0,y=1,z=0}, down={x=0,y=-1,z=0},
    north={x=0,y=0,z=1}, south={x=0,y=0,z=-1}
}

-- auto-generated constants for x/y/z offset in a facing index
-- ex: FACING_OFFSETS[1]: 1 = facing north so returns offset of {x=0,y=0,z=1} (+1 node north)
util3d.FACING_OFFSETS = {}
for facing,dir in pairs(util3d.FACING_DIRECTION) do
    util3d.FACING_OFFSETS[facing] = util3d.ADJACENT_OFFSETS[dir]
end

-- relative x/y/z offset for rotations
util3d.ROTATION_OFFSETS = {
    [0]={left={x=-1,y=0,z=0}, right={x=1,y=0,z=0}, front={x=0,y=0,z=-1}, back={x=0,y=0,z=1}},
    [1]={left={x=0,y=0,z=1}, right={x=0,y=0,z=-1}, front={x=-1,y=0,z=0}, back={x=1,y=0,z=0}},
    [2]={left={x=1,y=0,z=0}, right={x=-1,y=0,z=0}, front={x=0,y=0,z=1}, back={x=0,y=0,z=-1}},
    [3]={left={x=0,y=0,z=-1}, right={x=0,y=0,z=1}, front={x=1,y=0,z=0}, back={x=-1,y=0,z=0}},
}

