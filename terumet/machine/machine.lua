-- contains general functions/attributes applicable to any Terumetal/heat-based machine
terumet.machine = {}
local base_mach = terumet.machine
local opts = terumet.options.machine

function base_mach.heat_pct(machine)
    return 100.0 * machine.heat_level / machine.max_heat
end

-- implement machine owner protection
local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)
    if (not name) or name == '' then return true end
    local node = minetest.get_node_or_nil(pos)
    if node then
        local nodedef = minetest.registered_nodes[node.name]
        if nodedef and nodedef._terumach_class then
            local owner = minetest.get_meta(pos):get_string('owner')
            if base_mach.has_auth({owner=owner}, name) then
                return false
            else
                minetest.chat_send_player(name, 'You do not have permission to do that.')
                minetest.record_protection_violation(pos, name)
                return true
            end
        end
    end
    return old_is_protected(pos, name)
end

--
-- CONSTANTS
--

-- constants for interactive heat behavior of machines
base_mach.HEAT_XFER_MODE= {
    NO_XFER=0,
    ACCEPT=1,
    PROVIDE_ONLY=2
}

-- constants for absolute direction = pos offset
base_mach.ADJACENT_OFFSETS = {
    east={x=1,y=0,z=0}, west={x=-1,y=0,z=0},
    up={x=0,y=1,z=0}, down={x=0,y=-1,z=0},
    north={x=0,y=0,z=1}, south={x=0,y=0,z=-1}
}

-- constants for facing direction, FACING_DIRECTION[node.param2 / 4] = front absolute direction
base_mach.FACING_DIRECTION = {
    [0]='up', [1]='north', [2]='south', [3]='east', [4]='west', [5]='down'
}

-- auto-generated constants for pos offset in facing direction given index [node.param2 / 4]
-- ex: FACING_OFFSETS[1]: 1 = facing north so returns offset of {x=0,y=0,z=1} (+1 node north)
base_mach.FACING_OFFSETS = {}
for facing,dir in pairs(base_mach.FACING_DIRECTION) do
    base_mach.FACING_OFFSETS[facing] = base_mach.ADJACENT_OFFSETS[dir]
end

-- index = rotation
base_mach.SIDE_OFFSETS = {
    [0]={left={x=-1,y=0,z=0}, right={x=1,y=0,z=0}},
    [1]={left={x=0,y=0,z=1}, right={x=0,y=0,z=-1}},
    [2]={left={x=1,y=0,z=0}, right={x=-1,y=0,z=0}},
    [3]={left={x=0,y=0,z=-1}, right={x=0,y=0,z=1}},
}

function base_mach.get_leftside_pos(rot, pos)
    return terumet.pos_plus(pos, base_mach.SIDE_OFFSETS[rot].left)
end
function base_mach.get_rightside_pos(rot, pos)
    return terumet.pos_plus(pos, base_mach.SIDE_OFFSETS[rot].right)
end

-- 
-- CRAFTING MATERIALS
--

function base_mach.register_frame(id, name, craft_item, center_item)
    -- added and modified from https://github.com/Terumoc/terumet/pull/1 by RSL-Redstonier - thanks!
    minetest.register_node(terumet.id(id), {
        description = name,
        tiles = {terumet.tex(id)},
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {0.375, 0.375, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
                {-0.5, 0.375, -0.5, -0.375, 0.5, 0.5}, -- NodeBox2
                {-0.5, -0.5, -0.5, -0.375, -0.375, 0.5}, -- NodeBox3
                {0.375, -0.5, -0.5, 0.5, -0.375, 0.5}, -- NodeBox4
                {-0.5, -0.5, -0.5, -0.375, 0.4375, -0.375}, -- NodeBox5
                {-0.5, -0.5, 0.375, -0.375, 0.5, 0.5}, -- NodeBox6
                {0.375, -0.5, 0.375, 0.5, 0.5, 0.5}, -- NodeBox7
                {0.375, -0.5, -0.5, 0.5, 0.5, -0.375}, -- NodeBox8
                {-0.5, 0.375, 0.375, 0.5, 0.5, 0.5}, -- NodeBox9
                {-0.5, -0.5, 0.375, 0.5, -0.375, 0.5}, -- NodeBox10
                {-0.5, -0.5, -0.5, 0.5, -0.375, -0.375}, -- NodeBox11
                {-0.5, 0.375, -0.5, 0.5, 0.5, -0.375}, -- NodeBox12
            }
        },
        is_ground_content = false,
        groups = {cracky = 2},
        sounds = default.node_sound_metal_defaults()
    })

    minetest.register_craft({
        output = terumet.id(id),
        recipe = terumet.recipe_box(terumet.id(craft_item), center_item or '')
    })
