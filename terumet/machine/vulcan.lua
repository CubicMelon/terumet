local opts = terumet.options.vulcan
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_vul = {}
base_vul.id = terumet.id('mach_vulcan')

-- state identifier consts
base_vul.STATE = {}
base_vul.STATE.IDLE = 0
base_vul.STATE.VULCANIZING = 1

function base_vul.generate_formspec(vulcan)
    local fs = 'size[10,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    base_mach.fs_owner(vulcan,5,0)..
    --input inventory
    base_mach.fs_input(vulcan,0,1.5,2,2)..
    --output inventory
    base_mach.fs_output(vulcan,6,1.5,2,2)..
    --fuel slot
    base_mach.fs_fuel_slot(vulcan,6.5,0)..
    --upgrade slots
    base_mach.fs_upgrades(vulcan,8.75,1)..
    --current status
    'label[0,0;Crystal Vulcanizer]'..
    'label[0,0.5;' .. vulcan.status_text .. ']'..
    base_mach.fs_heat_info(vulcan,4.25,1.5)..
    base_mach.fs_heat_mode(vulcan,4.25,4)
    if vulcan.state == base_vul.STATE.VULCANIZING then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..vulcan.inv:get_stack('result',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;in]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function base_vul.generate_infotext(vulcan)
    return string.format('Crystal Vulcanizer (%.1f%% heat): %s', base_mach.heat_pct(vulcan), vulcan.status_text)
end

function base_vul.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('in', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)
    inv:set_size('upgrade', 4)

    local init_vulcan = {
        class = base_vul.nodedef._terumach_class,
        state = base_vul.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.ACCEPT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_vulcan)
end

function base_vul.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, "fuel", drops)
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function base_vul.do_processing(vulcan, dt)
    if vulcan.state == base_vul.STATE.VULCANIZING and base_mach.expend_heat(vulcan, vulcan.heat_cost, 'Vulcanizing') then
        local result_stack = vulcan.inv:get_stack('result', 1)
        local result_name = result_stack:get_definition().description
        vulcan.state_time = vulcan.state_time - dt
        if vulcan.state_time <= 0 then
            local out_inv, out_list = base_mach.get_output(vulcan)
            if out_inv then
                if out_inv:room_for_item(out_list, result_stack) then
                    vulcan.inv:set_stack('result', 1, nil)
                    out_inv:add_item(out_list, result_stack)
                    vulcan.state = base_vul.STATE.IDLE
                else
                    vulcan.status_text = result_name .. ' ready - no output space!'
                    vulcan.state_time = -0.1
                end
            else
                vulcan.status_text = 'No output'
                vulcan.state_time = -0.1
            end
        else
            vulcan.status_text = 'Creating ' .. result_name .. ' (' .. terumet.format_time(vulcan.state_time) .. ')'
        end
    end
end

function base_vul.check_new_processing(vulcan)
    if vulcan.state ~= base_vul.STATE.IDLE then return end
    local in_inv, in_list = base_mach.get_input(vulcan)
    local cook_result
    for slot = 1,in_inv:get_size(in_list) do
        local input_stack = in_inv:get_stack(in_list, slot)
        local matched_recipe = opts.recipes[input_stack:get_name()]
        if matched_recipe then
            local yield = 2
            vulcan.state = base_vul.STATE.VULCANIZING
            vulcan.state_time = opts.PROCESS_TIME
            vulcan.heat_cost = opts.COST_VULCANIZE
            if base_mach.has_upgrade(vulcan, 'cryst') then 
                yield = yield + 1
                vulcan.state_time = vulcan.state_time * 3
                vulcan.heat_cost = vulcan.heat_cost * 2
            end
            in_inv:remove_item(in_list, input_stack:get_name())
            vulcan.inv:set_stack('result', 1, matched_recipe .. ' ' .. yield)
            if base_mach.has_upgrade(vulcan, 'speed_up') then vulcan.state_time = vulcan.state_time / 2 end
            vulcan.status_text = 'Accepting ' .. input_stack:get_definition().description .. ' for vulcanizing...'
            return
        end
    end
    vulcan.status_text = 'Idle'
end

function base_vul.tick(pos, dt)
    -- read state from meta
    local vulcan = base_mach.read_state(pos)
    local venting

    if base_mach.check_heat_max(vulcan, opts.MAX_HEAT) then
        venting = true
    else
        base_vul.do_processing(vulcan, dt)
        base_vul.check_new_processing(vulcan)
        base_mach.process_fuel(vulcan)
    end

    if vulcan.state ~= base_vul.STATE.IDLE and (not vulcan.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        base_mach.set_timer(vulcan)
    elseif venting or base_mach.has_upgrade(vulcan, 'ext_input') then
        base_mach.set_timer(vulcan)
    end

    -- write status back to meta
    base_mach.write_state(pos, vulcan)

end

base_vul.nodedef = base_mach.nodedef{
    -- node properties
    description = "Crystal Vulcanizer",
    tiles = {
        terumet.tex('vulcan_top'), terumet.tex('block_ceramic'),
        terumet.tex('vulcan_sides'), terumet.tex('vulcan_sides'),
        terumet.tex('vulcan_sides'), terumet.tex('vulcan_sides')
    },
    -- callbacks
    on_construct = base_vul.init,
    on_timer = base_vul.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Crystal Vulcanizer',
        timer = 0.5,
        get_drop_contents = base_vul.get_drop_contents,
        on_read_state = function(vulcan)
            vulcan.heat_cost = vulcan.meta:get_int('heatcost') or 0
        end,
        on_write_state = function(vulcan)
            vulcan.meta:set_string('formspec', base_vul.generate_formspec(vulcan))
            vulcan.meta:set_string('infotext', base_vul.generate_infotext(vulcan))
            vulcan.meta:set_int('heatcost', vulcan.heat_cost or 0)
        end
    }
}

minetest.register_node(base_vul.id, base_vul.nodedef)

minetest.register_craft{ output = base_vul.id, recipe = {
    {terumet.id('item_coil_tgol'), terumet.id('item_coil_tgol'), terumet.id('item_coil_tgol')},
    {terumet.id('item_thermese'), terumet.id('frame_tste'), terumet.id('item_thermese')},
    {terumet.id('item_ceramic'), terumet.id('block_ceramic'), terumet.id('item_ceramic')}
}}