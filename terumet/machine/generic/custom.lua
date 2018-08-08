local base_opts = terumet.options.machine
local base_mach = terumet.machine

local base_cust = {}

-- state identifier consts
base_cust.STATE = {}
base_cust.STATE.IDLE = 0
base_cust.STATE.PROCESSING = 1

function base_cust.generate_formspec(machine)
    local cust_data = machine.class.cust
    local fs = 'size[8,9]'..(cust_data.pre_formspec or base_mach.fs_start)..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    base_mach.fs_owner(machine,5,0)..
    --input inventory
    'list[context;in;0,1.5;2,2;]'..
    'label[0.5,3.5;Input Slots]'..
    --output inventory
    'list[context;out;6,1.5;2,2;]'..
    'label[6.5,3.5;Output Slots]'..
    --fuel slot
    base_mach.fs_fuel_slot(machine,6.5,0)..
    --current status
    'label[0,0;'..cust_data.name..']'..
    'label[0,0.5;' .. machine.status_text .. ']'..
    base_mach.fs_heat_info(machine,4.25,1.5)..
    base_mach.fs_heat_mode(machine,4.25,4)
    if machine.state == base_cust.STATE.PROCESSING then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..machine.inv:get_stack('result',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;in]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function base_cust.generate_infotext(machine)
    return string.format('%s (%.1f%% heat): %s', machine.class.cust.name, base_mach.heat_pct(machine), machine.status_text)
end

function base_cust.init(pos, terumachine_class)
    local cust_data = terumachine_class.cust
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('in', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)

    local init_machine = {
        class = terumachine_class,
        state = base_cust.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = cust_data.max_heat_base,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.ACCEPT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_machine)
end

function base_cust.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, "fuel", drops)
    default.get_inventory_drops(machine.pos, "in", drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    return drops
end

function base_cust.do_processing(machine, dt)
    local cust_data = machine.class.cust
    local proc_desc = cust_data.process_desc or 'Processing'
    if machine.state == base_cust.STATE.PROCESSING and base_mach.expend_heat(machine, cust_data.heat_per_tick, proc_desc) then
        local result_stack = machine.inv:get_stack('result', 1)
        local result_name = result_stack:get_definition().description
        machine.state_time = machine.state_time - dt
        if machine.state_time <= 0 then
            if machine.inv:room_for_item('out', result_stack) then
                machine.inv:set_stack('result', 1, nil)
                machine.inv:add_item('out', result_stack)
                machine.state = base_cust.STATE.IDLE
                if cust_data.after_process_func then
                    cust_data.after_process_func(machine.inv)
                end
            else
                machine.status_text = result_name .. ' ready - no space!'
                machine.state_time = -0.1
            end
        else
            machine.status_text = string.format('%s %s (%s)', proc_desc, result_name, terumet.format_time(machine.state_time))
        end
    end
end

function base_cust.check_new_processing(machine)
    if machine.state ~= base_cust.STATE.IDLE then return end
    local cust_data = machine.class.cust
    local process_results = cust_data.process_func(machine.inv)
    if process_results then
        if type(process_results) ~= 'table' then
            error('Custom machine process_func returned a non-table value')
        end
        if not process_results.output then
            error('Custom machine process_func returned a table but no "output" in table')
        end
        machine.state = base_cust.STATE.PROCESSING
        machine.inv:set_stack('result', 1, process_results.output)
        machine.state_time = process_results.time or 1.0
        machine.status_text = process_results.desc or 'Beginning processing...'
        return
    end
    machine.status_text = 'Idle'
end

function base_cust.tick(pos, dt)
    -- read state from meta
    local machine = base_mach.tick_read_state(pos)

    base_cust.do_processing(machine, dt)

    base_cust.check_new_processing(machine)

    base_mach.process_fuel(machine)

    if machine.state ~= base_cust.STATE.IDLE and (not machine.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        base_mach.set_timer(machine)
        base_mach.generate_smoke(pos)
    end

    -- write status back to meta
    base_mach.write_state(pos, machine)
end

terumet.machine.custom = base_cust