-- interop bugfix with Mesecons/piston mod
-- fix for https://github.com/Terumoc/terumet/issues/16

terumet.machine.register_on_new_machine_node(function (id, def)
    -- register every terumetal machine node as a "stopper" for pistons
    mesecon.register_mvps_stopper(id, true)
end)