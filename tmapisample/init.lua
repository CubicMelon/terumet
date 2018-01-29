-- Terumet Custom Machine Sample (tmapisample)
-- A submod that creates a simple Terumetal heat machine that processes gravel into flint.
-- by Terumoc for testing and example purposes of API in terumet version 2.0

if not terumet or terumet.version.major < 2 then
    error('tmapisample is intended for Terumetal version 2.0 or later')
end

-- ids to track machine state
local GRAVELYZE_STATE_IDLE = 0 -- idle and looking for new input (0=default state)
local GRAVELYZE_STATE_ACTIVE = 1 -- active and processing an item

local gravelyzer_data = {
    -- Name of machine (only)
    name = 'Gravelyzer',
    -- (optional) Name of machine's node
    node_name = 'Gravelyzer\nGuaranteed to turn gravel into flint'
    -- tiles for machine's node (exact same as would normally be defined in nodedef)
    node_tiles = 'tmapisample_machine.png',
    -- max heat machine can store (+50% with heat storage upgrade)
    heat_max = 2000,
    -- true if this machine generates/provides heat to other machines, false if it uses it
    heat_provider = false,
    -- max heat machine can transfer per tick (increased with heat transfer upgrades)
    heat_transfer = 50,
    -- number of input/output slots
    input_slots = 2,
    output_slots = 1,
    -- true if machine has fuel slot and can be heated directly
    has_fuel_slot = true,
    -- number of upgrade slots
    -- simple upgrades such as heat level/transfer related ones will automatically be handled
    -- more specialized upgrades like speed upgrade must be handled yourself (see tick_function)
    upgrade_slots = 2,
    -- time between machine ticks (seconds)
    tick_time = 0.5,
    -- function called every tick with machine state and exact time since last tick (delta time)
    tick_function = function( machine, dt )
    end,
    -- (optional) bg/coloring for machine's formspec
    machinefs_theme = 'background[0,0;11,9;tmapisample_gui_bg.png]',
    -- (optional) function that returns formspec info for main machine area
    machinefs_func = function( machine )
        --TODO
    end,

    process_func = function( machine_inv )
        -- check for our target item to process
        if machine_inv:contains_item('in', 'default:gravel') then
            -- remove the item
            machine_inv:remove_item('in', 'default:gravel')
            -- return results of processing
            return {
                desc = 'Beginning gravelyzing...', -- message when new processing is acknowledged
                output = 'default:flint', -- itemstack that will go to output when complete
                time = 5.0, -- time in seconds processing will take (best as multiple of machine's 'timer')
            }
        else
            return nil -- return nil if no processing can be done on current input
        end
    end,
    -- optional: function that does anything additional after processing completes for an item
    -- will be called after machine moves output to output slot
    after_process_func = function( machine_inv )
        minetest.chat_send_all('A gravelyzer has completed its processing! Hooray!')
    end
}

-- call terumet.register_heat_machine with (id, machine_data)
terumet.register_heat_machine( 'tmapisample:gravelyzer', gravelyzer_data )