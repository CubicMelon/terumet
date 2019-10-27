-- interop bugfix with Mesecons/piston mod
-- fix for https://github.com/Terumoc/terumet/issues/16

terumet.machine.on_machine_registration(function (id, def)
    -- register every terumetal machine node as a "stopper" for pistons
    mesecon.register_mvps_stopper(id, true)
end)