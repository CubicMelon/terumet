local opts = terumet.options.smelter
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_asm = {}
base_asm.unlit_id = terumet.id('mach_asmelt')
base_asm.lit_id = terumet.id('mach_asmelt_lit')

-- time between smelter ticks
base_asm.timer = 0.5

-- state identifier consts
base_asm.STATE = {}
base_asm.STATE.IDLE = 0
base_asm.STATE.FLUX_MELT = 1
base_asm.STATE.ALLOYING = 2

function base_asm.start_timer(pos)
    minetest.get_node_timer(pos):start(base_asm.timer)
end

function base_asm.generate_formspec(smelter)
    local heat_pct = 100.0 * smelter.heat_level / smelter.max_heat
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    --input inventory
    'list[context;inp;0,1.5;2,2;]'..
    'label[0.5,3.5;Input Slots]'..
    --output inventory
    'list[context;out;6,1.5;2,2;]'..
    'label[6.5,3.5;Output Slots]'..
    --fuel slot
    base_mach.fs_fuel_slot(smelter,6.5,0)..
    --current status
    'label[0,0;Terumetal Alloy Smelter]'..
    'label[0,0.5;' .. smelter.status_text .. ']'..
    base_mach.fs_flux_info(smelter,2,1.5,100.0 * smelter.flux_tank / opts.FLUX_MAXIMUM)..
    base_mach.fs_heat_info(smelter,4.25,1.5)
    if smelter.state == base_asm.STATE.FLUX_MELT then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..terumet.id('lump_raw')..']'
    elseif smelter.state == base_asm.STATE.ALLOYING then
        fs=fs..'image[3.5,1.75;1,1;terumet_gui_product_bg.png]item_image[3.5,1.75;1,1;'..smelter.inv:get_stack('result',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;inp]"..
    "listring[current_player;main]"..
    "listring[context;out]"
    return fs
end

function base_asm.generate_infotext(smelter)
    return string.format('Alloy Smelter (%.0f%% heat): %s', base_mach.heat_pct(smelter), smelter.status_text)
end

function base_asm.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('fuel', 1)
    inv:set_size('inp', 4)
    inv:set_size('result', 1)
    inv:set_size('out', 4)

    local init_smelter = {
        flux_tank = 0,
        state = base_asm.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta
    }
    base_mach.write_state(pos, init_smelter, base_asm.generate_formspec(init_smelter), base_asm.generate_infotext(init_smelter))
    meta:set_int('flux_tank', init_smelter.flux_tank)
end

