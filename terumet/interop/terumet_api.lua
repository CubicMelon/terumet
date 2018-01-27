-- API for other mods to interface with this mod

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
        error('teruemt.register_alloy_recipe: invalid inputs; must be a table of 1-4 itemstack strings (inclusive)')
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
        inventory_image = terumet.tex('item_cryst_bg')..'^('..terumet.tex('item_cryst')..'^[multiply:'..data.color..')',
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



local MACHINE_REQUIRED = {
    name='[string] Name of machine',
    node_tiles='[minetest tiles definition] Tiles for machine node',
    heat_max='[integer] Base maximum heat units that can be stored by machine',
    heat_provider='[boolean] true if machine provides heat, false if it accepts heat',
    heat_transfer='[integer] Maximum amount of heat transfer machine can do in 1 tick',
    input_slots='[integer, 0-4 expected] Size of input inventory',
    output_slots='[integer, 0-4 expected] Size of output inventory',
    has_fuel_slot='[boolean] Whether machine has direct fuel slot',
    tick_time='[float] Time in seconds between machine ticks',
    tick_function='[fn(machine_state)] Function called when machine ticks. Return true to tick again in tick_time seconds.'
}
-- optional keys:
-- node_name: [string] name to give machine's node. if not provided, uses same as 'name'
-- custom_fsdef: [fsdef table] customized formspec definition table for machine to use, see terumet/machine/machine.lua:build_fs for more information
-- custom_write: [fn(machine_state)] function to call when saving machine state to metadata
-- custom_read: [fn(machine_state)] function to call when reading machine state from metadata
function terumet.register_heat_machine( id, data )
    if not data then
        error('terumet.register_heat_machine: no data provided')
    end
    for req_key, desc in pairs(MACHINE_REQUIRED) do
        if not data[req_key] then
            error(string.format('terumet.register_heat_machine: data is missing required key %s: %s', req_key, desc))
        end
    end
    -- TODO
    if not cust_nodedef.description then cust_nodedef.description = cust_data.name end
    
    local nodedef = terumet.machine.nodedef(cust_nodedef)
    local class = nodedef._terumach_class

    nodedef.on_construct = function(pos)
        terumet.machine.custom.init(pos, class)
    end
    nodedef.on_timer = terumet.machine.custom.tick
    
    class.cust = cust_data
    if cust_data.timer then class.timer = cust_data.timer end
    class.get_drop_contents = terumet.machine.custom.get_drop_contents
    class.on_write_state = function(cmachine)
        cmachine.meta:set_string('formspec', terumet.machine.custom.generate_formspec(cmachine))
        cmachine.meta:set_string('infotext', terumet.machine.custom.generate_infotext(cmachine))
    end
    minetest.register_node( id, nodedef )
end