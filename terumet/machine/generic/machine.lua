-- contains general functions/attributes applicable to any Terumetal/heat-based machine
terumet.machine = {}
local base_mach = terumet.machine
local opts = terumet.options.machine

local on_machine_node_creation_callbacks = {}
-- define a new callback for machine node creation (for interop)
-- callback is called with params (machine_id, machine_def)
function base_mach.register_on_new_machine_node(cb)
    on_machine_node_creation_callbacks[#on_machine_node_creation_callbacks+1]=cb
end

-- centralized call to define a new machine node
function base_mach.define_machine_node(id, def)
    minetest.register_node(id, def)
    for _,cb in ipairs(on_machine_node_creation_callbacks) do
        cb(id, def)
    end
end

-- events are called with params: (pos, machine, [placer])
local on_machine_place_callbacks = {}
local on_machine_remove_callbacks = {}

function base_mach.register_on_place(event)
    on_machine_place_callbacks[#on_machine_place_callbacks+1]=event
end
function base_mach.register_on_remove(event)
    on_machine_remove_callbacks[#on_machine_remove_callbacks+1]=event
end

function base_mach.heat_pct(machine)
    return 100.0 * base_mach.get_current_heat(machine) / machine.max_heat
end

-- if any other protection mod is not found, then use our own simple owner-based protection
-- this function is called only if any protection mod in terumet.options.protection.EXTERNAL_MODS is not found
local function setup_machine_protection()
    local old_is_protected = minetest.is_protected
    minetest.is_protected = function(pos, name)
        if (not name) or name == '' then return true end
        local node = minetest.get_node_or_nil(pos)
        if node then
            local nodedef = minetest.registered_nodes[node.name]
            if nodedef and nodedef._terumach_class then
                local owner = minetest.get_meta(pos):get_string('owner')
                if (owner == '*') or (owner == name) then
                    return false
                else
                    minetest.chat_send_player(name, "You are not the machine's owner.")
                    minetest.record_protection_violation(pos, name)
                    return true
                end
            end
        end
        return old_is_protected(pos, name)
    end
end

local function find_external_protection_mod()
    local modlist = minetest.get_modnames()
    for _,mod in pairs(modlist) do
        if terumet.options.protection.EXTERNAL_MODS[mod] then
            return true
        end
    end
    return false
end

-- set up machine protection if necessary
if not find_external_protection_mod() then
    setup_machine_protection()
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

local SMOKE_ANIMATION = {
    type='vertical_frames',
    aspect_w=32,
    aspect_h=32,
    length=1.5
}

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

terumet.do_lua_file('machine/generic/formspec')

--
-- GENERIC META
--

-- return a list of {count=number, direction=machine_state, direction=machine_state...} from all adjacent positions
-- where there is a machine w/heat_xfer_mode of ACCEPT and heat_level < max_heat
function base_mach.find_adjacent_need_heat(pos)
    local result = {}
    local count = 0
    for dir,offset in pairs(util3d.ADJACENT_OFFSETS) do
        local opos = util3d.pos_plus(pos, offset)
        local ostate = base_mach.read_state(opos)
        -- read_state returns nil if area unloaded or not a terumetal machine
        if ostate then
            if ostate.heat_xfer_mode == base_mach.HEAT_XFER_MODE.ACCEPT and base_mach.get_current_heat(ostate) < ostate.max_heat then
                result[dir] = ostate
                count = count + 1
            end
        end
    end
    result.count = count
    return result
end

-- given a list of target machines, evenly distribute up to total_hus from 'from' machine to them all
-- update: returns total HUs sent
function base_mach.do_push_heat(from, total_hus, targets)
    local total_distrib = math.min(from.heat_level, total_hus)
    if total_distrib == 0 or #targets == 0 then return nil end
    -- can't afford to even give 1 HU to each target?
    if from.heat_level < #targets then return nil end
    local hus_each = math.floor(total_distrib / #targets)
    local actual_hus_sent = 0
    for i=1,#targets do
        local to_machine = targets[i]
        -- if from and to_machine are the same, don't bother sending any heat
        if not vector.equals(from.pos, to_machine.pos) then
            local send_amount = math.min(hus_each, to_machine.max_heat - base_mach.get_current_heat(to_machine))
            --minetest.chat_send_all(string.format('push to %s hl: %d', to_machine.class.name, send_amount))
            if send_amount > 0 then
                base_mach.external_send_heat(to_machine, send_amount)
                actual_hus_sent = actual_hus_sent + send_amount
            end
        end
    end
    from.heat_level = from.heat_level - actual_hus_sent
    return actual_hus_sent
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
-- update: returns nil if none sent or value of HUs sent
function base_mach.push_heat_single(machine, target, send_amount)
    if send_amount <= 0 then return nil end
    if (target.heat_xfer_mode ~= base_mach.HEAT_XFER_MODE.ACCEPT) or (base_mach.get_current_heat(target) >= target.max_heat) then return nil end
    if base_mach.has_upgrade(machine, 'heat_xfer') then
        send_amount = send_amount * 2
    end
    if base_mach.has_upgrade(target, 'heat_xfer') then
        send_amount = math.floor(send_amount * 1.25)
    end
    return base_mach.do_push_heat(machine, send_amount, {target})
end

local function value_to_sideopts(value)
    if value then
        return value % 10, math.floor(value / 10)
    else
        return opts.DEFAULT_INPUT_SIDE, opts.DEFAULT_OUTPUT_SIDE
    end
end

local function sideopts_to_value(inside, outside)
    return (inside or opts.DEFAULT_INPUT_SIDE) + ((outside or opts.DEFAULT_OUTPUT_SIDE) * 10)
end

local function write_side_options(machine)
    machine.meta:set_int('side_options', sideopts_to_value(machine.input_side, machine.output_side))
end

function base_mach.read_state(pos)
    local machine = {}
    local node_info = minetest.get_node_or_nil(pos)
    if not node_info then return nil end -- unloaded
    machine.nodedef = minetest.registered_nodes[node_info.name]
    if not machine.nodedef then return nil end
    machine.class = machine.nodedef._terumach_class
    if not machine.class then return nil end -- not a terumetal machine
    local meta = minetest.get_meta(pos)
    machine.pos = pos
    machine.meta = meta
    machine.owner = meta:get_string('owner')
    machine.facing = util3d.param2_to_facing(node_info.param2)
    machine.rot = util3d.param2_to_rotation(node_info.param2)
    machine.inv = meta:get_inventory()
    machine.heat_level = meta:get_int('heat_level') or 0
    machine.max_heat = meta:get_int('max_heat') or 0
    machine.heat_xfer_mode = meta:get_int('heat_xfer_mode') or machine.class.default_heat_xfer
    machine.state = meta:get_int('state')
    machine.state_time = meta:get_float('state_time') or 0
    machine.status_text = meta:get_string('status_text') or 'No Status'
    machine.installed_upgrades = base_mach.get_installed_upgrades(machine)
    machine.input_side, machine.output_side = value_to_sideopts(meta:get_int('side_options'))

    -- call read callback on node def if exists
    if machine.class.on_read_state then machine.class.on_read_state(machine) end
    -- following attributes are not saved in meta, but reset every tick
    machine.need_heat = false
    return machine
end

-- this version of read state is intended for a machines tick function
-- updates heat with all pending changes before functioning
function base_mach.tick_read_state(pos)
    local machine = base_mach.read_state(pos)
    base_mach.process_pending_heat(machine)
    return machine
end

-- return simplified list of data of a machine at a specific position
-- intended to be used outside of the machine's tick loop (external nodes)
function base_mach.readonly_state(pos)
    local machine = {}
    local meta = minetest.get_meta(pos)
    local node_info = minetest.get_node_or_nil(pos)
    if not node_info then return nil end -- unloaded
    machine.nodedef = minetest.registered_nodes[node_info.name]
    machine.class = machine.nodedef._terumach_class
    if not machine.class then return nil end -- not a terumetal machine
    machine.heat_xfer_mode = meta:get_int('heat_xfer_mode') or machine.class.default_heat_xfer
    machine.pos = pos
    machine.meta = meta
    machine.inv = meta:get_inventory()
    machine.owner = meta:get_string('owner')
    machine.installed_upgrades = base_mach.get_installed_upgrades(machine)
    machine.input_side, machine.output_side = value_to_sideopts(meta:get_int('side_options'))
    return machine
end

-- WARNING!!
-- THIS FUNCTION SHOULD ONLY BE CALLED BY MACHINE TICK FUNCTION (or on init)
-- per project 'stop race conditions'
function base_mach.write_state(pos, machine)
    local meta = minetest.get_meta(pos)
    meta:set_string('owner', machine.owner)
    meta:set_string('status_text', machine.status_text)
    meta:set_int('heat_level', machine.heat_level or 0)
    meta:set_int('max_heat', machine.max_heat or 0)
    meta:set_int('state', machine.state)
    meta:set_float('state_time', machine.state_time)
    meta:set_string('formspec', base_mach.build_fs(machine))
    meta:set_string('infotext', base_mach.build_infotext(machine))
    write_side_options(machine)
    -- call write callback on node def if exists
    if machine.class.on_write_state then machine.class.on_write_state(machine) end
end

-- get a machine's current heat level plus any pending changes
function base_mach.get_current_heat(machine)
    local pending = machine.meta:get_int('pending_heat_xfer') or 0
    return machine.heat_level + pending
end

-- send heat externally to another machine
function base_mach.external_send_heat(machine, delta)
    if (not machine) or delta == 0 then return false end
    local meta = minetest.get_meta(machine.pos)
    local pending = meta:get_int('pending_heat_xfer') or 0
    pending = pending + delta
    meta:set_int('pending_heat_xfer', pending)
    -- call heat receive callback for node if exists
    if machine.class.on_external_heat then
        machine.class.on_external_heat(machine)
    end
    return true
end

-- update any pending heat transfers (should only be called by machine tick itself)
function base_mach.process_pending_heat(machine)
    local pending = machine.meta:get_int('pending_heat_xfer') or 0
    if pending ~= 0 then
        machine.heat_level = machine.heat_level + pending
        machine.meta:set_int('pending_heat_xfer', 0)
    end
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
    if base_mach.has_ext_output(machine) then
        local input_pos = util3d.get_relative_pos(machine.rot, machine.pos, machine.input_side)
        local lmeta = minetest.get_meta(input_pos)
        if lmeta then return lmeta:get_inventory(), 'main' end
        return nil, nil
    else
        return machine.inv, 'in'
    end
end

-- return inventory, list of where to put output
function base_mach.get_output(machine)
    if base_mach.has_ext_output(machine) then
        local output_pos = util3d.get_relative_pos(machine.rot, machine.pos, machine.output_side)
        local rmeta = minetest.get_meta(output_pos)
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

function base_mach.has_ext_input(machine)
    return base_mach.has_upgrade(machine, 'ext_input') or base_mach.has_upgrade(machine, 'ext_both')
end

function base_mach.has_ext_output(machine)
    return base_mach.has_upgrade(machine, 'ext_output') or base_mach.has_upgrade(machine, 'ext_both')
end

function base_mach.has_external(machine)
    return base_mach.has_upgrade(machine, 'ext_both') or base_mach.has_upgrade(machine, 'ext_input') or base_mach.has_upgrade(machine, 'ext_output')
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

    if base_mach.has_upgrade(machine, 'cheat') then
        machine.heat_level = machine.max_heat
        return false
    end

    if machine.heat_level > machine.max_heat then
        base_mach.generate_smoke(machine.pos, 8)
        if opts.OVERHEAT_SOUND then
            minetest.sound_play( opts.OVERHEAT_SOUND, {
                pos = machine.pos,
                gain = 0.7,
                max_hear_distance = 16
            })
        end
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

-- handle basic fuel heating
function base_mach.process_fuel(machine)
    local fuel_item = machine.inv:get_stack('fuel',1)
    local heat_source = opts.BASIC_HEAT_SOURCES[fuel_item:get_name()]
    local hu_value = 0
    if heat_source then
        hu_value = heat_source.hus
    end
    if heat_source and (machine.max_heat - machine.heat_level) >= hu_value then
        local out_inv, out_list = base_mach.get_output(machine)
        local return_item = heat_source.return_item
        if fuel_item:get_stack_max() > 1 then
            if (not return_item) or out_inv:room_for_item(out_list, return_item) then
                out_inv:add_item(out_list, return_item)
            else
                machine.status_text = 'Heat Input: no return space for ' .. minetest.registered_items[return_item].description
                return
            end
            machine.inv:remove_item('fuel', fuel_item:get_name())
        else
            machine.inv:set_stack('fuel', 1, return_item)
        end
        machine.heat_level = math.min(machine.max_heat, machine.heat_level + hu_value)
        machine.need_heat = false
        if opts.HEATIN_SOUND then
            minetest.sound_play( opts.HEATIN_SOUND, {
                pos = machine.pos,
                gain = 0.2,
                max_hear_distance = 4,
            })
        end
    end
end

-- handle battery filling
function base_mach.process_battery(machine)
    local slot_item = machine.inv:get_stack('battery', 1)
    if slot_item then
        local binfo = slot_item:get_definition()._empty_battery_info
        if binfo then
            if binfo.void then
                machine.heat_level = 0
            elseif machine.heat_level >= binfo.fill then
                machine.inv:set_stack('battery', 1, binfo.change_to) -- batteries are expected to be 1-stacks only
                machine.heat_level = machine.heat_level - binfo.fill
                if opts.HEATOUT_SOUND then
                    minetest.sound_play( opts.HEATOUT_SOUND, {
                        pos = machine.pos,
                        gain = 0.2,
                        max_hear_distance = 4,
                    })
                end
            end
        end
    end
end

-- handle expending heat
-- returns true if successful, false if not enough heat
-- automatically sets need_heat and "low heat message" if fails
function base_mach.expend_heat(machine, value, process)
    if base_mach.has_upgrade(machine, 'cheat') then return true end
    value = math.floor(value)
    if machine.heat_level < value then
        base_mach.set_low_heat_msg(machine, process)
        machine.need_heat = true
        return false
    end
    machine.heat_level = machine.heat_level - value
    return true
end

-- for use by machine itself ONLY
-- use external_send_heat for outside machine
function base_mach.gain_heat(machine, value)
    value = math.floor(value)
    machine.heat_level = math.min(machine.max_heat, machine.heat_level + value)
end

function base_mach.generate_particle(pos, data, count)
    if not opts.PARTICLES then return end
    count = count or 1
    data = data or terumet.EMPTY
    for _ = 1,count do
        local px = pos.x + (terumet.RAND:next(-5,5) / 10)
        local py = pos.y + 0.5 + (terumet.RAND:next(0,100) / 250)
        local pz = pos.z + (terumet.RAND:next(-5,5) / 10)
        local sz = data.size or (terumet.RAND:next(50,400) / 100)
        local vel = {x=0,y=0,z=0}
        if data.velocity then
            vel.x = data.velocity.x or 0
            vel.y = data.velocity.y or 0
            vel.z = data.velocity.z or 0
        end
        if data.randvel_xz then
            vel.x = vel.x + (terumet.RAND:next(-data.randvel_xz,data.randvel_xz) / 10)
            vel.z = vel.z + (terumet.RAND:next(-data.randvel_xz,data.randvel_xz) / 10)
        end
        if data.randvel_y then
            vel.y = vel.y + (terumet.RAND:next(-data.randvel_y,data.randvel_y) / 10)
        end
        minetest.add_particle{
            pos={x=px, y=py, z=pz},
            velocity=vel,
            acceleration=data.acceleration or terumet.ZERO_XYZ,
            expirationtime=data.expiration or 1.0,
            size=sz,
            collisiondetection = false,
            texture = data.texture,
            playername = data.playername,
            animation = data.animation,
            glow = data.glow
        }
    end
end

function base_mach.generate_smoke(pos, count)
    if not opts.PARTICLES then return end
    count = count or 1
    for _ = 1,count do
        local px = pos.x + (terumet.RAND:next(-5,5) / 10)
        local py = pos.y + 0.5 + (terumet.RAND:next(0,100) / 250)
        local pz = pos.z + (terumet.RAND:next(-5,5) / 10)
        local sz = terumet.RAND:next(100,400) / 100
        local vel = terumet.RAND:next(2,5) / 10
        local acc = terumet.RAND:next(4,10) / 10
        minetest.add_particle{
            pos={x=px, y=py, z=pz},
            velocity={x=0, y=vel, z=0},
            acceleration={x=0, y=acc, z=0},
            expirationtime=1.41,
            size=sz,
            collisiondetection=false,
            texture=string.format('terumet_part_smoke%d.png', terumet.RAND:next(1,3)),
            animation=SMOKE_ANIMATION
        }
    end
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

-- returns nil if not a machine or does not have that property
function base_mach.get_class_property(nodename, prop)
    local ndef = minetest.registered_nodes[nodename]
    if ndef then
        if ndef._terumach_class then
            return ndef._terumach_class[prop]
        end
    end
    return nil
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
        groups = {cracky=2},
        drop = '', -- since after_dig_node/on_destruct/on_blast handles machines dropping w/stored heat, flag machines as ignoring usual drop mechanic
        -- default inventory slot control
        allow_metadata_inventory_put = base_mach.allow_put,
        allow_metadata_inventory_move = base_mach.allow_move,
        allow_metadata_inventory_take = base_mach.allow_take,
        -- default callbacks
        can_dig = function(pos, user)
            if user and user:is_player() then
                return not minetest.is_protected(pos, user:get_player_name())
            else
                return false
            end
        end,
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
                if not minetest.is_protected(machine.pos, player_name) then
                    local updatefs = false
                    -- handle default buttondefs
                    if fields.hxfer_toggle then
                        if machine.heat_xfer_mode == machine.class.default_heat_xfer then
                            machine.heat_xfer_mode = base_mach.HEAT_XFER_MODE.NO_XFER
                        else
                            machine.heat_xfer_mode = machine.class.default_heat_xfer
                        end
                        machine.meta:set_int('heat_xfer_mode', machine.heat_xfer_mode)
                        updatefs = true
                    elseif fields.input_side then
                        machine.input_side = machine.input_side + 1
                        if machine.input_side > 6 then machine.input_side = 1 end
                        write_side_options(machine)
                        updatefs = true
                    elseif fields.output_side then
                        machine.output_side = machine.output_side + 1
                        if machine.output_side > 6 then machine.output_side = 1 end
                        write_side_options(machine)
                        updatefs = true
                    else
                        -- handle machine custom buttondefs
                        -- return true to flag formspec should be updated
                        if machine.class.on_form_action then
                            updatefs = machine.class.on_form_action(machine, fields, player_name)
                        end
                    end
                    if updatefs then
                        machine.meta:set_string('formspec', base_mach.build_fs(machine))
                        base_mach.set_timer(machine)
                    end
                end
            end
        end,
        -- callbacks for saving/loading heat level
        after_dig_node = base_mach.after_dig_machine,
        after_place_node = base_mach.after_place_machine,
        -- terumetal machine class
        _terumach_class = {
            -- dummy property to allow get_class_property(nodename, 'is_machine')
            is_machine = true,
            -- should be false for heatline input machine
            heatline_target = true,
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
            end,
            -- on_place
            on_place = function(pos, machine, placer)
            end,
            -- on_remove
            on_remove = function(pos, machine)
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
    if new_nodedef._terumach_class.heatline_target then
        -- if node is a heatline target, add group to allow heatlines to connect
        new_nodedef.groups['terumet_hltarget']=1
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
    -- event callbacks
    mach.class.on_remove(pos, mach)
    for _,event in ipairs(on_machine_remove_callbacks) do
        event(pos, mach)
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
    local drop_id = base_mach.get_class_property(oldnode.name,'drop_id') or oldnode.name
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
    if placer and placer:is_player() then
        machine.owner = placer:get_player_name()
    else
        machine.owner = '*'
    end
    -- event callbacks
    machine.class.on_place(pos, machine, placer)
    for _,event in ipairs(on_machine_place_callbacks) do
        event(pos, machine, placer)
    end
    -- init default meta settings
    local meta = minetest.get_meta(pos)
    meta:set_int('pending_heat_xfer', 0) -- just in case of an exploit
    meta:set_int('heat_xfer_mode', machine.class.default_heat_xfer)
    -- write final initial state
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
        -- deny based on protection
        return 0 -- number of items allowed to move
    end
    if listname == 'fuel' then
        -- only allow fuel items into fuel slot
        if opts.BASIC_HEAT_SOURCES[stack:get_name()] then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == 'battery' then
        -- only allow empty batteries in battery slot
        if stack:get_definition()._empty_battery_info then
            return 1
        end
        return 0
    elseif listname == 'upgrade' then
        -- deny insert immediately if target upgrade slot is not empty
        if not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then return 0 end
        -- only allow upgrade items into upgrade slot
        if stack:get_definition()._terumach_upgrade_id then
            return 1
        end
        return 0
    elseif listname == "out" then
        -- deny insertion into output slots
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