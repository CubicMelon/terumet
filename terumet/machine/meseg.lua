local opts = terumet.options.meseg
local base_opts = terumet.options.machine

local base_mach = terumet.machine

local base_msg = {}
base_msg.id = terumet.id('mach_meseg')

-- state identifier consts
base_msg.STATE = {}
base_msg.STATE.WAITING = 0
base_msg.STATE.GROWING = 1
base_msg.STATE.OUTPUT = 2

-- itemstack gained by successful growth
local RESULT_ITEMSTACK = ItemStack(opts.PRODUCE_ITEM)

-- definition for particles when seed breaks
local LOSS_PARTICLE_DATA = {
    texture='terumet_part_seedbreak.png',
    velocity={x=0,y=2.9,z=0},
    size=0.8,
    randvel_xz=5,
    randvel_y=10,
    acceleration={x=0,y=-6.0,z=0},
    expiration=1.2,
}

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    machine = function(machine)
        return base_mach.fs_meter(2,1.5,'effc', 100*machine.effic/opts.MAX_EFFIC, 'Efficiency') ..
            base_mach.fs_meter(2,2.5,'mese', 100*machine.progress/opts.PROGRESS_NEED, 'Growth')
    end,
    input = {label='Seeds'},
    output = {label='Grown'}
}


function base_msg.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('in', 1)
    inv:set_size('out', 1)
    local init_meseg = {
        class = base_msg.nodedef._terumach_class,
        state = base_msg.STATE.WAITING,
        state_time = 0,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_meseg)
end

function base_msg.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'in', drops)
    default.get_inventory_drops(machine.pos, "out", drops)
    return drops
end

function base_msg.do_output(meseg)
    if meseg.state ~= base_msg.STATE.OUTPUT then return end
    local out_inv, out_list = base_mach.get_output(meseg)
    if out_inv and out_inv:room_for_item(out_list, RESULT_ITEMSTACK) then
        local in_inv, in_list = base_mach.get_input(meseg)
        local failure = false
        if in_inv then
            local input_stack = in_inv:get_stack(in_list, 1) -- supports only 1 slot input
            if input_stack and input_stack:get_name() == opts.SEED_ITEM then
                out_inv:add_item(out_list, RESULT_ITEMSTACK)
                if opts.SEED_LOSS_CHANCE then
                    local seed_count = input_stack:get_count()
                    local chance = math.max(1, opts.SEED_LOSS_CHANCE - seed_count)
                    if terumet.RAND:next(1,chance) == 1 then
                        in_inv:remove_item(in_list, opts.SEED_ITEM)
                        if opts.SEED_LOSS_SOUND then
                            minetest.sound_play( opts.SEED_LOSS_SOUND, {
                                pos = meseg.pos,
                                gain = 0.3,
                                max_hear_distance = 16
                            })
                        end
                        if opts.SEED_LOSS_PARTICLES then base_mach.generate_particle(meseg.pos, LOSS_PARTICLE_DATA, 6) end
                        meseg.status_text = "New shard complete! (seed crystal lost)"
                    else
                        meseg.status_text = "New shard complete!"
                    end
                else
                    meseg.status_text = "New shard complete!"
                end
            else
                failure = true
            end
        else
            failure = true
        end
        if failure then
            meseg.status_text = "Seed crystals lost, growth failure"
            meseg.progress = 0
        end
        meseg.state = base_msg.STATE.GROWING
    else
        meseg.status_text = "Waiting for output space..."
    end
end

