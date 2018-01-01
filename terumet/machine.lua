-- contains functions applicable to any Terumetal/heat-based machine
terumet.machine = {}
local mach = terumet.machine
local opts = terumet.options.machine

function mach.heat_pct(machine)
    return 100.0 * machine.heat_level / opts.FULL_HEAT
end

mach.fs_gui_bg = 'background[0,0;8,9;terumet_gui_bg.png;true]listcolors[#3a101b;#905564;#190309;#114f51;#d2fdff]'

function mach.fs_fuel_slot(machine, fsx, fsy)
    -- show fuel slot only if needed
    if machine.heat_level == 0 or (not machine.inv:is_empty('fuel')) then
        return 'list[context;fuel;'..fsx..','..fsy..';1,1;]label['..fsx..','..fsy+1 ..';Fuel Slot]'
    end
    return ''
end

function mach.fs_heat_info(machine, fsx, fsy)
    return 'image['..fsx..','..fsy..';2,2;terumet_gui_heat_bg.png^[lowpart:'..
    mach.heat_pct(machine)..':terumet_gui_heat_fg.png]label['..fsx..','..fsy+2 ..';Heat Level]'
end

function mach.fs_flux_info(machine, fsx, fsy, percent)
    return 'image['..fsx..','..fsy..';2,2;terumet_gui_flux_bg.png^[lowpart:'..
    percent..':terumet_gui_flux_fg.png]label['..fsx..','..fsy+2 ..';Molten Flux]'
end

function mach.fs_player_inv(fsx, fsy)
    return 'list[current_player;main;'..fsx..','..fsy..';8,1;]list[current_player;main;'..fsx..','..fsy+1.25 ..';8,3;8]'
end

function mach.process_fuel(machine)
    if machine.inv:contains_item('fuel', opts.FUEL_ITEM) then
        if machine.inv:room_for_item('out', opts.FUEL_RETURN) then
            machine.inv:remove_item('fuel', opts.FUEL_ITEM)
            machine.inv:add_item('out', opts.FUEL_RETURN)
            machine.heat_level = opts.FULL_HEAT
        else
            machine.status_text = 'No space for '..minetest.registerd_items[opts.FUEL_ITEM].description
        end
    else
        machine.status_text = 'Need heat ('..minetest.registered_items[opts.FUEL_ITEM].description..')'
    end
end

function mach.expend_heat(machine, value)
    machine.heat_level = math.max(0, machine.heat_level - value)
end

function mach.heat_exhausted(machine)
    -- expel the fuel finish item (cobblestone by default)
    -- no need to check if fuel slot is empty because in normal usage it's been hidden since last fueling
    machine.inv:set_stack('fuel', 1, opts.FUEL_COMPLETE)
end

function mach.allow_put(pos, listname, index, stack, player)
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

function mach.allow_take(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

function mach.allow_move(pos, from_list, from_index, to_list, to_index, count, player)
    --return count
    local stack = minetest.get_meta(pos):get_inventory():get_stack(from_list, from_index)
    return mach.allow_put(pos, to_list, to_index, stack, player)
end