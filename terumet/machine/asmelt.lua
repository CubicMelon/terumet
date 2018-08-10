local opts = terumet.options.smelter
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_asm = {}
base_asm.unlit_id = terumet.id('mach_asmelt')
base_asm.lit_id = terumet.id('mach_asmelt_lit')

-- state identifier consts
base_asm.STATE = {}
base_asm.STATE.IDLE = 0
base_asm.STATE.FLUX_MELT = 1
base_asm.STATE.ALLOYING = 2

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
        {flag='zero_flux_recipes', icon='default_bronze_ingot.png', name='zfr_toggle', on_text='Using zero flux recipes', off_text='Ignoring zero flux recipes'}
    },
    machine = function(machine)
        local fs = base_mach.fs_meter(2.5,1, 'flux', 100*machine.flux_tank/opts.FLUX_MAXIMUM, string.format('%d flux', machine.flux_tank))
        if machine.state == base_asm.STATE.FLUX_MELT then
            fs=fs..base_mach.fs_proc(3,2,'melt',machine.inv:get_stack('result',1))
        elseif machine.state == base_asm.STATE.ALLOYING then
            fs=fs..base_mach.fs_proc(3,2,'alloy',machine.inv:get_stack('result',1))
        end
        return fs
    end,
    input = {true},
    output = {true},
    fuel_slot = {true},
}

local FORM_ACTION = function(asmelt, fields, player)
    if fields.zfr_toggle then
        asmelt.zero_flux_recipes = not asmelt.zero_flux_recipes
        asmelt.meta:set_int('opt_zfr', (asmelt.zero_flux_recipes and 1) or 0)
        return true -- update formspec
    end
end

function base_asm.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('in', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)
    inv:set_size('upgrade', 4)

    local init_smelter = {
        class = base_asm.unlit_nodedef._terumach_class,
        flux_tank = 0,
        zero_flux_recipes = true,
        state = base_asm.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos,
    }
    base_mach.write_state(pos, init_smelter)
end

