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
base_asm.STATE.VENTING = 3

function base_asm.generate_formspec(smelter)
    local fs = 'size[10,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    base_mach.fs_owner(smelter,8,0)..
    --input inventory
    base_mach.fs_input(smelter,0,1.5,2,2)..
    --output inventory
    base_mach.fs_output(smelter,6,1.5,2,2)..
    --fuel slot
    base_mach.fs_fuel_slot(smelter,6.5,0)..
    --upgrade slots
    base_mach.fs_upgrades(smelter,8.75,1)..
    --current status
    'label[0,0;Terumetal Alloy Smelter]'..
    'label[0,0.5;' .. smelter.status_text .. ']'..
    base_mach.fs_flux_info(smelter,2,1.5,100.0 * smelter.flux_tank / opts.FLUX_MAXIMUM)..
    base_mach.fs_heat_info(smelter,4.25,1.5)..
    base_mach.fs_heat_mode(smelter,4.25,4)
    if smelter.state == base_asm.STATE.FLUX_MELT then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..terumet.id('item_cryst_raw')..']'
    elseif smelter.state == base_asm.STATE.ALLOYING then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..smelter.inv:get_stack('result',1):get_name()..']'
    end
    --option buttons
    if smelter.zero_flux_recipes then
        fs=fs..'image_button[8.75,8;1,1;default_bronze_ingot.png;zfr_button; ]'..
        'tooltip[zfr_button;Using zero flux recipies]'
    else
        fs=fs..'image_button[8.75,8;1,1;(default_bronze_ingot.png^terumet_gui_disabled.png);zfr_button; ]'..
        'tooltip[zfr_button;Ignoring zero flux recipies]'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;in]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function base_asm.generate_infotext(smelter)
    return string.format('Alloy Smelter (%.1f%% heat): %s', base_mach.heat_pct(smelter), smelter.status_text)
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
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.ACCEPT,
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
    if smelter.state == base_asm.STATE.FLUX_MELT and base_mach.expend_heat(smelter, smelter.heat_cost, 'Melting flux') then
        smelter.state_time = smelter.state_time - dt
        if smelter.state_time <= 0 then
            smelter.flux_tank = smelter.flux_tank + 1
            smelter.state = base_asm.STATE.IDLE
        else
            smelter.status_text = 'Melting flux (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    elseif smelter.state == base_asm.STATE.ALLOYING and base_mach.expend_heat(smelter, smelter.heat_cost, 'Alloying') then
        local result_stack = smelter.inv:get_stack('result', 1)
        local result_name = terumet.itemstack_desc(result_stack)
        smelter.state_time = smelter.state_time - dt
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
            if base_mach.has_upgrade(smelter, 'speed_up') then
                smelter.state_time = matched_recipe.time / 2
                smelter.heat_cost = opts.COST_FLUX_ALLOYING_HU * 2
            else
                smelter.state_time = matched_recipe.time
                smelter.heat_cost = opts.COST_FLUX_ALLOYING_HU
            end
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
                if base_mach.has_upgrade(smelter, 'speed_up') then
                    smelter.state_time = flux_params.time / 2
                    smelter.heat_cost = opts.COST_FLUX_MELTING_HU * 2
                else
                    smelter.state_time = flux_params.time
                    smelter.heat_cost = opts.COST_FLUX_MELTING_HU
                end
                in_inv:remove_item(in_list, flux_item)
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
    local smelter = base_mach.read_state(pos)
    local venting
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
        base_mach.set_timer(smelter)
        base_mach.set_node(pos, base_asm.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, base_asm.unlit_id)
    end

    if venting or base_mach.has_upgrade(smelter, 'ext_input') then
        base_mach.set_timer(smelter)
    end
    -- write status back to meta
    base_mach.write_state(pos, smelter)
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
        drop_id = base_asm.unlit_id,
        get_drop_contents = base_asm.get_drop_contents,
        on_form_action = function(asmelt, fields, player)
            if fields.zfr_button then
                terumet.toggle_option(asmelt.meta, 'opt_zfr')
                asmelt.meta:set_string('formspec', base_asm.generate_formspec(asmelt))
                base_mach.set_timer(asmelt)
            end
        end,
        on_read_state = function(asmelt)
            asmelt.flux_tank = asmelt.meta:get_int('flux_tank')
            asmelt.heat_cost = asmelt.meta:get_int('heatcost') or 0
            asmelt.zero_flux_recipes = (asmelt.meta:get_int('opt_zfr') or 0) == 1
        end,
        on_write_state = function(asmelt)
            asmelt.meta:set_int('flux_tank', asmelt.flux_tank)
            asmelt.meta:set_string('formspec', base_asm.generate_formspec(asmelt))
            asmelt.meta:set_string('infotext', base_asm.generate_infotext(asmelt))
            asmelt.meta:set_int('heatcost', asmelt.heat_cost or 0)
            asmelt.meta:set_int('opt_zfr', (asmelt.zero_flux_recipes and 1) or 0)
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
base_asm.lit_nodedef.groups={cracky=1, not_in_creative_inventory=1}
base_asm.lit_nodedef.light_source = 10


minetest.register_node(base_asm.unlit_id, base_asm.unlit_nodedef)
minetest.register_node(base_asm.lit_id, base_asm.lit_nodedef)

minetest.register_craft{ output = base_asm.unlit_id, recipe = {
    {terumet.id('item_coil_raw'), terumet.id('item_coil_raw'), terumet.id('item_coil_raw')},
    {'bucket:bucket_empty', terumet.id('frame_raw'), 'bucket:bucket_empty'},
    {'default:furnace', 'default:furnace', 'default:furnace'}
}}