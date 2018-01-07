-- contains general functions/attributes applicable to any Terumetal/heat-based machine
terumet.machine = {}
local base_mach = terumet.machine
local opts = terumet.options.machine

function base_mach.heat_pct(machine)
    return 100.0 * machine.heat_level / machine.max_heat
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

-- general preamble setting background, colors
base_mach.fs_start = 'background[0,0;8,9;terumet_gui_bg.png;true]listcolors[#3a101b;#905564;#190309;#114f51;#d2fdff]'

-- fuel slot formspec
function base_mach.fs_fuel_slot(machine, fsx, fsy)
    return 'list[context;fuel;'..fsx..','..fsy..';1,1;]label['..fsx..','..fsy+1 ..';Fuel Slot]'
end

-- heat display formspec
function base_mach.fs_heat_info(machine, fsx, fsy)
    return 'image['..fsx..','..fsy..';2,2;terumet_gui_heat_bg.png^[lowpart:'..
    base_mach.heat_pct(machine)..':terumet_gui_heat_fg.png]label['..fsx..','..fsy+2 ..';Heat Level]'
end

-- flux display formspec
function base_mach.fs_flux_info(machine, fsx, fsy, percent)
    return 'image['..fsx..','..fsy..';2,2;terumet_gui_flux_bg.png^[lowpart:'..
    percent..':terumet_gui_flux_fg.png]label['..fsx..','..fsy+2 ..';Molten Flux]'
end

-- player inventory formspec
function base_mach.fs_player_inv(fsx, fsy)
    return 'list[current_player;main;'..fsx..','..fsy..';8,1;]list[current_player;main;'..fsx..','..fsy+1.25 ..';8,3;8]'
end

--
-- GENERIC META
--
-- constants for interactive heat behavior of machines
base_mach.HEAT_XFER_MODE= {
    IGNORE=0, -- default if not specified
    ACCEPT=1,
    PROVIDE_ONLY=2,
}

base_mach.ADJACENT_OFFSETS = {
    east={x=1,y=0,z=0}, west={x=-1,y=0,z=0},
    up={x=0,y=1,z=0}, down={x=0,y=-1,z=0},
    north={x=0,y=0,z=1}, south={x=0,y=0,z=-1}
}

-- return a list of {count=number, direction=machine_state, direction=machine_state...} from all adjacent positions 
-- where there is a machine w/heat_xfer_mode of ACCEPT and heat_level < max_heat
function base_mach.find_adjacent_need_heat(pos)
    local result = {}
    local count = 0
    for dir,offset in pairs(base_mach.ADJACENT_OFFSETS) do
        local opos = {x=pos.x+offset.x, y=pos.y+offset.y, z=pos.z+offset.z}
        local ostate = base_mach.read_state(opos)
        -- read_state returns nil if area unloaded or not a terumetal machine
        if ostate then 
            if ostate.heat_xfer_mode == base_mach.HEAT_XFER_MODE.ACCEPT and ostate.heat_level < ostate.max_heat then
                result[dir] = ostate
                count = count + 1
            end
        end
    end
    minetest.chat_send_all('found ' .. count .. ' adjacent machines that accept and need heat')
    result.count = count
    return result
end

