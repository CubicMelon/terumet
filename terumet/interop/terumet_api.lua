-- API for other mods to interface with this mod


-- register an external block for use in making heatline versions and/or reinforced versions
-- if you wish to exclude one or the other, pass {heatline=true} or {reinforced=true} as 3rd argument
function terumet.register_convertible_block(id, unique_code, exclude)
    exclude = exclude or {}
    if not exclude.heatline then
        terumet.register_heatline_block(id, unique_code)
    end
    if not exclude.reinforced then
        terumet.register_reinforced_block(id, unique_code)
    end
end

-- register an item that provide Repair Material to Equipment Reformer
-- value = repair material value provided by 1 item
function terumet.register_repair_material(id, value)
    -- TODO error checking
    terumet.options.repm.repair_mats[id] = value
end

-- register a tool that can be repaired in Equipment Reformer
-- needed_mat = amount of repair material value to repair fully worn tool
function terumet.register_repairable_item(id, needed_mat)
    -- TODO error checking
    terumet.options.repm.repairable[id] = needed_mat
end

-- register a new alloy smelter recipe
-- required data keys and descriptions:
local ALLOY_REQUIRED = {
    result='[itemstack string] what will be output',
    inputs='[table, 1-4 stacks] table of itemstacks consumed as input',
    time='[float] time in seconds to process',
    flux='[integer] amount of terumetal flux consumed from tank',
}
function terumet.register_alloy_recipe(data)
    if not data then
        error('terumet.register_alloy_recipe: no recipe data provided')
    end
    for req_key, desc in pairs(ALLOY_REQUIRED) do
        if not data[req_key] then
            error(string.format('terumet.register_alloy_recipe: recipe data is missing required key %s: %s', req_key, desc))
        end
    end
    if type(inputs) ~= 'table' or #inputs < 1 or #inputs > 4 then
        error('terumet.register_alloy_recipe: invalid inputs; must be a table of 1-4 itemstack strings (inclusive)')
    end
    local list = terumet.options.smelter.recipes
    list[#list+1] = data
end

-- register a new crystallized material with the provided data
-- ID of created item will be 'terumet:item_cryst_<SUFFIX>' 
-- IMPORTANT NOTE: a single source item can only be defined as a single crystal
-- for example, trying to add a new crystal for 'default:copper_lump' will override the default one
-- 
-- required data keys and descriptions:
local CRYSTAL_REQUIRED = {
    suffix='[string] ID suffix for crystallized item',
    color='[colorspec] minetest colorspec for crystallized item color',
    name='[string] name of crystallized item',
    source='[itemstack string] source item that creates crystallized item',
    cooking_result='[itemstack string] result of cooking crystallized item'
}

function terumet.register_crystal(data)
    if not data then
        error('terumet.register_crystal: no material data provided')
    end
    for req_key, desc in pairs(CRYSTAL_REQUIRED) do
        if not data[req_key] then
            error(string.format('terumet.register_crystal: material data is missing required key %s: %s', req_key, desc))
        end
    end
    local crys_id = terumet.id('item_cryst_' .. data.suffix)
    minetest.register_craftitem( crys_id, {
        description = data.name,
        inventory_image = terumet.crystal_tex(data.color),
    })

    minetest.register_craft{ type = 'cooking', 
        output = data.cooking_result,
        recipe = crys_id,
        cooktime = 5
    }

    terumet.options.vulcan.recipes[data.source] = crys_id
end

-- register that a node can generate heat when extracted by the Environmental Entropy Extraction Heater (EEE Heater)
local ENTROPIC_REQUIRED = {
    node='[string] id of node that can be extracted',
    hu_per_s='[integer] number of heat units extracted per second',
    extract_time='[float] total amount of time to extract this node',
}
-- optional keys:
-- change_to: [string] what node this node will change into after extraction - if nil, the node will not change and thus can be extracted over and over (like air by default)
function terumet.register_entropic_node(data)
    if not data then
        error('terumet.register_entropic_node: no data provided')
    end
    for req_key, desc in pairs(ENTROPIC_REQUIRED) do
        if not data[req_key] then
            error(string.format('terumet.register_entropic_node: data is missing required key %s: %s', req_key, desc))
        end
    end
    terumet.options.heater.entropy.EFFECTS[data.node] = {hu_per_s=data.hu_per_s, extract_time=data.extract_time, change_to=data.change_to}
end


local STANDARD_INV_LISTS = {'in', 'out', 'fuel', 'upgrade'}
local EXTERNAL_MACHINES = {}
local MACHINE_REQUIRED = {
    name='[string] Name of machine',
    node_tiles='[minetest tiles definition] Tiles for machine node',
    heat_max='[integer] Base maximum heat units that can be stored by machine',
    input_slots='[integer, 0-4 expected] Size of input inventory',
    output_slots='[integer, 0-4 expected] Size of output inventory',
    has_fuel_slot='[boolean] Whether machine has direct fuel slot',
    upgrade_slots='[integer, 0-6 expected] Size of upgrade inventory',
    tick_time='[float] Time in seconds between machine ticks',
    tick_function='[fn(machine_state, dt) -> boolean] Function called when machine ticks. Return true to tick again in tick_time seconds.'
}
-- optional keys:
-- heat_provider: [boolean] true if machine generates/provides heat to adjacent machines
-- heat_transfer: [integer] Maximum amount of heat machine can send in 1 tick
-- node_name: [string] name to give machine's node. if not provided, uses same as 'name'
-- node_param2: [string] param2 to give machine's node (same as minetest's nodedef param2 setting: facedir/none/etc. )
-- custom_init: [fn(pos, meta, inv) -> nil] custom initialization for setting inventories or other metadata of a new machine
-- custom_write: [fn(machine_state)] function to call when saving machine state to metadata
-- custom_read: [fn(machine_state)] function to call when reading machine state from metadata
-- -- machine formspec options --
-- <basic>
-- machinefs_theme: [string] definition of background/listcolors for machine's formspec
-- machinefs_func: [fn(machine_state) -> string] custom function that returns formspec definition for main area above inventory in interface
-- -- <OR advanced> --
-- custom_fsdef: [fsdef table] entire customized formspec definition table for machine to use, see terumet/machine/machine.lua:build_fs for more information
--  [IMPORTANT] => using custom_fsdef completely overrides use of machinefs_* funcs and default formspec so everything must be defined

