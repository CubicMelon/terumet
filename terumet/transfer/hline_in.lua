--local opts = terumet.options.heat_ray
local base_opts = terumet.options.machine
local base_mach = terumet.machine

local base_hlin = {}
base_hlin.id = terumet.id('mach_hl_input')

base_hlin.links = {}

local HEATLINE_ID = terumet.id('xfer_hline')
local is_heatline = function(node)
    return node and (node.name == HEATLINE_ID)
end

-- on hlin.get_links() if links[pos] is empty, calls find_links
-- also calls find_links on update button press

function base_hlin.get_links(machine)
    if not machine then return nil end
    if not base_hln.links[machine.pos] then base_hln.find_links(machine) end
    return base_hln.links[machine.pos]
end

function base_hlin.delete_links(mpos)
    base_hlin.links[mpos]=nil
end

function base_hlin.find_links(machine)
    if not machine then return end

    local visit_list = {}
    local visited = {}
    local links = {}

    for _,offset in pairs(util3d.ADJACENT_OFFSETS) do
        local adj_pos, adj_node = util3d.get_offset(machine.pos, offset)
        if is_heatline(adj_node) then
            visit_list[#visit_list+1] = {pos=adj_pos, dist=0}
        end
    end

    while #visit_list > 0 do
        local visit = visit_list[#visit_list]
        visit_list[#visit_list] = nil
        local vpos = visit.pos
        local vnode = minetest.get_node_or_nil(visit.pos)
        local vdist = visit.dist + 1
        for _,offset in pairs(util3d.ADJACENT_OFFSETS) do
            local adj_pos, adj_node = util3d.get_offset(vpos, offset)
            if adj_node then
                -- if target machine, record lowest distance
                if base_mach.get_class_property(adj_node.name, 'heatline_target') then
                    if (not links[adj_pos]) or links[adj_pos] > vdist then
                        linked_machines[look_node] = vdist
                    end
                -- if another heatline and not yet visited, add to list
                elseif is_heatline(adj_node) and (not visited[adj_pos]):
                    visit_list[#visit_list+1] = {pos=adj_pos, dist=vdist}
                end
            end
        end
        visited[vpos] = true
    end
    
    base_hlin.links[machine.pos] = links
end

base_hlin.nodedef = base_mach.nodedef{
    description = 'Heatline Input (WIP)',
    tiles = {terumet.tex('hline_in')},
    _terumach_class = {
        name = 'Heatline Input',
        timer = 1.0,
        --fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_hlin.id,
        get_drop_contents = base_hlin.get_drop_contents,
        on_remove = function(pos, machine)
            -- cleanup stored links from server
            base_hlin.delete_links(pos)
        end
    }
}

minetest.register_node( terumet.id('conn_hline_in'), base_hlin.nodedef )