function base_mach.push_heat(from, total_hus, targets)
    if from.heat_level < total_hus then return end
    if #targets == 0 then return end
    -- can't afford to even give 1 HU to each target?
    if from.heat_level < #targets then return end
    local total_distrib = math.min(from.heat_level, total_hus)
    local hus_each = math.floor(total_distrib / #targets)
    local actual_hus_sent = 0
    for i=1,#targets do
        local to_machine = targets[i]
        local send_amount = math.min(hus_each, to_machine.max_heat - to_machine.heat_level)
        if send_amount > 0 then
            to_machine.heat_level = to_machine.heat_level + send_amount
            -- call heat receive callback for node if exists
            if to_machine.class_on_external_heat then
                to_machine.class.on_external_heat(to_machine)
            end
            base_mach.write_state(to_machine.pos, to_machine)
            actual_hus_sent = actual_hus_sent + send_amount
        end
    end
    from.heat_level = from.heat_level - actual_hus_sent
end

-- find all adjacent accepting machines and push desired amount of heat to them, split evenly
function base_mach.push_heat_adjacent(machine, hus)
    if hus == 0 or hus > machine.heat_level then return end
    local adjacent_needy = base_mach.find_adjacent_need_heat(machine.pos)
    if adjacent_needy.count > 0 then
        local send_targets = {}
        for dir, target in pairs(adjacent_needy) do
            if dir ~= 'count' then send_targets[#send_targets+1] = target end
        end
        base_mach.push_heat(machine, hus, send_targets)
    end
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
    machine.inv = meta:get_inventory()
    machine.heat_level = meta:get_int('heat_level') or 0
    machine.max_heat = meta:get_int('max_heat') or 0
    machine.heat_xfer_mode = meta:get_int('heat_xfer_mode')
    machine.state = meta:get_int('state')
    machine.state_time = meta:get_float('state_time') or 0
    machine.status_text = meta:get_string('status_text') or 'No Status'
    -- call read callback on node def if exists
    if machine.class.on_read_state then machine.class.on_read_state(machine) end
    -- following attributes are not saved in meta, but reset every tick
    machine.need_heat = false
    return machine
end

function base_mach.write_state(pos, machine)
    local meta = minetest.get_meta(pos)
    meta:set_string('status_text', machine.status_text)
    meta:set_int('heat_level', machine.heat_level or 0)
    meta:set_int('max_heat', machine.max_heat or 0)
    meta:set_int('heat_xfer_mode', machine.heat_xfer_mode or base_mach.HEAT_XFER_MODE.IGNORE)
    meta:set_int('state', machine.state)
    meta:set_float('state_time', machine.state_time)
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

function base_mach.set_timer(machine)
    minetest.get_node_timer(machine.pos):start(machine.class.timer)
end

function base_mach.set_low_heat_msg(machine, process)
    if process then
        machine.status_text = process .. ': Insufficient heat'
    else
        machine.status_text = 'Insufficient heat'
    end
end

-- handle basic fuel heating
function base_mach.process_fuel(machine)
    local fuel_item = machine.inv:get_stack('fuel',1)
    local heat_source = opts.basic_heat_sources[fuel_item:get_name()]
    if heat_source and (machine.max_heat - machine.heat_level) >= heat_source.hus then
        local return_item = heat_source.return_item
        if fuel_item:get_stack_max() > 1 then
            if (not return_item) or machine.inv:room_for_item('out', return_item) then
                machine.inv:add_item('out', return_item)
            else
                machine.status_text = 'Fuel: no space for ' .. minetest.registered_items[return_item].description
                return
            end
            machine.inv:remove_item('fuel', fuel_item:get_name())
        else
            machine.inv:set_stack('fuel', 1, return_item)
        end
        machine.heat_level = math.min(machine.max_heat, machine.heat_level + heat_source.hus)
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

base_mach.RAND = PcgRandom(os.time())

function base_mach.generate_particle(pos, particle_tex)
    if not opts.PARTICLES then return end
    local xoff = base_mach.RAND:next(-5,5) / 10
    local zoff = base_mach.RAND:next(-5,5) / 10
    local sz = base_mach.RAND:next(50,400) / 100
    local vel = base_mach.RAND:next(2,5) / 10
    minetest.add_particle{
        pos={x=pos.x+xoff, y=pos.y+0.5, z=pos.z+zoff},
        velocity={x=0, y=vel, z=0},
        acceleration={x=0, y=0.6, z=0},
        expirationtime=1.5,
        size=sz,
        collisiondetection=false,
        texture=(particle_tex or 'default_item_smoke.png')
    }
end

--
-- GENERIC CALLBACKS
--

function base_mach.allow_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0 -- number of items allowed to move
    end
    if listname == "fuel" then
        if opts.basic_heat_sources[stack:get_name()] then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == "inp" then
        return stack:get_count()
    else
        return 0
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