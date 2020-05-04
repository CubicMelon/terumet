local function register_with_moreblocks(item_id)
    local _, subname = item_id:match("^([^:]+):([^:]+)$")
    local def = minetest.registered_nodes[item_id]
    if not (subname and def) then
        minetest.log('warning', '[terumet] trying to register unknown item w/ moreblocks: ' .. item_id)
    end
    stairsplus:register_all(terumet.mod_name, subname, item_id, def)
end

for index, _ in ipairs(dye.dyes) do
    register_with_moreblocks(terumet.concrete_block_id(index))
end

register_with_moreblocks(terumet.id('block_asphalt'))
register_with_moreblocks(terumet.id('block_ceramic'))
register_with_moreblocks(terumet.id('block_coke'))
register_with_moreblocks(terumet.id('block_cgls'))
register_with_moreblocks(terumet.id('block_dust_bio'))
register_with_moreblocks(terumet.id('block_entropy'))
register_with_moreblocks(terumet.id('block_pwood'))
register_with_moreblocks(terumet.id('block_raw'))
register_with_moreblocks(terumet.id('block_tar'))
register_with_moreblocks(terumet.id('block_tcha'))
register_with_moreblocks(terumet.id('block_tcop'))
register_with_moreblocks(terumet.id('block_tglass'))
register_with_moreblocks(terumet.id('block_tglassglow'))
register_with_moreblocks(terumet.id('block_tgol'))
register_with_moreblocks(terumet.id('block_thermese'))
register_with_moreblocks(terumet.id('block_tste'))
register_with_moreblocks(terumet.id('block_ttin'))
