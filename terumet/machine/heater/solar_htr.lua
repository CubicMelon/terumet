local opts = terumet.options.heater.solar
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local sol_htr = {}
sol_htr.id = terumet.id('mach_htr_solar')

-- state identifier consts
sol_htr.STATE = {}
sol_htr.STATE.GENERATING = 0

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE
    },
    machine = function(machine)
        local fs = ''
        if machine.last_sun and machine.last_interf then
            fs = base_mach.fs_double_meter(2.5,1, 'sun', machine.last_sun, 'interf', machine.last_interf)
        end
        return fs
    end
}

function sol_htr.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('upgrade', 2)

    local init_heater = {
        class = sol_htr.nodedef._terumach_class,
        state = sol_htr.STATE.GENERATING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_heater)
    base_mach.set_timer(init_heater)
end

function sol_htr.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

local LIGHT_LEEWAY = 3
function sol_htr.do_processing(solar, dt)
    local above = {x=solar.pos.x, y=solar.pos.y+1, z=solar.pos.z}
    -- use light level at midnight to determine how much artificial light is affecting light level
    local night_light = minetest.get_node_light(above, 0)
    local present_light = minetest.get_node_light(above, nil)
    if not (night_light and present_light) then return end -- in case above is not loaded?
    
    local effective_light = math.min(15, math.max(0, present_light - night_light + LIGHT_LEEWAY))
    
    local gain = opts.SOLAR_GAIN_RATES[effective_light+1]

    if base_mach.has_upgrade(solar, 'gen_up') then gain = gain * 2 end
    local last_eff = 100.0*effective_light/15
    local last_sun = 100.0*present_light/15
    local last_interf = math.max(0, 100.0*(night_light-LIGHT_LEEWAY)/15)
    if gain == 0 then
        solar.status_text = string.format('Waiting. Effective light: %.0f%%', last_eff)
    else
        local under_cap = solar.heat_level < (solar.max_heat - gain)
        if under_cap then
            base_mach.gain_heat(solar, gain)
            solar.status_text = string.format('Heating. Effective light: %.0f%% ', last_eff)
        else
            solar.status_text = 'Idle - maximum heat.'
        end
    end
    solar.last_sun = last_sun
    solar.last_interf = last_interf
    solar.last_eff = last_eff
end

function sol_htr.tick(pos, dt)
    -- read state from meta
    local solar = base_mach.read_state(pos)
    if not base_mach.check_overheat(solar, opts.MAX_HEAT) then
        sol_htr.do_processing(solar, dt)

        if solar.heat_xfer_mode == base_mach.HEAT_XFER_MODE.PROVIDE_ONLY then
            base_mach.push_heat_adjacent(solar, opts.HEAT_TRANSFER_RATE)
        end
    end
    -- write status back to meta
    base_mach.write_state(pos, solar)
    base_mach.set_timer(solar)
end

sol_htr.nodedef = base_mach.nodedef{
    -- node properties
    description = "Solar Heater",
    tiles = {
        terumet.tex('htr_solar_top'), terumet.tex('tste_heater_sides'),
        terumet.tex('tste_heater_sides'), terumet.tex('tste_heater_sides'),
        terumet.tex('tste_heater_sides'), terumet.tex('tste_heater_sides')
    },
    paramtype2 = 'none',
    -- callbacks
    on_construct = sol_htr.init,
    on_timer = sol_htr.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Solar Heater',
        timer = 1.0,
        -- heatlines cannot send heat to this machine
        heatline_target = false,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.PROVIDE_ONLY,
        on_external_heat = terumet.NO_FUNCTION,
        get_drop_contents = sol_htr.get_drop_contents,
    }
}

minetest.register_node(sol_htr.id, sol_htr.nodedef)

minetest.register_craft{ output = sol_htr.id, recipe = {
    {terumet.id('item_htglass'), terumet.id('item_htglass'), terumet.id('item_htglass')},
    {terumet.id('item_coil_tgol'), terumet.id('frame_tste'), terumet.id('item_coil_tgol')},
    {terumet.id('item_coil_tgol'), 'bucket:bucket_water', terumet.id('item_coil_tgol')}
}}