end

base_mach.register_frame('frame_raw', 'Terumetal Machine Frame\nFoundation of simple Terumetal machinery', 'ingot_raw', 'default:copperblock')
base_mach.register_frame('frame_tste', 'Terusteel Machine Frame\nFoundation of advanced Terumetal machinery', 'ingot_tste', terumet.id('item_thermese'))
base_mach.register_frame('frame_cgls', 'Coreglass Machine Frame\nFoundation of highly advanced Terumetal machinery', 'ingot_cgls', terumet.id('mach_thermobox'))

--
-- GENERIC FORMSPECS
--

local SPECIAL_OWNERS = {
    [''] = '<None>',
    ['*'] = '<Everyone>'
}

local fs_container = function(fsx,fsy,machine,content_func)
    return string.format('container[%f,%f]%scontainer_end[]', fsx, fsy, func(machine))
end

base_mach.buttondefs = {}
-- standard control button to toggle on/off heat transfer
base_mach.buttondefs.HEAT_XFER_TOGGLE = {
    flag = function(machine)
        return machine.heat_xfer_mode == machine.class.default_heat_xfer
    end,
    icon = 'terumet_gui_heatxfer.png',
    name = 'hxfer_toggle',
    on_text = 'Heat transfer on',
    off_text = 'Heat transfer off'
}

