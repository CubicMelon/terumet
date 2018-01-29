-- Terumet Custom Machine Sample (tmapisample)
-- A submod that creates a simple Terumetal heat machine that processes gravel into flint.
-- by Terumoc for testing and example purposes of API in terumet version 2.0

if not terumet or terumet.version.major < 2 then
    error('tmapisample is intended for Terumetal version 2.0 or later')
end

-- ids to track machine state
-- all machines are state 0 when created
-- you could just use integers, but having descriptions is easier to understand
local GRAVELYZE_STATE_IDLE = 0 -- idle and looking for new input
local GRAVELYZE_STATE_PROCESSING = 1 -- active and processing an item

-- function called every machine tick
-- can be defined in machine data table itself; it's pulled out into its own local function here just for readability
-- "machine" contains machine's state table (see terumet/machine.lua:read_state)
-- "dt" is time since last tick (in seconds)
local MACHINE_TICK_FUNC = function( machine, dt )
    if machine.state == GRAVELYZE_STATE_IDLE then
        -- if we are currently idle looking for a new piece of gravel to process
        -- get machine's input inventory and listname (ex: machine.inv, "in" if no external upgrade)
        local input_inv, input_list = terumet.machine.get_input(machine)
        if input_inv:contains_item(input_list, 'default:gravel') then
            -- if input has gravel, remove one piece
            input_inv:remove_item(input_list, 'default:gravel')
            -- set state to begin processing it next tick
            machine.state = GRAVELYZE_STATE_PROCESSING
            -- reduce required time if a speed upgrade is installed
            -- (see terumet/material/upgrade.lua for names of all standard upgrades)
            -- 2 seconds with upgrade, 4 without
            if terumet.machine.has_upgrade(machine, 'speed_up') then
                machine.state_time = 2.0
            else
                machine.state_time = 4.0
            end
            -- fall through to do first processing tick now
        else
            -- since we won't have anything to process until inventory changes
            -- return false to not schedule a new tick immediately
            return false
        end
    end
    if machine.state == GRAVELYZE_STATE_PROCESSING then
        -- if we are currently processing a piece of gravel
        -- spend heat to process - returns false if not enough heat and automatically sets status text
        if terumet.machine.expend_heat(machine, 2, 'Gravelyzing') then
            -- progress processing time
            machine.state_time = machine.state_time - dt
            -- have we finished processing?
            if machine.state_time <= 0 then
                -- get machine's output inventory and listname (ex: machine.inv, "out" if no external upgrade)
                local output_inv, output_list = terumet.machine.get_output(machine)
                -- check that there's space for the flint
                if output_inv:room_for_item(output_list, 'default:flint') then
                    -- place a flint in output inventory
                    output_inv:add_item(output_list, 'default:flint')
                    -- set machine's state to idle
                    machine.state = GRAVELYZE_STATE_IDLE
                    machine.status_text = 'Gravelyzing finished!'
                else
                    -- if no room, let the player know
                    machine.status_text = 'Gravelyzing finished but no room for output.'
                    -- keep state time just below zero to trigger attempt to output next tick
                    machine.state_time = -0.01
                end
            else
                -- if we're still processing just update status message
                machine.status_text = string.format('Gravelyzing (%.1fs)', machine.state_time)
            end
            -- returning true will automatically schedule next machine tick
            -- since we're currently processing, next tick should happen no matter what
            return true
        end
    end
end

-- itemstack used in machinefs_func below
local DISPLAY_FLINT_ITEMSTACK = ItemStack('default:flint')

local gravelyzer_data = {
    -- Name of machine (only)
    name = 'Gravelyzer',
    -- (optional) Name of machine's node
    node_name = 'Gravelyzer\nGuaranteed to turn gravel into flint',
    -- tiles for machine's node (exact same as would normally be defined in nodedef)
    node_tiles = {'tmapisample_machine.png'},
    -- max heat machine can store (+50% with heat storage upgrade)
    heat_max = 2000,
    -- true if this machine generates/provides heat to other machines, false/nil if it does not
    heat_provider = nil,
    -- number of input/output slots
    input_slots = 2,
    output_slots = 1,
    -- true if machine has fuel slot and can be heated directly
    has_fuel_slot = true,
    -- number of upgrade slots
    -- simple upgrades such as heat level/transfer related ones will automatically be handled
    -- more specialized upgrades like speed upgrade must be handled yourself (see use of has_upgrade in MACHINE_TICK_FUNC above)
    upgrade_slots = 2,
    -- time between machine ticks (seconds)
    tick_time = 0.5,
    -- function called every tick with machine state and exact time since last tick (delta time)
    -- common attributes of machine will automatically be read/written to and from metadata before and after this call
    -- (MACHINE_TICK_FUNC is defined above)
    tick_function = MACHINE_TICK_FUNC,
    -- (optional) bg/coloring for machine's formspec
    machinefs_theme = 'background[0,0;11,9;tmapisample_gui_bg.png;true]',
    -- (optional) function that returns formspec info for main machine area
    machinefs_func = function( machine )
        if machine.state == GRAVELYZE_STATE_PROCESSING then
            -- coordinates of formspec elements will have 0,0 as the upper-left of machine info area, not whole formspec area
            -- terumet.machine.fs_proc returns a standard "processing" formspec image for the type of processing you provide
            -- 'gen' is generic, other options are 'flux', 'heat', 'alloy' (see terumet/textures/terumet_gui_proc_*.png)
            return terumet.machine.fs_proc(3,1.5, 'gen', DISPLAY_FLINT_ITEMSTACK)
        else
            return ""
        end
    end,

}

-- call terumet.register_heat_machine with (id, machine_data)
terumet.register_heat_machine( 'tmapisample:gravelyzer', gravelyzer_data )