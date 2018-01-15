local opts = terumet.options.heater.furnace
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local furn_htr = {}
furn_htr.unlit_id = terumet.id('mach_htr_furnace')
furn_htr.lit_id = terumet.id('mach_htr_furnace_lit')

-- state identifier consts
furn_htr.STATE = {}
furn_htr.STATE.IDLE = 0
furn_htr.STATE.BURNING = 1
furn_htr.STATE.BURN_FULL = 2

function furn_htr.generate_formspec(heater)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    base_mach.fs_owner(heater,5,0)..
    --input inventory
    base_mach.fs_input(heater,1,1.5,1,1)..
    --current status
    'label[0,0;Furnace Heater]'..
    'label[0,0.5;' .. heater.status_text .. ']'..
    base_mach.fs_heat_info(heater,3,1.5)..
    base_mach.fs_heat_mode(heater,3,4)..
    base_mach.fs_upgrades(heater,6.75,1)
    if heater.state ~= furn_htr.STATE.IDLE then
        fs=fs..'image[1,3;1,1;terumet_gui_product_bg.png]item_image[1,3;1,1;'..heater.inv:get_stack('burn',1):get_name()..']'
    end
    --list rings
    fs=fs.."listring[current_player;main]"..
	"listring[context;in]"
    return fs
end

function furn_htr.generate_infotext(heater)
    return string.format('Furnace Heater (%.1f%% heat): %s', base_mach.heat_pct(heater), heater.status_text)
end

function furn_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 1)
    inv:set_size('burn', 1)
    inv:set_size('upgrade', 2)
    local init_heater = {
        class = furn_htr.unlit_nodedef._terumach_class,
        state = furn_htr.STATE.IDLE,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        status_text = 'New',
        inv = inv,
        meta = meta
    }
    base_mach.write_state(pos, init_heater)
end

function furn_htr.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

function furn_htr.do_processing(heater, dt)
    local gain = math.floor(heater.gen_rate * dt) -- heat gain this tick
    if base_mach.has_upgrade(heater, 'gen_up') then gain = gain * 3 end
    if gain == 0 then return end
    local under_cap = heater.heat_level < (heater.max_heat - gain)
    if heater.state == furn_htr.STATE.BURN_FULL and under_cap then
        heater.state = furn_htr.STATE.BURNING
    end
    if heater.state == furn_htr.STATE.BURNING then
        if under_cap then
            heater.state_time = heater.state_time - dt
            base_mach.gain_heat(heater, gain)
            if heater.state_time <= 0 then
                heater.inv:set_stack('burn', 1, nil)
                heater.status_text = 'Burn complete'
                heater.state = furn_htr.STATE.IDLE
            else
                heater.status_text = 'Burning (' .. terumet.format_time(heater.state_time) .. ')'
            end
        else
            heater.state = furn_htr.STATE.BURN_FULL
            heater.status_text = 'Burning Paused: Heat maximum'
        end
    end
end

function furn_htr.check_new_processing(heater)
    if heater.state ~= furn_htr.STATE.IDLE or heater.heat_level == heater.max_heat then return end
    local in_inv, in_list = base_mach.get_input(heater)
    if not in_inv then
        heater.status_text = 'No input'
    end
    for slot=1,in_inv:get_size(in_list) do
        local input_stack = in_inv:get_stack(in_list, slot)
        local cook_result
        local cook_after
        cook_result, cook_after = minetest.get_craft_result({method = 'fuel', width = 1, items = {input_stack}})
        if cook_result.time ~= 0 then
            heater.state = furn_htr.STATE.BURNING
            in_inv:set_stack(in_list, slot, cook_after.items[1])
            heater.inv:set_stack('burn', 1, input_stack)
            heater.state_time = math.floor(cook_result.time * heater.class.timer)
            heater.gen_rate = 5
            if base_mach.has_upgrade(heater, 'speed_up') then
                heater.state_time = heater.state_time / 2
                heater.gen_rate = heater.gen_rate * 2
            end
            heater.status_text = 'Accepting ' .. input_stack:get_definition().description .. ' for burning...'
            return
        end
    end
    heater.status_text = 'Idle'
end

function furn_htr.tick(pos, dt)
    -- read state from meta
    local heater = base_mach.read_state(pos)
    local venting
    if base_mach.check_heat_max(heater, opts.MAX_HEAT) then
        venting = true
    else
        furn_htr.do_processing(heater, dt)
        furn_htr.check_new_processing(heater)
    end

    if (not venting) and heater.heat_xfer_mode == base_mach.HEAT_XFER_MODE.PROVIDE_ONLY then
        base_mach.push_heat_adjacent(heater, opts.HEAT_TRANSFER_RATE)
    end
    -- remain active if currently burning something or have any heat (for distribution)
    if heater.state == furn_htr.STATE.BURNING then
        base_mach.set_timer(heater)
        base_mach.set_node(pos, furn_htr.lit_id)
        base_mach.generate_particle(pos)
    else
        base_mach.set_node(pos, furn_htr.unlit_id)
        if heater.heat_level > 0 then base_mach.set_timer(heater) end
    end

    if venting or base_mach.has_upgrade(heater, 'ext_input') then base_mach.set_timer(heater) end
    -- write status back to meta
    base_mach.write_state(pos, heater)

end

furn_htr.unlit_nodedef = base_mach.nodedef{
    -- node properties
    description = "Furnace Heater",
    tiles = {
        terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
        terumet.tex('raw_sides_unlit'), terumet.tex('raw_sides_unlit'),
        terumet.tex('raw_sides_unlit'), terumet.tex('htr_furnace_front_unlit')
    },
    -- callbacks
    on_construct = furn_htr.init,
    on_timer = furn_htr.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Furnace Heater',
        timer = 0.5,
        drop_id = furn_htr.unlit_id,
        on_external_heat = nil,
        get_drop_contents = furn_htr.get_drop_contents,
        on_read_state = function(fheater)
            fheater.gen_rate = fheater.meta:get_int('genrate') or 0
        end,
        on_write_state = function(fheater)
            fheater.meta:set_string('formspec', furn_htr.generate_formspec(fheater))
            fheater.meta:set_string('infotext', furn_htr.generate_infotext(fheater))
            fheater.meta:set_int('genrate', fheater.gen_rate or 0)
        end
    }
}

furn_htr.lit_nodedef = {}
for k,v in pairs(furn_htr.unlit_nodedef) do furn_htr.lit_nodedef[k] = v end
furn_htr.lit_nodedef.on_construct = nil -- lit node shouldn't be constructed by player
furn_htr.lit_nodedef.tiles = {
    terumet.tex('raw_mach_top'), terumet.tex('raw_mach_bot'),
    terumet.tex('raw_sides_lit'), terumet.tex('raw_sides_lit'),
    terumet.tex('raw_sides_lit'), terumet.tex('htr_furnace_front_lit')
}
furn_htr.lit_nodedef.groups={cracky=1, not_in_creative_inventory=1}
furn_htr.lit_nodedef.light_source = 10


minetest.register_node(furn_htr.unlit_id, furn_htr.unlit_nodedef)
minetest.register_node(furn_htr.lit_id, furn_htr.lit_nodedef)

minetest.register_craft{ output = furn_htr.unlit_id, recipe = {
    {terumet.id('item_coil_tcop'), 'default:furnace', terumet.id('item_coil_tcop')},
    {terumet.id('item_coil_tcop'), terumet.id('frame_raw'), terumet.id('item_coil_tcop')},
    {terumet.id('item_coil_tcop'), 'default:copperblock', terumet.id('item_coil_tcop')}
}}