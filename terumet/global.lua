-- returns a function that defines global utility functions used across all of my mods
-- the function expects to be passed mod's main table with the following defined:
--      modtable.mod_name = ID of mod
--      modtable.version = table of keys major, minor, patch (optional)

-- by Terumoc / Scott Horvath

-- ===================================================================================================================
--      3D UTILITY
-- ===================================================================================================================
local util3d = {}

-- Utility functions for dealing with 3D math and node rotations/facing directions

-- "Facing" is the direction the top of the node points, i.e. the axis the node rotates around with a screwdriver.
-- "Rotation" is the direction the "front" of the node points, i.e. the face that rotates with a screwdriver.

-- The 6th texture in "tiles" of a facedir-type node is considered the "front" since that
-- is the side that faces the player when placed.

-- given a node pos plus another pos/offset, add them together
function util3d.pos_plus(pos, offset)
    return {
        x=pos.x + offset.x,
        y=pos.y + offset.y,
        z=pos.z + offset.z,
    }
end

-- given a node pos plus offset, return the offset pos and node there
function util3d.get_offset(pos, offset)
    pos = util3d.pos_plus(pos, offset)
    return pos, minetest.get_node_or_nil(pos)
end

-- given a facedir node's param2, return the FACING index
function util3d.param2_to_facing(param2)
    return math.floor(param2 / 4)
end

-- given a facedir node's param2, return the ROTATION index
function util3d.param2_to_rotation(param2)
    return param2 % 4
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
    [0]={left={x=-1,y=0,z=0}, right={x=1,y=0,z=0}, front={x=0,y=0,z=-1}, back={x=0,y=0,z=1}, top=util3d.ADJACENT_OFFSETS.up, bottom=util3d.ADJACENT_OFFSETS.down},
    [1]={left={x=0,y=0,z=1}, right={x=0,y=0,z=-1}, front={x=-1,y=0,z=0}, back={x=1,y=0,z=0}, top=util3d.ADJACENT_OFFSETS.up, bottom=util3d.ADJACENT_OFFSETS.down},
    [2]={left={x=1,y=0,z=0}, right={x=-1,y=0,z=0}, front={x=0,y=0,z=1}, back={x=0,y=0,z=-1}, top=util3d.ADJACENT_OFFSETS.up, bottom=util3d.ADJACENT_OFFSETS.down},
    [3]={left={x=0,y=0,z=-1}, right={x=0,y=0,z=1}, front={x=1,y=0,z=0}, back={x=-1,y=0,z=0}, top=util3d.ADJACENT_OFFSETS.up, bottom=util3d.ADJACENT_OFFSETS.down},
}

util3d.RELATIVE_SIDES = { 'top', 'bottom', 'left', 'right', 'front', 'back' }

function util3d.get_relative_pos(rot, pos, rel)
    if 'number'==type(rel) then rel = util3d.RELATIVE_SIDES[rel] end
    return util3d.pos_plus(pos, util3d.ROTATION_OFFSETS[rot][rel])
end

-- ===================================================================================================================
--      RETURN FUNCTION (WITH ENCLOSURED GENERAL UTILITY FUNCTIONS)
-- ===================================================================================================================

local FMT = string.format

