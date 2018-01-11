-- Terumet Custom Machine Sample (tmcms)
-- A submod that creates a simple Terumetal heat machine that processes gravel into flint.
-- by Terumoc for testing and example purposes

-- if testing this directly as a mod, rename the folder to "tmcms" and move to your mods folder

-- any standard Minetest node def settings for your machine's node can be provided
local machine_nodedef = {
    description = 'Gravelyzer\nGuaranteed to turn gravel into flint',
    tiles = {'tmcms_machine.png'},
    -- glows for no reason, just as an example to show standard minetest properties propagate
    light_source = 10,
    -- many nodedef properties such as groups, stack_max, is_ground_content etc. will be automatically 
    -- set by the API to usual machine-like settings
    -- see terumet/machine/machine.lua -> function base_mach.nodedef(additions) for full defaults
}

local machine_cust_data = {
    -- Name of machine (only)
    name = 'Gravelyzer',
    -- optional: Preamble to machine's formspec; if not provided, uses Terumetal mod's default
    --  note: custom machine formspec is 8x9 item slots large
    pre_formspec = 'background[0,0;8,9;tmcms_gui_bg.png;true]listcolors[#aaaaaa;#444444]',
    -- how often machine 'ticks' in seconds
    timer = 0.5,
    -- Base maximum heat units that can be stored by machine
    -- (note minimum should likely be 2000 since that is the HUs given by a lava bucket and the largest instant
    --  source of heat -- any less and lava buckets will not ever work in your machine!)
    max_heat_base = 2000,
    -- heat expended per tick when processing
    heat_per_tick = 1,
    -- description for process, will be displayed as "process_desc result_item"
    process_desc = 'Gravelyzing',
    -- function that does actual processing of input
    -- access and modify machine input through Inventory machine_inv
    -- the inventory lists used by custom machines are: 
    --    'in' (4 slots, allows anything) 
    --    'out' (4 slots, only allows item removal)
    --    'fuel' (1 slot, heating fuel only and automatically processed if needed)
    --    'result' (1 slot, special) - used to contain results of processing and display result on GUI
    --                                 'output' in return table will automatically be placed in here
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

-- call terumet.create_custom_machine with (id, nodedef, cust_data)
terumet.create_custom_machine( 'tmcms:gravelyzer', machine_nodedef, machine_cust_data )