function base_asm.get_drops(pos, include_self)
    local drops = {}
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "inp", drops)
    default.get_inventory_drops(pos, "out", drops)
    local flux_tank = minetest.get_meta(pos):get_int('flux_tank') or 0
    if flux_tank > 0 then
        drops[#drops+1] = terumet.id('lump_raw', math.min(99, flux_tank))
    end
    if include_self then drops[#drops+1] = base_asm.unlit_id end
    return drops
end

function base_asm.do_processing(smelter, dt)
    if smelter.state == base_asm.STATE.FLUX_MELT and base_mach.expend_heat(smelter, opts.COST_FLUX_MELT_HU, 'Melting flux') then
        smelter.state_time = smelter.state_time - dt
        if smelter.state_time <= 0 then
            smelter.flux_tank = smelter.flux_tank + 1
            smelter.state = base_asm.STATE.IDLE
        else
            smelter.status_text = 'Melting flux (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    elseif smelter.state == base_asm.STATE.ALLOYING and base_mach.expend_heat(smelter, opts.COST_FLUX_ALLOYING_HU, 'Alloying') then
        local result_stack = smelter.inv:get_stack('result', 1)
        local result_name = result_stack:get_definition().description
        smelter.state_time = smelter.state_time - dt
        if smelter.state_time <= 0 then
            if smelter.inv:room_for_item('out', result_stack) then
                smelter.inv:set_stack('result', 1, nil)
                smelter.inv:add_item('out', result_stack)
                smelter.state = base_asm.STATE.IDLE
            else
                smelter.status_text = result_name .. ' ready - no space!'
                smelter.state_time = -0.1
            end
        else
            smelter.status_text = 'Alloying ' .. result_name .. ' (' .. terumet.format_time(smelter.state_time) .. ')'
        end
    end
end

function base_asm.check_new_processing(smelter)
    if smelter.state ~= base_asm.STATE.IDLE then return end

    local error_msg = nil
    -- first, check for elements of an alloying recipe in input
    local matched_result = nil
    for result, recipe in pairs(terumet.alloy_recipes) do
        local sources_count = 0
        for i = 1,#recipe do
            if smelter.inv:contains_item('inp', recipe[i]) then
                sources_count = sources_count + 1
            end
        end
        if sources_count == #recipe then
            matched_result = result
            break
        end
    end
    if matched_result and minetest.registered_items[matched_result] then
        local recipe = terumet.alloy_recipes[matched_result]
        local result_name = minetest.registered_items[matched_result].description
        if smelter.flux_tank < recipe.flux then
            error_msg = 'Alloying ' .. result_name .. ': ' .. recipe.flux - smelter.flux_tank .. ' more flux needed'
        else
            smelter.state = base_asm.STATE.ALLOYING
            for _, consumed_source in ipairs(recipe) do
                smelter.inv:remove_item('inp', consumed_source)
            end
            smelter.state_time = recipe.time
            smelter.inv:set_stack('result', 1, ItemStack(matched_result, recipe.result_count))
            smelter.flux_tank = smelter.flux_tank - recipe.flux
            smelter.status_text = 'Accepting materials to alloy ' .. result_name .. '...'

        end
    end
    -- if could not begin alloying anything, check for flux to melt
    if smelter.state == base_asm.STATE.IDLE then
        if smelter.inv:contains_item('inp', opts.FLUX_ITEM) then
            if smelter.flux_tank >= opts.FLUX_MAXIMUM then
                smelter.status_text = 'Flux tank full!'
            else
                smelter.state = base_asm.STATE.FLUX_MELT
                smelter.state_time = opts.FLUX_MELTING_TIME
                smelter.inv:remove_item('inp', opts.FLUX_ITEM)
                smelter.status_text = 'Accepting flux...'
            end
        else
            -- nothing to do at this point - if no error from before then display idle
            smelter.status_text = error_msg or 'Idle'
        end
    end

end

function base_asm.tick(pos, dt)
    -- read state from meta
    local smelter = base_mach.read_state(pos)
    smelter.flux_tank = smelter.meta:get_int('flux_tank')
    
    base_asm.do_processing(smelter, dt)

    base_asm.check_new_processing(smelter)

    base_mach.process_fuel(smelter)

    if smelter.state ~= base_asm.STATE.IDLE and (not smelter.need_heat) then
        -- if still processing and not waiting for heat, reset timer to continue processing
        base_asm.start_timer(pos)
        base_mach.set_node(pos, base_asm.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, base_asm.unlit_id)
    end
    -- write status back to meta
    base_mach.write_state(pos, smelter, base_asm.generate_formspec(smelter), base_asm.generate_infotext(smelter))
    smelter.meta:set_int('flux_tank', smelter.flux_tank)
end

function base_asm.on_destruct(pos)
    for _,item in ipairs(base_asm.get_drops(pos, false)) do
        minetest.add_item(pos, item)
    end
end

function base_asm.on_blast(pos)
    drops = base_asm.get_drops(pos, true)
    minetest.remove_node(pos)
    return drops
end

base_asm.unlit_nodedef = {
    -- node properties
    description = "Terumetal Alloy Smelter",
    tiles = {
        terumet.tex('mach_top'), terumet.tex('mach_bot'),
        terumet.tex('asmelt_sides_unlit'), terumet.tex('asmelt_sides_unlit'),
        terumet.tex('asmelt_sides_unlit'), terumet.tex('asmelt_front_unlit')
    },
    paramtype2 = 'facedir',
    groups = {cracky=1},
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    legacy_facedir_simple = true,
    -- inventory slot control
    allow_metadata_inventory_put = base_mach.allow_put,
    allow_metadata_inventory_move = base_mach.allow_move,
    allow_metadata_inventory_take = base_mach.allow_take,
    -- callbacks
    on_construct = base_asm.init,
    on_metadata_inventory_move = base_asm.start_timer,
    on_metadata_inventory_put = base_asm.start_timer,
    on_metadata_inventory_take = base_asm.start_timer,
    on_timer = base_asm.tick,
    on_destruct = base_asm.on_destruct,
    on_blast = base_asm.on_blast,
}

base_asm.lit_nodedef = {}
for k,v in pairs(base_asm.unlit_nodedef) do base_asm.lit_nodedef[k] = v end
base_asm.lit_nodedef.on_construct = nil -- lit smeltery node shouldn't be constructed by player
base_asm.lit_nodedef.tiles = {
    terumet.tex('mach_top'), terumet.tex('mach_bot'),
    terumet.tex('asmelt_sides_lit'), terumet.tex('asmelt_sides_lit'),
    terumet.tex('asmelt_sides_lit'), terumet.tex('asmelt_front_lit')
}
base_asm.lit_nodedef.groups={cracky=1, not_in_creative_inventory=1}
base_asm.lit_nodedef.drop = base_asm.unlit_id
base_asm.lit_nodedef.light_source = 10


minetest.register_node(base_asm.unlit_id, base_asm.unlit_nodedef)
minetest.register_node(base_asm.lit_id, base_asm.lit_nodedef)

minetest.register_craft{ output = base_asm.unlit_id, recipe = {
    {terumet.id('item_coil_raw'), terumet.id('item_coil_raw'), terumet.id('item_coil_raw')},
    {'bucket:bucket_empty', terumet.id('frame_raw'), 'bucket:bucket_empty'},
    {'default:furnace', 'default:furnace', 'default:furnace'}
}}