function base_msg.do_growing(meseg, dt)
    -- if still waiting to output, skip growing until output complete
    if meseg.state == base_msg.STATE.OUTPUT then return end

    local in_inv, in_list = base_mach.get_input(meseg)
    local input_stack = in_inv:get_stack(in_list, 1) -- supports only 1 slot input
    local has_seed = (input_stack and input_stack:get_name() == opts.SEED_ITEM)
    local has_heat = base_mach.expend_heat(meseg, opts.GROW_HEAT, 'Heating garden')
    if has_seed and has_heat then
        local seed_count = input_stack:get_count()
        if meseg.effic < opts.MAX_EFFIC then 
            meseg.effic = math.min(meseg.effic + seed_count, opts.MAX_EFFIC)
        end
        meseg.progress = meseg.progress + math.floor(seed_count * meseg.effic / opts.MAX_EFFIC)
        if meseg.progress >= opts.PROGRESS_NEED then
            meseg.state = base_msg.STATE.OUTPUT
            meseg.progress = 0
            meseg.status_text = 'Growth complete!'
        else
            meseg.status_text = 'Growing...'
        end        
    else
        meseg.effic = math.floor(meseg.effic * opts.EFFIC_LOSS_RATE)
        if meseg.effic > 0 then
            meseg.status_text = 'Efficiency dropping - '
            if not has_seed then meseg.status_text = meseg.status_text .. 'No seed crystals ' end
            if not has_heat then meseg.status_text = meseg.status_text .. 'No heat' end
        else
            meseg.state = base_msg.STATE.WAITING
        end
    end
end

function base_msg.check_start(meseg)
    local in_inv, in_list = base_mach.get_input(meseg)
    local input_stack = in_inv:get_stack(in_list, 1) -- supports only 1 slot input
    if input_stack and input_stack:get_name() == opts.SEED_ITEM and base_mach.expend_heat(meseg, opts.START_HEAT, 'Starting garden') then
        meseg.effic = math.floor(opts.MAX_EFFIC / 100)
        meseg.state = base_msg.STATE.GROWING
        meseg.status_text = "Starting..."
    else
        meseg.status_text = "Stopped. Waiting for seed crystals and heat."
    end
end

function base_msg.tick(pos, dt)
    -- read state from meta
    local meseg = base_mach.read_state(pos)

    local venting
    if base_mach.check_overheat(meseg, opts.MAX_HEAT) then
        venting = true
    else
        if meseg.effic > 0 then
            base_msg.do_growing(meseg, dt)
            base_msg.do_output(meseg)
        end
        if meseg.effic <= 0 then
            base_msg.check_start(meseg)
        end
    end

    if venting or meseg.state == base_msg.STATE.GROWING then
        base_mach.generate_smoke(pos)
    end

    if venting or meseg.state ~= base_msg.STATE.WAITING then 
        base_mach.set_timer(meseg) 
    end
    -- write status back to meta
    base_mach.write_state(pos, meseg)

end

base_msg.nodedef = base_mach.nodedef{
    -- node properties
    description = "Mese Garden",
    tiles = {
        terumet.tex('meseg_top'), terumet.tex('block_ceramic'),
        terumet.tex('htfurn_sides'), terumet.tex('htfurn_sides'),
        terumet.tex('htfurn_sides'), terumet.tex('htfurn_sides')
    },
    -- callbacks
    on_construct = base_msg.init,
    on_timer = base_msg.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Mese Garden',
        timer = 1.0,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_msg.id,
        get_drop_contents = base_msg.get_drop_contents,
        on_read_state = function(meseg)
            meseg.effic = meseg.meta:get_int('effic') or 0
            meseg.progress = meseg.meta:get_int('progress') or 0
        end,
        on_write_state = function(meseg)
            meseg.meta:set_int('effic', meseg.effic or 0)
            meseg.meta:set_int('progress', meseg.progress or 0)
        end
    }
}

minetest.register_node(base_msg.id, base_msg.nodedef)

minetest.register_craft{ output = base_msg.id, recipe = {
    {terumet.id('item_thermese'), terumet.id('item_coil_tcop'), terumet.id('item_thermese')},
    {terumet.id('item_ceramic'), terumet.id('frame_tste'), terumet.id('item_ceramic')},
    {terumet.id('item_ceramic'), 'bucket:bucket_water', terumet.id('item_ceramic')}
}}