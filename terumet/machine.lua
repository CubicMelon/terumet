-- contains general functions/attributes applicable to any Terumetal/heat-based machine
terumet.machine = {}
local base_mach = terumet.machine
local opts = terumet.options.machine

function base_mach.heat_pct(machine)
    return 100.0 * machine.heat_level / opts.FULL_HEAT
end

--
-- GENERIC FORMSPECS
--

-- general preamble setting background, colors
base_mach.fs_start = 'background[0,0;8,9;terumet_gui_bg.png;true]listcolors[#3a101b;#905564;#190309;#114f51;#d2fdff]'

-- fuel slot formspec (only if necessary)
function base_mach.fs_fuel_slot(machine, fsx, fsy)
    if machine.need_heat or (not machine.inv:is_empty('fuel')) then
        return 'list[context;fuel;'..fsx..','..fsy..';1,1;]label['..fsx..','..fsy+1 ..';Fuel Slot]'
    end
    return ''
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

function base_mach.read_state(pos)
    local machine = {}
    local meta = minetest.get_meta(pos)
    machine.meta = meta
    machine.inv = meta:get_inventory()
    machine.heat_level = meta:get_int('heat_level') or 0
    machine.hus_spent = meta:get_int('hus_spent') or 0
    machine.state = meta:get_int('state')
    machine.state_time = meta:get_float('state_time') or 0
    machine.status_text = meta:get_string('status_text') or 'No Status'
    -- following attributes are not saved in meta, but reset every tick
    machine.need_heat = false
    return machine
end

function base_mach.write_state(pos, machine, formspec, infotext)
    local meta = minetest.get_meta(pos)
    meta:set_string('formspec', formspec)
    meta:set_string('infotext', infotext)
    meta:set_string('status_text', machine.status_text)
    meta:set_int('heat_level', machine.heat_level)
    meta:set_int('hus_spent', machine.hus_spent)
    meta:set_int('state', machine.state)
    meta:set_float('state_time', machine.state_time)
end

--
-- GENERIC MACHINE PROCESSES
--

function base_mach.set_low_heat_msg(machine, process)
    local fuel_item_desc = minetest.registered_items[opts.FUEL_ITEM].description
    if process then
        machine.status_text = process .. ': Insufficient heat - fuel with ' .. fuel_item_desc
    else
        machine.status_text = 'Insufficient heat - fuel with ' .. fuel_item_desc
    end
end

-- handle reheating input
function base_mach.process_fuel(machine)
    if machine.need_heat then
        if machine.inv:contains_item('fuel', opts.FUEL_ITEM) then
            if machine.inv:room_for_item('out', opts.FUEL_RETURN) then
                machine.inv:remove_item('fuel', opts.FUEL_ITEM)
                machine.inv:add_item('out', opts.FUEL_RETURN)
                machine.heat_level = opts.FULL_HEAT
                machine.need_heat = false
            else
                machine.status_text = 'No space for '..minetest.registered_items[opts.FUEL_RETURN].description
            end
        else
            base_mach.set_low_heat_msg(machine)
        end
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
    machine.hus_spent = machine.hus_spent + value
    while machine.hus_spent >= opts.FULL_HEAT do
        machine.hus_spent = machine.hus_spent - opts.FULL_HEAT
        machine.inv:add_item('fuel', opts.FUEL_CYCLE)
    end
    return true
end

--
-- GENERIC CALLBACKS
--

function base_mach.allow_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0 -- number of items allowed to move
    end
    if listname == "fuel" then
        if stack:get_name() == opts.FUEL_ITEM then
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