function base_asm.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, "fuel", drops)
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    local flux_tank = machine.meta:get_int('flux_tank') or 0
    if flux_tank > 0 then
        drops[#drops+1] = terumet.id('item_cryst_raw', math.min(99, flux_tank))
    end
    return drops
end

function base_asm.do_processing(smelter, dt)
    local speed_mult = 1
    if base_mach.has_upgrade(smelter, 'speed_up') then speed_mult = 2 end

    if smelter.state == base_asm.STATE.FLUX_MELT and base_mach.expend_heat(smelter, opts.COST_FLUX_MELTING_HU * speed_mult, 'Melting flux') then
        smelter.state_time = smelter.state_time - (dt * speed_mult)
        if smelter.state_time <= 0 then
            smelter.flux_tank = smelter.flux_tank + 1
            smelter.inv:set_stack('result', 1, nil)
            smelter.state = base_asm.STATE.IDLE
        else
            smelter.status_text = 'Melting flux (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    elseif smelter.state == base_asm.STATE.ALLOYING and base_mach.expend_heat(smelter, opts.COST_FLUX_ALLOYING_HU * speed_mult, 'Alloying') then
        local result_stack = smelter.inv:get_stack('result', 1)
        local result_name = terumet.itemstack_desc(result_stack)
        smelter.state_time = smelter.state_time - (dt * speed_mult)
        if smelter.state_time <= 0 then
            local out_inv, out_list = base_mach.get_output(smelter)
            if out_inv then
                if out_inv:room_for_item(out_list, result_stack) then
                    smelter.inv:set_stack('result', 1, nil)
                    out_inv:add_item(out_list, result_stack)
                    smelter.state = base_asm.STATE.IDLE
                else
                    smelter.status_text = result_name .. ' ready - no output space!'
                    smelter.state_time = -0.1
                end
            else
                smelter.status_text = 'No output'
                smelter.state_time = -0.1
            end
        else
            smelter.status_text = 'Alloying ' .. result_name .. ' (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    end
end

function base_asm.check_new_processing(smelter)
    if smelter.state ~= base_asm.STATE.IDLE then return end
    local in_inv, in_list = base_mach.get_input(smelter)
    if not in_inv then
        smelter.status_text = "No input"
        return
    end
    local error_msg
    -- first, check for elements of an alloying recipe in input
    local matched_recipe = nil
    for _,recipe in ipairs(opts.recipes) do
        if recipe.flux > 0 or smelter.zero_flux_recipes then
            local sources_count = 0
            for i = 1,#recipe.input do
                if in_inv:contains_item(in_list, recipe.input[i]) then
                    sources_count = sources_count + 1
                end
            end
            if sources_count == #recipe.input then
                matched_recipe = recipe
                break
            end
        end
    end
    if matched_recipe then
        local result = ItemStack(matched_recipe.result)
        local result_name = terumet.itemstack_desc(result)
        if smelter.flux_tank < matched_recipe.flux then
            error_msg = 'Alloying ' .. result_name .. ': ' .. matched_recipe.flux - smelter.flux_tank .. ' more flux needed'
        else
            smelter.state = base_asm.STATE.ALLOYING
            for _, consumed_source in ipairs(matched_recipe.input) do
                in_inv:remove_item(in_list, consumed_source)
            end
            smelter.state_time = matched_recipe.time
            smelter.inv:set_stack('result', 1, result)
            smelter.flux_tank = smelter.flux_tank - matched_recipe.flux
            smelter.status_text = 'Accepting materials to alloy ' .. result_name .. '...'
            return
        end
    end
    -- if could not begin alloying anything, check for flux to melt
    for flux_item, flux_params in pairs(opts.FLUX_ITEMS) do
        if in_inv:contains_item(in_list, flux_item) then
            if smelter.flux_tank >= opts.FLUX_MAXIMUM then
                error_msg = 'Flux tank full!'
            else
                smelter.state = base_asm.STATE.FLUX_MELT
                smelter.state_time = flux_params.time
                in_inv:remove_item(in_list, flux_item)
                smelter.inv:set_stack('result', 1, flux_item)
                smelter.status_text = 'Accepting flux from '.. minetest.registered_items[flux_item].description ..'...'
                return
            end
        end
    end
    -- at this point nothing we can do
    smelter.status_text = error_msg or 'Idle'
end

function base_asm.tick(pos, dt)
    -- read state from meta
    local smelter = base_mach.tick_read_state(pos)

    local venting
    local reset_timer = false
    if base_mach.check_overheat(smelter, opts.MAX_HEAT) then
        -- venting heat
        venting = true
    else
        -- normal operation
        base_asm.do_processing(smelter, dt)
        base_asm.check_new_processing(smelter)
        base_mach.process_fuel(smelter)
    end

    if smelter.state ~= base_asm.STATE.IDLE and (not smelter.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        reset_timer = true
        base_mach.set_node(pos, base_asm.lit_id)
        base_mach.generate_smoke(pos)
    else
        base_mach.set_node(pos, base_asm.unlit_id)
    end

    if venting or base_mach.has_upgrade(smelter, 'ext_input') then
        reset_timer = true
    end
    -- write status back to meta
    base_mach.write_state(pos, smelter)

    return reset_timer
end

base_asm.unlit_nodedef = base_mach.nodedef{
    -- node properties
    description = "Terumetal Alloy Smelter",
    tiles = {
        terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
        terumet.tex('raw_sides_unlit'), terumet.tex('raw_sides_unlit'),
        terumet.tex('raw_sides_unlit'), terumet.tex('asmelt_front_unlit')
    },
    -- callbacks
    on_construct = base_asm.init,
    on_timer = base_asm.tick,
    -- machine class data
    _terumach_class = {
        name = 'Terumetal Alloy Smelter',
        timer = 0.5,
        -- NEW
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        -- end new
        drop_id = base_asm.unlit_id,
        get_drop_contents = base_asm.get_drop_contents,
        on_form_action = FORM_ACTION,
        on_read_state = function(asmelt)
            asmelt.zero_flux_recipes = (asmelt.meta:get_int('opt_zfr') or 0) == 1
            asmelt.flux_tank = asmelt.meta:get_int('flux_tank')
        end,
        on_write_state = function(asmelt)
            asmelt.meta:set_int('flux_tank', asmelt.flux_tank)
        end
    }
}

base_asm.lit_nodedef = {}
for k,v in pairs(base_asm.unlit_nodedef) do base_asm.lit_nodedef[k] = v end
base_asm.lit_nodedef.on_construct = nil -- lit smeltery node shouldn't be constructed by player
base_asm.lit_nodedef.tiles = {
    terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
    terumet.tex('raw_sides_lit'), terumet.tex('raw_sides_lit'),
    terumet.tex('raw_sides_lit'), terumet.tex('asmelt_front_lit')
}
base_asm.lit_nodedef.groups = terumet.create_lit_node_groups(base_asm.unlit_nodedef.groups)
base_asm.lit_nodedef.light_source = 10


minetest.register_node(base_asm.unlit_id, base_asm.unlit_nodedef)
minetest.register_node(base_asm.lit_id, base_asm.lit_nodedef)

minetest.register_craft{ output = base_asm.unlit_id, recipe = {
    {terumet.id('item_coil_raw'), terumet.id('item_coil_raw'), terumet.id('item_coil_raw')},
    {'bucket:bucket_empty', terumet.id('frame_raw'), 'bucket:bucket_empty'},
    {'default:furnace', 'default:furnace', 'default:furnace'}
}}