function terumet.register_heat_machine( id, data )
    if not data then
        error('terumet.register_heat_machine: no data provided')
    end
    for req_key, desc in pairs(MACHINE_REQUIRED) do
        if not data[req_key] then
            error(string.format('terumet.register_heat_machine: data is missing required key %s: %s', req_key, desc))
        end
    end

    local machine_tm_class = {
        name = data.name,
        timer = data.tick_time,
        fsdef = data.custom_fsdef or {
            control_buttons = {
                terumet.machine.buttondefs.HEAT_XFER_TOGGLE,
            },
            machine = data.machinefs_func or terumet.NO_FUNCTION,
            input = {data.input_slots > 0},
            output = {data.output_slots > 0},
            fuel_slot = {data.fuel_slot},
            theme = data.machinefs_theme,
        },
        default_heat_xfer = (data.heat_provider and terumet.machine.HEAT_XFER_MODE.PROVIDE_ONLY) or terumet.machine.HEAT_XFER_MODE.ACCEPT,
        get_drop_contents = function(machine)
            local drops = {}
            for _,std_list in ipairs(STANDARD_INV_LISTS) do
                default.get_inventory_drops(machine.pos, std_list, drops)
            end
            return drops
        end
    }

    local node_def = terumet.machine.nodedef{
        description = data.node_name or data.name,
        tiles = data.node_tiles,
        param2 = data.node_param2,
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            if data.upgrade_slots > 0 then inv:set_size('upgrade', data.upgrade_slots) end
            if data.input_slots > 0 then inv:set_size('in', data.input_slots) end
            if data.output_slots > 0 then inv:set_size('out', data.output_slots) end
            if data.has_fuel_slot then inv:set_size('fuel', 1) end
            if data.custom_init then data.custom_init(pos, meta, inv) end
            local init = {
                class = machine_tm_class,
                state = 0,
                state_time = 0,
                heat_level = 0,
                max_heat = data.heat_max,
                status_text = 'New',
                inv = inv,
                meta = meta,
                pos = pos,
            }
            terumet.machine.write_state(pos, init)
            terumet.machine.set_timer(init)
        end,
        on_timer = function(pos, dt)
            local machine = terumet.machine.tick_read_state(pos)
            local re_tick = false
            if not terumet.machine.check_overheat(machine, data.heat_max) then
                re_tick = data.tick_function(machine, dt)
                if machine.heat_xfer_mode == terumet.machine.HEAT_XFER_MODE.PROVIDE_ONLY then
                    terumet.machine.push_heat_adjacent(machine, data.heat_transfer or 50)
                end

                if data.has_fuel_slot then
                    terumet.machine.process_fuel(machine)
                    re_tick = not machine.need_heat
                end
            end
            -- write status back to meta
            terumet.machine.write_state(pos, machine)
            return re_tick
        end,
        _terumach_class = machine_tm_class
    }

    minetest.register_node( id, node_def )

    EXTERNAL_MACHINES[id] = data
end