terumet.register_machine_upgrade('tubelib', 'Tube Support Upgrade', 'tubelib:tube1', nil, 'single')

local machine_check = function(machine, player_name)
    return machine and terumet.machine.has_upgrade(machine, 'tubelib')
    ---terumet.machine.has_auth(machine, player_name)
end

local PUSH_FUNC = function(pos, side, item, player_name)
    local machine = terumet.machine.readonly_state(pos)
    if machine_check(machine) then
        local result = tubelib.put_item(machine.meta, 'in', item)
        if result then machine.class.on_inventory_change(machine) end
        return result
    end
    return false
end

local TUBELIB_MACHINE_DEF = {
    on_pull_item = function(pos, side, player_name)
        local machine = terumet.machine.readonly_state(pos)
        if machine_check(machine) then
            return tubelib.get_item(machine.meta, 'out')
        end
        return nil
    end,
    on_push_item = PUSH_FUNC,
    on_unpull_item = PUSH_FUNC
}

terumet.machine.register_on_place(function (pos, machine, placer)
    tubelib.add_node(pos, machine.class.name)
end)

terumet.machine.register_on_remove(function (pos, machine)
    tubelib.remove_node(pos)
end)

tubelib.register_node(terumet.id('mach_asmelt'), {terumet.id('mach_asmelt_lit')}, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_htfurn'), {terumet.id('mach_htfurn_lit')}, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_lavam'), {terumet.id('mach_lavam_lit')}, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_htr_furnace'), {terumet.id('mach_htr_furnace_lit')}, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_crusher'), {terumet.id('mach_crusher_lit')}, TUBELIB_MACHINE_DEF)
--oops: mese garden has no upgrade slots... consider adding it if support for other upgrades is added in future
--tubelib.register_node(terumet.id('mach_meseg'), terumet.EMPTY, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_repm'), terumet.EMPTY, TUBELIB_MACHINE_DEF)
tubelib.register_node(terumet.id('mach_vulcan'), terumet.EMPTY, TUBELIB_MACHINE_DEF)

