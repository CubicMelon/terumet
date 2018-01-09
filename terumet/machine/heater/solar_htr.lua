local opts = terumet.options.heater.solar
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local sol_htr = {}
sol_htr.id = terumet.id('mach_htr_solar')

-- state identifier consts
sol_htr.STATE = {}
sol_htr.STATE.GENERATING = 0

function sol_htr.generate_formspec(heater)
    local fs = 'size[8,9]'..base_mach.fs_start..
    --player inventory
    base_mach.fs_player_inv(0,4.75)..
    --current status
    'label[0,0;Solar Heater]'..
    'label[0,0.5;' .. heater.status_text .. ']'..
    base_mach.fs_heat_info(heater,4,1.5)
    return fs
end

function sol_htr.generate_infotext(heater)
    return string.format('Solar Heater (%.1f%% heat): %s', base_mach.heat_pct(heater), heater.status_text)
end

function sol_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    
    local init_heater = {
        class = sol_htr.nodedef._terumach_class,
        state = sol_htr.STATE.GENERATING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        heat_xfer_mode = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_heater)
    base_mach.set_timer(init_heater)
end

local LIGHT_LEEWAY = 4
function sol_htr.do_processing(solar, dt)
    local above = {x=solar.pos.x, y=solar.pos.y+1, z=solar.pos.z}
    -- use light level at midnight to determine how much artificial light is affecting light level
    local night_light = minetest.get_node_light(above, 0)
    local present_light = minetest.get_node_light(above, nil)
    if not (night_light and present_light) then return end -- in case above is not loaded?
    
    local effective_light = math.min(15, math.max(0, present_light - night_light + LIGHT_LEEWAY))
    
    local gain = opts.SOLAR_GAIN_RATES[effective_light+1]

    if gain == 0 then
        solar.status_text = 'Waiting for sufficient sunlight'
    else
        local under_cap = solar.heat_level < (solar.max_heat - gain)
        if under_cap then
            base_mach.gain_heat(solar, gain)
            solar.status_text = string.format('Sunlight: %.0f%% ', 100.0*effective_light/15)
        else
            solar.status_text = 'Heat is maximum'
        end
    end
    if night_light > LIGHT_LEEWAY then
        solar.status_text = solar.status_text .. string.format(', Interference: %.0f%%', 100.0*(night_light-LIGHT_LEEWAY)/15)
    end
end

function sol_htr.tick(pos, dt)
    -- read state from meta
    local solar = base_mach.read_state(pos)

    sol_htr.do_processing(solar, dt)
    base_mach.push_heat_adjacent(solar, opts.HEAT_TRANSFER_RATE)

    -- write status back to meta
    base_mach.write_state(pos, solar)
    base_mach.set_timer(solar)
end

sol_htr.nodedef = base_mach.nodedef{
    -- node properties
    description = "Solar Heater",
    tiles = {
        terumet.tex('htr_solar_top'), terumet.tex('frame_tste'),
        terumet.tex('frame_tste'), terumet.tex('frame_tste'),
        terumet.tex('frame_tste'), terumet.tex('frame_tste')
    },
    paramtype2 = 'none',
    -- callbacks
    on_construct = sol_htr.init,
    on_timer = sol_htr.tick,
    -- terumet machine class data
    _terumach_class = {
        timer = 1.0,
        on_external_heat = nil,
        on_write_state = function(solar)
            solar.meta:set_string('formspec', sol_htr.generate_formspec(solar))
            solar.meta:set_string('infotext', sol_htr.generate_infotext(solar))
        end
    }
}

minetest.register_node(sol_htr.id, sol_htr.nodedef)

minetest.register_craft{ output = sol_htr.id, recipe = {
    {terumet.id('item_solar'), terumet.id('item_solar'), terumet.id('item_solar')},
    {terumet.id('item_coil_tgol'), terumet.id('frame_tste'), terumet.id('item_coil_tgol')},
    {terumet.id('item_coil_tgol'), 'bucket:bucket_water', terumet.id('item_coil_tgol')}
}}