return function(mod)
    -- set version text
    if mod.version then
        mod.version_text = mod.version.major .. '.' .. mod.version.minor .. '.' .. mod.version.patch
    else
        mod.version_text = 'no mod.version set'
    end

    -- make 3d utilities available under "mod.util3d"
    mod.util3d = util3d

    -- constant empty function
    mod.NO_FUNCTION = function() end
    -- constant empty table
    mod.EMPTY = {}
    -- constant zero vector
    mod.ZERO_VECTOR = {x=0,y=0,z=0}

    -- execute a Lua file in this mod's directory
    mod.do_lua_file = function(name)
        dofile(minetest.get_modpath(mod.mod_name) .. '/' .. name .. '.lua')
    end

    -- create an id for an item in this mod
    mod.id = function(id, number)
        if number then
            return FMT('%s:%s %d', mod.mod_name, id, number)
        else
            return FMT('%s:%s', mod.mod_name, id)
        end
    end

    -- append an item to the end of a table
    mod.push = function(tbl, item)
        tbl[#tbl+1]=item
    end

    -- return a texture given a standard ID
    -- ex "ham" -> "thismod_ham.png"
    -- handles other mods as well
    -- ex "default:stick" -> "default_stick.png"
    mod.tex = function(id)
        -- accepts both base ids (assuming this mod) and full mod ids
        if id:match(':') then
            return FMT('%s.png', id:gsub(':', '_'))
        else
            return FMT('%s_%s.png', mod.mod_name, id)
        end
    end

    -- return a composited texture
    mod.tex_comp = function(base_tex, overlay_id)
        return base_tex .. '^' .. mod.tex(overlay_id)
    end

    -- return a full 3x3 recipe pattern
    mod.recipe_3x3 = function(i)
        return {
            {i, i, i}, {i, i, i}, {i, i, i}
        }
    end

    -- return a box-shaped recipe pattern
    mod.recipe_box = function(outer, inner)
        outer = outer or ''
        inner = inner or ''
        return {
            {outer, outer, outer}, {outer, inner, outer}, {outer, outer, outer}
        }
    end

    -- return a +-shaped recipe pattern
    mod.recipe_plus = function(plus, corners)
        plus = plus or ''
        corners = corners or ''
        return {
            {corners, plus, corners}, {plus, plus, plus}, {corners, plus, corners}
        }
    end

    -- add default values to table keys if they do not already exist
    mod.table_defaults = function(dest, defaults)
        for k,v in pairs(defaults) do
            dest[k] = dest[k] or v
        end
    end

    -- convert a plaintext name to acceptable ID format (ex: "White Wool" -> "white_wool")
    mod.name_to_id = function(name)
        return string.lower(name):gsub(' ', '_')
    end

    -- get a short description of an itemstack, eschewing any additional tooltip info (past a newline)
    mod.itemstack_desc = function(stack)
        local stack_desc = stack:get_definition().description
        -- use only what is before a newline if one is in the description
        if stack_desc:find('\n') then stack_desc = stack_desc:match('(.*)\n') end
        if stack:get_count() > 1 then
            return FMT('%s (x%d)', stack_desc, stack:get_count())
        else
            return stack_desc
        end
    end

    -- add an item to player's inventory, or if cannot fit, at their current location
    mod.give_player_item = function(pos, player, stack)
        local inv = player:get_inventory()
        local leftover = inv:add_item("main", stack)
        if leftover and not leftover:is_empty() then
            minetest.item_drop(leftover, player, player:get_pos())
        end
    end

    -- given a table with 'group:XXX' keys and a node/item definition with groups, return the
    -- (first) value in the table where node/item has a group key of XXX, otherwise nil
    mod.match_group_key = function(table, def)
        if not def then return nil end
        for group_name,_ in pairs(def.groups) do
            local grp_key = 'group:'..group_name
            if table[grp_key] then
                return table[grp_key]
            end
        end
        return nil
    end

    -- randomization provider for global functions
    mod.RAND = PcgRandom(os.time())

    -- returns true pct% of the time
    mod.chance = function(pct)
        if pct <= 0 then return false end
        if pct >= 100 then return true end
        return mod.RAND:next(1,100) <= pct
    end

    -- return a random vector where each dimension is between (-max_tenths/10 ... max_tenths/10)
    mod.random_vector = function(max_tenths)
        return {
            x = mod.RAND:next(-max_tenths,max_tenths) / 10,
            y = mod.RAND:next(-max_tenths,max_tenths) / 10,
            z = mod.RAND:next(-max_tenths,max_tenths) / 10
        }
    end

    -- generate a stream of particles (as defined by [particle_data]) from [pointA] to [pointB] - there will be [density] particles per node
    -- if a [playername] is provided, they will be visible only to that player
    mod.particle_stream = function(pointA, pointB, density, particle_data, playername)
        local dist_vector = {x=(pointB.x-pointA.x), y=(pointB.y-pointA.y), z=(pointB.z-pointA.z)}
        local dist = vector.length(dist_vector)
        local pcount = dist * density
        if pcount < 1 then return end -- guard against div/0
        local step = {x=(dist_vector.x/pcount), y=(dist_vector.y/pcount), z=(dist_vector.z/pcount)}
        local ppos = vector.new(pointA)
        for _ = 1,pcount do
            ppos = util3d.pos_plus(ppos, step)
            minetest.add_particle{
                pos = vector.new(ppos),
                velocity=mod.random_vector(5),
                expirationtime=(particle_data.expiration or 1),
                size=(particle_data.size or 1),
                glow=(particle_data.glow or 1),
                playername=playername,
                texture=particle_data.texture,
                animation=particle_data.animation
            }
        end
    end

end