-- build and return a formspec given a machine state
-- takes fsdef table from machine's class definition to define what is shown and where
-- _terumach_class.fsdef guidelines: is a table with definitions for sections or elements. Nearly all info is optional and will be given standard defaults (or omitted) if not provided
--      .size  -> must be a table with {x=width, y=height} (in item slots, like normal formspec dimensions), size defaults to 11x9 if not given
--      .theme -> string that provides background, listcolors
--      .before  -> fn(machine) that returns formspec string to insert after preamble
--      .control -> fn(machine) that returns formspec string to insert inside machine controls container
--      .control_buttons -> table of machine buttondefs:
--              .flag -> string of machine flag or function that returns whether control is on/off
--              .icon -> image to use as base icon for button
--              .name -> id to assign to button (returned as field to machine's on_form_action)
--              .on_text + .off_text -> tooltips when on/off
--      .machine -> fn(machine) that returns formspec string to insert inside main machine container
--      .status_text -> {x,y} to reposition status text or 'hide' to not show
--      .input -> {true} or {x,y,w,h} that input slots/info should be shown (2x2 slots if no width/height provided)
--      .output -> {true} or {x,y,w,h} that output slots/info should be shown (2x2 slots if no width/height provided)
--      .fuel_slot -> {true} or {x,y} that fuel slot should be shown in control section
--      .player_inv -> {x,y} that repositions player inventory, or 'hide' to not show
--      .list_rings -> formspec string that defines list rings, otherwise: player;main -> machine;in -> player;main -> machine;out ->
--      .after -> fn(machine) that returns formspec string to insert after all other formspec content
function base_mach.build_fs(machine)
    local fsdef = machine.class.fsdef
    -- start/misc section
    local fs_width = (fsdef.size and fsdef.size.x) or 11
    local fs_height = (fsdef.size and fsdef.size.y) or 9
    local fs = string.format('size[%f,%f]', fs_width, fs_height)
    fs = fs .. (fsdef.theme or string.format('background[0,0;%f,%f;terumet_gui_back.png;true]listcolors[#432d31;#91626b;#3f252b;#114f51;#d2fdff]', fs_width, fs_height))
    if fsdef.before then
        fs = fs .. fsdef.before(machine)
    end
    -- control container
    fs = fs..'container[0,0]'
    fs = fs..string.format('label[0,0;%s]', machine.class.name)
    if machine.heat_level > machine.max_heat then
        fs = fs..'image[0,0.5;3.5,1;terumet_gui_overheat.png^[transformR270]label[1.2,0.9;Overheated]'
    else
        fs = fs..base_mach.fs_meter(0,0.5, 'heat', base_mach.heat_pct(machine), string.format('%d HU', machine.heat_level))
    end
    -- control: fuel_slot
    if fsdef.fuel_slot then
        local fsx = fsdef.fuel_slot.x or 0
        local fsy = fsdef.fuel_slot.y or 1.5
        fs = fs..string.format('label[%f,%f;Fuel]list[context;fuel;%f,%f;1,1;]', fsx, fsy, fsx, fsy+0.5)
    end
    -- control: upgrade slots
    local upg_ct = machine.inv:get_size('upgrade')
    if upg_ct and upg_ct > 0 then
        local upx = 0
        local upy = fs_height - 3.75
        fs = fs..string.format('label[%f,%f;Upgrades]list[context;upgrade;%f,%f;3,%d]', upx, upy, upx, upy+0.5, math.ceil(upg_ct/3))
    end
    --fs = fs..string.format('label[0,%f;HU Xfer: %s]', fs_height - 1, opts.HEAT_TRANSFER_MODE_NAMES[machine.heat_xfer_mode])
    fs = fs..string.format('label[0,%f;Owner: \n%s]', fs_height - 1, SPECIAL_OWNERS[machine.owner] or machine.owner)
    if fsdef.control then
        fs = fs .. fsdef.control(machine)
    end
    -- control: buttons container
    fs = fs..'container[0,3]'

    local btx = 0
    local bty = 0 
    for _, buttondef in ipairs(fsdef.control_buttons) do
        if buttondef.flag then
            local flag_on = false
            if type(buttondef.flag) == 'string' then
                flag_on = machine[buttondef.flag]
            elseif type(buttondef.flag) == 'function' then
                flag_on = buttondef.flag(machine)
            end
            if flag_on then
                fs = fs .. string.format('image_button[%f,%f;0.75,0.75;%s;%s; ]tooltip[%s;%s]',
                    btx, bty, buttondef.icon, buttondef.name, buttondef.name, buttondef.on_text)
            else
                fs = fs .. string.format('image_button[%f,%f;0.75,0.75;(%s^terumet_gui_disabled.png);%s; ]tooltip[%s;%s]',
                    btx, bty, buttondef.icon, buttondef.name, buttondef.name, buttondef.off_text)
            end
            bty = bty + 0.75
            if bty >= 4 then
                bty = 0
                btx = btx + 0.75
            end
        end
    end
    -- machine container
    fs = fs..'container_end[]container_end[]container[3,0]'
    if 'hide' ~= fsdef.status_text then
        local sttx = (fsdef.status_text and fsdef.status_text.x) or 0
        local stty = (fsdef.status_text and fsdef.status_text.y) or 0
        fs = fs..string.format('label[%f,%f;%s]', sttx, stty, machine.status_text)
    end
    if fsdef.machine then
        fs = fs .. fsdef.machine(machine)
    end
    -- machine: input
    if fsdef.input then
        local inpx = fsdef.input.x or 0.5
        local inpy = fsdef.input.y or 1.5
        local inpw = fsdef.input.w or 2
        local inph = fsdef.input.h or 2
        if base_mach.has_upgrade(machine, 'ext_input') then
            local input_node = minetest.get_node(base_mach.get_leftside_pos(machine.rot, machine.pos))
            fs = fs .. string.format('label[%f,%f;External Input]item_image[%f,%f;%d,%d;%s]', inpx, inpy, inpx, inpy+0.5, inpw, inph, input_node.name)
        else
            fs = fs .. string.format('label[%f,%f;Input]list[context;in;%f,%f;%d,%d;]', inpx, inpy, inpx, inpy+0.5, inpw, inph)
        end
    end
    -- machine: output
    if fsdef.output then
        local outx = fsdef.output.x or 5.5
        local outy = fsdef.output.y or 1.5
        local outw = fsdef.output.w or 2
        local outh = fsdef.output.h or 2
        if base_mach.has_upgrade(machine, 'ext_output') then
            local output_node = minetest.get_node(base_mach.get_rightside_pos(machine.rot, machine.pos))
            fs = fs .. string.format('label[%f,%f;External Output]item_image[%f,%f;%d,%d;%s]', outx, outy, outx, outy+0.5, outw, outh, output_node.name)
        else
            fs = fs .. string.format('label[%f,%f;Output]list[context;out;%f,%f;%d,%d;]', outx, outy, outx, outy+0.5, outw, outh)
        end
    end
    fs = fs..'container_end[]'
    -- player inventory
    if 'hide' ~= fsdef.player_inv then
        local pix = (fsdef.player_inv and fsdef.player_inv.x) or 3
        local piy = (fsdef.player_inv and fsdef.player_inv.y) or fs_height - 4.25
        fs = fs..string.format('list[current_player;main;%f,%f;8,1;]list[current_player;main;%f,%f;8,3;8]', pix, piy, pix, piy+1.25)
    end
    -- list rings
    if fsdef.list_rings then
        fs = fs..fsdef.list_rings
    else
        fs = fs..'listring[current_player;main]listring[context;in]listring[current_player;main]listring[context;out]'
    end
    if fsdef.after then
        fs = fs .. fsdef.after(machine)
    end
    --minetest.log('warn', fs)
    return fs
end

function base_mach.build_infotext(machine)
    return string.format('%s (%.1f%% heat): %s', machine.class.name, base_mach.heat_pct(machine), machine.status_text)
end

-- basic process display
function base_mach.fs_proc(fsx, fsy, proc, itemstack)
    if itemstack and not itemstack:is_empty() then
        return string.format('image[%f,%f;2,2;terumet_gui_proc_%s.png]item_image[%f,%f;1,1;%s]', 
            fsx, fsy, proc, fsx+0.4, fsy+0.4, itemstack:get_name())
    else
        return string.format('image[%f,%f;2,2;terumet_gui_proc_%s.png]', fsx, fsy, proc)
    end
end

-- basic meter display
function base_mach.fs_meter(fsx, fsy, id, fill, text)
    return string.format('label[%f,%f;%s]image[%f,%f;3.5,1;(terumet_gui_bg_%s.png^[lowpart:%f:terumet_gui_fg_%s.png)^[transformR270]',
        fsx+1.2,fsy+0.4,text, fsx, fsy, id, fill, id)
end

-- double meter display (no text)
function base_mach.fs_double_meter(fsx, fsy, mainid, mainfill, oppid, oppfill)
    return string.format('image[%f,%f;3.5,1;(terumet_gui_bg_%s.png^[lowpart:%f:terumet_gui_fg_%s.png^[lowpart:%f:terumet_gui_fg_%s.png)^[transformR270]',
        fsx, fsy, mainid, mainfill, mainid, oppfill, oppid)
end
--
-- GENERIC META
--

-- return a list of {count=number, direction=machine_state, direction=machine_state...} from all adjacent positions 
-- where there is a machine w/heat_xfer_mode of ACCEPT and heat_level < max_heat
function base_mach.find_adjacent_need_heat(pos)
    local result = {}
    local count = 0
    for dir,offset in pairs(base_mach.ADJACENT_OFFSETS) do
        local opos = terumet.pos_plus(pos, offset)
        local ostate = base_mach.read_state(opos)
        -- read_state returns nil if area unloaded or not a terumetal machine
        if ostate then 
            if ostate.heat_xfer_mode == base_mach.HEAT_XFER_MODE.ACCEPT and ostate.heat_level < ostate.max_heat then
                result[dir] = ostate
                count = count + 1
            end
        end
    end
    result.count = count
    return result
end

-- given a list of target machines, evenly distribute up to total_hus from 'from' machine to them all
function base_mach.do_push_heat(from, total_hus, targets)
    local total_distrib = math.min(from.heat_level, total_hus)
    if total_distrib == 0 or #targets == 0 then return end
    -- can't afford to even give 1 HU to each target?
    if from.heat_level < #targets then return end
    local hus_each = math.floor(total_distrib / #targets)
    local actual_hus_sent = 0
    for i=1,#targets do
        local to_machine = targets[i]
        -- if from and to_machine are the same, don't bother sending any heat
        if not vector.equals(from.pos, to_machine.pos) then
            local send_amount = math.min(hus_each, to_machine.max_heat - to_machine.heat_level)
            if send_amount > 0 then
                to_machine.heat_level = to_machine.heat_level + send_amount
                --minetest.get_meta(to_machine.pos):set_int('heat_level', to_machine.heat_level)
                base_mach.write_state(to_machine.pos, to_machine)
                -- call heat receive callback for node if exists
                if to_machine.class.on_external_heat then
                    to_machine.class.on_external_heat(to_machine)
                end
                actual_hus_sent = actual_hus_sent + send_amount
            end
        end
    end
    from.heat_level = from.heat_level - actual_hus_sent
end

-- find all adjacent accepting machines and push desired amount of heat to them, split evenly
-- amount may be modified by heat_xfer upgrades in src or target(s)
-- if any sides are provided in table in 3rd argument, those specific sides will be ignored
function base_mach.push_heat_adjacent(machine, send_amount, ignore_sides)
    if send_amount <= 0 then return end
    local adjacent_needy = base_mach.find_adjacent_need_heat(machine.pos, ignore_sides)
    if ignore_sides then
        for _,ignored_side in ipairs(ignore_sides) do
            if adjacent_needy[ignored_side] then 
                adjacent_needy[ignored_side] = nil
                adjacent_needy.count = adjacent_needy.count - 1
            end
        end
    end
    if adjacent_needy.count > 0 then
        if base_mach.has_upgrade(machine, 'heat_xfer') then
            send_amount = send_amount * 2
        end
        local send_targets = {}
        for dir, target in pairs(adjacent_needy) do
            if dir ~= 'count' then 
                send_targets[#send_targets+1] = target 
                if base_mach.has_upgrade(target, 'heat_xfer') then
                    send_amount = math.floor(send_amount * 1.25)
                end
            end
        end
        base_mach.do_push_heat(machine, send_amount, send_targets)
    end
end

-- try to push an amount of heat to single target machine
-- amount may be modified by heat_xfer upgrades in src or target
-- returns true if we did
function base_mach.push_heat_single(machine, target, send_amount)
    if send_amount <= 0 then return false end
    if target.heat_xfer_mode ~= base_mach.HEAT_XFER_MODE.ACCEPT or target.heat_level >= target.max_heat then return false end
    if base_mach.has_upgrade(machine, 'heat_xfer') then
        send_amount = send_amount * 2
    end
    if base_mach.has_upgrade(target, 'heat_xfer') then
        send_amount = math.floor(send_amount * 1.25)
    end
    base_mach.do_push_heat(machine, send_amount, {target})
    return true
end

function base_mach.read_state(pos)
    local machine = {}
    local meta = minetest.get_meta(pos)
    local node_info = minetest.get_node_or_nil(pos)
    if not node_info then return nil end -- unloaded
    machine.nodedef = minetest.registered_nodes[node_info.name]
    machine.class = machine.nodedef._terumach_class
    if not machine.class then return nil end -- not a terumetal machine
    machine.pos = pos
    machine.meta = meta
    machine.owner = meta:get_string('owner')
    machine.facing = math.floor(node_info.param2 / 4)
    machine.rot = node_info.param2 % 4
    machine.inv = meta:get_inventory()
    machine.heat_level = meta:get_int('heat_level') or 0
    machine.max_heat = meta:get_int('max_heat') or 0
    machine.heat_xfer_mode = meta:get_int('heat_xfer_mode') or machine.class.default_heat_xfer
    machine.state = meta:get_int('state')
    machine.state_time = meta:get_float('state_time') or 0
    machine.status_text = meta:get_string('status_text') or 'No Status'
    machine.installed_upgrades = base_mach.get_installed_upgrades(machine)
    -- call read callback on node def if exists
    if machine.class.on_read_state then machine.class.on_read_state(machine) end
    -- following attributes are not saved in meta, but reset every tick
    machine.need_heat = false
    return machine
end

function base_mach.write_state(pos, machine)
    local meta = minetest.get_meta(pos)
    meta:set_string('owner', machine.owner)
    meta:set_string('status_text', machine.status_text)
    meta:set_int('heat_level', machine.heat_level or 0)
    meta:set_int('max_heat', machine.max_heat or 0)
    meta:set_int('heat_xfer_mode', machine.heat_xfer_mode or machine.class.default_heat_xfer)
    meta:set_int('state', machine.state)
    meta:set_float('state_time', machine.state_time)
    meta:set_string('formspec', base_mach.build_fs(machine))
    meta:set_string('infotext', base_mach.build_infotext(machine))
    -- call write callback on node def if exists
    if machine.class.on_write_state then machine.class.on_write_state(machine) end
end

function base_mach.set_node(pos, target_node)
    local node = minetest.get_node(pos)
    if node.name == target_node then return end
    node.name = target_node
    minetest.swap_node(pos, node)
end

--
-- GENERIC MACHINE PROCESSES
--

-- return inventory, list of where to acquire input
function base_mach.get_input(machine)
    if base_mach.has_upgrade(machine, 'ext_input') then
        local lpos = base_mach.get_leftside_pos(machine.rot, machine.pos)
        local lmeta = minetest.get_meta(lpos)
        if lmeta then return lmeta:get_inventory(), 'main' end
        return nil, nil
    else
        return machine.inv, 'in'
    end
end

-- return inventory, list of where to put output
function base_mach.get_output(machine)
    if base_mach.has_upgrade(machine, 'ext_output') then
        local rpos = base_mach.get_rightside_pos(machine.rot, machine.pos)
        local rmeta = minetest.get_meta(rpos)
        if rmeta then return rmeta:get_inventory(), 'main' end
        return nil, nil
    else
        return machine.inv, 'out'
    end
end

-- return true if machine has upgrade now installed
function base_mach.has_upgrade(machine, upgrade)
    if not machine.installed_upgrades then return false end
    return machine.installed_upgrades[upgrade]
end

-- return list of {upgrade_id=true, upgrade_id=true...} of machine's installed upgrades
-- automatically called on load_state and placed into machine.installed_upgrades but can be called seperately too
function base_mach.get_installed_upgrades(machine)
    local upgrades = {}
    local upgrade_inv = machine.inv:get_list('upgrade')
    if not upgrade_inv then return upgrades end
    for _, stack in ipairs(upgrade_inv) do
        local itemdef = stack:get_definition()
        if itemdef and itemdef._terumach_upgrade_id then
            upgrades[itemdef._terumach_upgrade_id] = true
        end
    end
    return upgrades
end

-- should be called every tick to change max_heat and/or vent excess heat
-- returns true if venting
function base_mach.check_overheat(machine, base_max_heat)
    if base_mach.has_upgrade(machine, 'max_heat') then
        machine.max_heat = math.floor(base_max_heat * 1.5)
    else
        machine.max_heat = base_max_heat
    end

    if machine.heat_level > machine.max_heat then
        if opts.PARTICLES then base_mach.generate_particle(machine.pos) end
        -- TODO make sound or something
        machine.heat_level = machine.heat_level - 50
        machine.status_text = 'Venting excess heat'
        return true
    end
    return false
end

function base_mach.set_timer(machine)
    local timer = minetest.get_node_timer(machine.pos)
    if not timer:is_started() then timer:start(machine.class.timer) end
end

function base_mach.set_low_heat_msg(machine, process)
    if process then
        machine.status_text = process .. ': Insufficient heat'
    else
        machine.status_text = 'Insufficient heat'
    end
end

-- return true if given player has authorization to use machine
-- (at minimum machine just has owner attribute)
function base_mach.has_auth(machine, player)
    return (machine.owner == '') or (machine.owner == '*') or (machine.owner == player)
end

-- handle basic fuel heating
function base_mach.process_fuel(machine)
    local fuel_item = machine.inv:get_stack('fuel',1)
    local heat_source = opts.BASIC_HEAT_SOURCES[fuel_item:get_name()]
    local hu_value = 0
    if heat_source then
        hu_value = heat_source.hus
        if base_mach.has_upgrade(machine, 'gen_up') then hu_value = math.floor(hu_value * 1.3) end
    end
    if heat_source and (machine.max_heat - machine.heat_level) >= hu_value then
        local out_inv, out_list = base_mach.get_output(machine)
        local return_item = heat_source.return_item
        if fuel_item:get_stack_max() > 1 then
            if (not return_item) or out_inv:room_for_item(out_list, return_item) then
                out_inv:add_item(out_list, return_item)
            else
                machine.status_text = 'Fuel: no output space for ' .. minetest.registered_items[return_item].description
                return
            end
            machine.inv:remove_item('fuel', fuel_item:get_name())
        else
            machine.inv:set_stack('fuel', 1, return_item)
        end
        machine.heat_level = math.min(machine.max_heat, machine.heat_level + hu_value)
        machine.need_heat = false
    end
end

-- handle expending heat
-- returns true if successful, false if not enough heat
-- automatically sets need_heat and "low heat message" if fails
function base_mach.expend_heat(machine, value, process)
    if machine.heat_level < value then
        base_mach.set_low_heat_msg(machine, process)
        machine.need_heat = true
        return false 
    end
    machine.heat_level = machine.heat_level - value
    return true
end

function base_mach.gain_heat(machine, value)
    machine.heat_level = math.min(machine.max_heat, machine.heat_level + value)
end

function base_mach.generate_particle(pos, particle_data)
    if not opts.PARTICLES then return end
    particle_data = particle_data or terumet.EMPTY
    local xoff = terumet.RAND:next(-5,5) / 10
    local zoff = terumet.RAND:next(-5,5) / 10
    local sz = terumet.RAND:next(50,400) / 100
    local vel = terumet.RAND:next(2,5) / 10
    minetest.add_particle{
        pos={x=pos.x+xoff, y=pos.y+0.5, z=pos.z+zoff},
        velocity={x=0, y=vel, z=0},
        acceleration={x=0, y=0.6, z=0},
        expirationtime=(particle_data.expiration or 1.5),
        size=sz,
        collisiondetection=false,
        texture=(particle_data.texture or 'default_item_smoke.png'),
        animation=particle_data.animation
    }
end

-- convert state of a machine to an itemstack
-- requires id of machine node and meta.fields (table of old meta, as per after_dig_node returns)
function base_mach.machine_to_itemstack(machine_id, machine_meta_fields)
    local stack = ItemStack{name = machine_id, count=1, wear=0}
    local nodedef = stack:get_definition()
    local stackmeta = stack:get_meta()
    local machine_heat = machine_meta_fields.heat_level
    local machine_max = machine_meta_fields.max_heat
    if machine_heat and machine_max then
        stackmeta:set_int('heat_level', machine_heat)
        stackmeta:set_string('description', string.format('%s\nHeat: %.1f%%', nodedef.description, 100.0*machine_heat/machine_max) )
    end
    return stack
end

--
-- BASIC MACHINE NODEDEF TEMPLATE GENERATOR
-- (makes considerable use of generic callbacks below)
--

function base_mach.nodedef(additions)
    local new_nodedef = { -- default properties for all machine nodedefs
        stack_max = 1,
        is_ground_content = false,
        sounds = default.node_sound_metal_defaults(),
        paramtype2 = 'facedir',
        groups = {cracky=1},
        drop = '', -- since after_dig_node/on_destruct/on_blast handles machines dropping w/stored heat, flag machines as ignoring usual drop mechanic
        -- default inventory slot control
        allow_metadata_inventory_put = base_mach.allow_put,
        allow_metadata_inventory_move = base_mach.allow_move,
        allow_metadata_inventory_take = base_mach.allow_take,
        -- default callbacks
        on_destruct = base_mach.on_destruct,
        on_blast = base_mach.on_blast,
        on_metadata_inventory_move = base_mach.simple_inventory_event,-- base_mach.on_inventory_move, for event_data
        on_metadata_inventory_put = base_mach.simple_inventory_event,-- base_mach.on_inventory_put, for event_data
        on_metadata_inventory_take = base_mach.simple_inventory_event,-- base_mach.on_inventory_take, for event_data
        on_rotate = screwdriver.rotate_simple, -- most machines always remain upright
        on_receive_fields = function(pos, formname, fields, sender)
            if not sender:is_player() then return end
            local player_name = sender:get_player_name()
            local machine = base_mach.read_state(pos)
            if machine then 
                if base_mach.has_auth(machine, player_name) then
                    --minetest.chat_send_player(player_name, dump(fields))
                    local save = false
                    -- handle default buttondefs
                    if fields.hxfer_toggle then
                        if machine.heat_xfer_mode == machine.class.default_heat_xfer then
                            machine.heat_xfer_mode = base_mach.HEAT_XFER_MODE.NO_XFER
                        else
                            machine.heat_xfer_mode = machine.class.default_heat_xfer
                        end
                        save = true
                    else
                        -- handle machine custom buttondefs - returns true to auto save machine state
                        if machine.class.on_form_action then
                            save = machine.class.on_form_action(machine, fields, player_name)
                        end
                    end
                    if save then
                        base_mach.write_state(machine.pos, machine)
                        base_mach.set_timer(machine)
                    end
                else
                    minetest.chat_send_player(player_name, 'You do not have permission to do that.')
                    minetest.record_protection_violation(pos, player_name)
                end
            end
        end,    
        -- callbacks for saving/loading heat level
        after_dig_node = base_mach.after_dig_machine,
        after_place_node = base_mach.after_place_machine,
        -- terumetal machine class
        _terumach_class = {
            -- timer: standard time (in seconds) for node timer to tick
            timer = 1.0,
            -- -
            -- drop_id: id of base machine that is dropped when broken
            -- -
            -- get_drop_contents: fn(machine) -> list of additional items to drop when broken (don't include self)
            get_drop_contents = function(machine)
                return {}
            end,
            -- -
            -- on_inventory_change: fn(machine, event_data) -> nil
            -- called whenever items are put in/taken out/moved within inventory
            -- event_data will contain specific info ONLY IF the nodedef's 
            --      on_metadata_inventory_* was pointed to base_mach.on_inventory_*
            --      instead of base_mach.simple_inventory_event
            on_inventory_change = function(machine, event_data)
                base_mach.set_timer(machine)
            end,
            -- -
            -- on_read_state: fn(machine) -> nil
            -- called whenever state is read from node metadata
            -- -
            -- on_write_state: fn(machine) -> nil
            -- called whenever state is written to node metadata
            -- usually used to update formspec/infotext
            -- -
            -- on_external_heat: fn(machine) -> nil
            -- called whenever machine receives heat from an external source
            -- by default just resets node timer
            on_external_heat = function(machine)
                base_mach.set_timer(machine)
            end,
            -- on_form_action: fn(machine, fields, player) -> save_machine_state
            -- called when authorized player sends fields from a machine's formspec
            -- return true to automatically re-save machine state after handling change(s)
            on_form_action = function(machine, fields, player)
                --minetest.chat_send_player(player, 'You took action on the GUI for ' .. machine.class.name .. ', but it has no on_form_action callback. Oops!')
                --minetest.chat_send_player(player, 'fields='..dump(fields))
            end
        }
    }
    if additions._terumach_class then
        for tk,tv in pairs(additions._terumach_class) do
            new_nodedef._terumach_class[tk] = tv
        end
    end
    for k,v in pairs(additions) do
        if k ~= '_terumach_class' then
            new_nodedef[k] = v
        end
    end
    return new_nodedef
end

--
-- GENERIC CALLBACKS
--

function base_mach.on_destruct(pos)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    local drops = mach.class.get_drop_contents(mach)
    for _,item in ipairs(drops) do
        minetest.add_item(pos, item)
    end
end

function base_mach.on_blast(pos)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    local drops = mach.class.get_drop_contents(mach)
    -- always need to return machine as well when exploded
    drops[#drops+1] = base_mach.machine_to_itemstack(mach.class.drop_id or mach.nodedef.name, mach.meta:to_table().fields)
    minetest.remove_node(pos)
    return drops
end

function base_mach.after_dig_machine(pos, oldnode, oldmeta_table, digger)
    local drop_id = minetest.registered_nodes[oldnode.name]._terumach_class.drop_id or oldnode.name
    local drop_item = base_mach.machine_to_itemstack(drop_id, oldmeta_table.fields)
    if not digger:is_player() then
        minetest.add_item(pos, drop_item)
    else
        terumet.give_player_item(pos, digger, drop_item)
    end
end

function base_mach.after_place_machine(pos, placer, itemstack, pointed_thing)
    local item_meta = itemstack:get_meta()
    local machine = base_mach.read_state(pos)
    if item_meta then
        local heat_level = item_meta:get_int('heat_level')
        if heat_level then
            machine.heat_level = heat_level
            base_mach.set_timer(machine)
        end
    end
    if placer:is_player() then
        machine.owner = placer:get_player_name()
    else
        machine.owner = '*'
    end
    base_mach.write_state(pos, machine)
end

-- used by default instead of the following on_inventory_* callbacks to reduce unnecessary tables
-- change nodedef on_metadata_inventory_* callbacks from this to those if specific event data is needed
function base_mach.simple_inventory_event(pos)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    mach.class.on_inventory_change(mach)
end

function base_mach.on_inventory_move(pos, list_from, index_from, list_to, index_to, count, player)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    mach.class.on_inventory_change(mach, {
        event='move',
        from={list=list_from, index=index_from},
        to={list=list_to, index=index_to},
        count=count,
        player=player
    })
end

function base_mach.on_inventory_take(pos, list, index, stack, player)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    mach.class.on_inventory_change(mach, {
        event='take',
        from={list=list, index=index},
        stack=stack,
        player=player
    })
end

function base_mach.on_inventory_put(pos, list, index, stack, player)
    local mach = base_mach.read_state(pos)
    if not mach then return end
    mach.class.on_inventory_change(mach, {
        event='put',
        to={list=list, index=index},
        stack=stack,
        player=player
    })
end

function base_mach.allow_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0 -- number of items allowed to move
    end
    if listname == "fuel" then
        if opts.BASIC_HEAT_SOURCES[stack:get_name()] then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == 'upgrade' then
        if stack:get_definition()._terumach_upgrade_id then
            return 1
        end
        return 0
    elseif listname == "out" then
        return 0
    else
        return stack:get_count()
    end
end

function base_mach.allow_take(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

function base_mach.allow_move(pos, from_list, from_index, to_list, to_index, count, player)
    --return count
    local stack = minetest.get_meta(pos):get_inventory():get_stack(from_list, from_index)
    return base_mach.allow_put(pos, to_list, to_index, stack, player)
end