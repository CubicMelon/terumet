local opts = terumet.options.heatline
local base_opts = terumet.options.machine
local base_mach = terumet.machine

local base_hlin = {}
base_hlin.id = terumet.id('mach_hl_input')

local POS_STR = minetest.pos_to_string

-- server cache of links keyed by location of input machine
base_hlin.links = {}

minetest.register_chatcommand('heatlines', {
    description = 'Display a list of all currently cached heatline links',
    func = function(name, param)
        local count = 0
        for orig,links in pairs(base_hlin.links) do
            minetest.chat_send_player(name, '***** Links originating from '..orig..':')
            minetest.chat_send_player(name, debug_linklist_desc(links))
            count = count + 1
        end
        minetest.chat_send_player(name, 'Total cached heatline links: '..count)
    end
})

base_hlin.STATE = {}
-- no heat stored, so nothing to do
base_hlin.STATE.IDLE = 0
-- has heat, sending some periodically
base_hlin.STATE.ACTIVE = 1

local HEATLINE_ID = terumet.id('xfer_hline')
local is_heatline = function(node)
    return node and (node.name == HEATLINE_ID)
end

function debug_linklist_desc(links)
    if links then
        local count = #links
        str=string.format('%d linked machine(s):\n', count)
        for _,link in ipairs(links) do
            local linkinfo = string.format(' at %s d:%d\n', POS_STR(link.pos), link.dist)
            local machine_node = minetest.get_node_or_nil(link.pos)
            if machine_node then
                local machine_name = base_mach.get_class_property(machine_node.name, 'name')
                if machine_name then
                    str=str..machine_name..linkinfo
                else
                    str=str..'(not machine)'..linkinfo
                end
            else
                str=str..'<unavailable>'..linkinfo
            end
        end
        return str
    else
        return 'no link data'
    end
end

function base_hlin.init(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size('upgrade', 2)
    local init_hlin = {
        class = base_hlin.nodedef._terumach_class,
        state = base_hlin.STATE.IDLE,
        state_time = opts.RECHECK_LINKS_TIMER,
        heat_level = 0,
        max_heat = opts.MAX_HEAT,
        status_text = 'New',
        inv = inv,
        meta = meta,
        pos = pos
    }
    base_mach.write_state(pos, init_hlin)
    base_mach.set_timer(init_hlin)
end

function base_hlin.get_drop_contents(machine)
    local drops = {}
    default.get_inventory_drops(machine.pos, 'upgrade', drops)
    return drops
end

local FSDEF = {
    control_buttons = {
        base_mach.buttondefs.HEAT_XFER_TOGGLE,
    },
    machine = function(machine)
        if machine.state == base_hlin.STATE.IDLE then
            return 'label[0.5,0.5;Currently idle.]'
        else
            local links = base_hlin.get_links(machine)
            if links then
                return string.format('label[0.5,0.5;%d linked machine(s). Last sent %d HU total.]', #links, machine.last_sent or 0)
            else
                return 'label[0.5,0.5;No links.]'
            end
        end
    end,
}

function base_hlin.get_links(machine)
    if not machine then return nil end
    local mposstr = POS_STR(machine.pos)
    if not base_hlin.links[mposstr] then base_hlin.find_links(machine) end
    return base_hlin.links[mposstr]
end

function base_hlin.delete_links(mpos)
    base_hlin.links[POS_STR(mpos)]=nil
end

function base_hlin.find_links(machine)
    if not machine then return end
    -- stack of pending node visits:
    --  visit_stack[index] = {pos=node_pos, dist=distance_from_input}
    local visit_stack = {}
    -- list of already visited nodes
    --  visited[node_pos] = true
    local visited = {}
    -- list of linked machines
    --  links[index] = {pos=node_pos, dist=distance_from_input}
    -- this is eventually stored in server cache base_hlin.links[input_machine_pos]
    local links = {}
    -- list of linked poses
    --  link_pos_list[node_pos] = index in links -- for quicker checking if a linked node is already added
    local link_pos_list = {}

    for _,offset in pairs(util3d.ADJACENT_OFFSETS) do
        local adj_pos, adj_node = util3d.get_offset(machine.pos, offset)
        if is_heatline(adj_node) then
            visit_stack[#visit_stack+1] = {pos=adj_pos, dist=0}
        end
    end

    while #visit_stack > 0 do
        local visit = visit_stack[#visit_stack]
        visit_stack[#visit_stack] = nil
        local vpos = visit.pos
        local vnode = minetest.get_node_or_nil(visit.pos)
        local vdist = visit.dist + 1
        for _,offset in pairs(util3d.ADJACENT_OFFSETS) do
            local adj_pos, adj_node = util3d.get_offset(vpos, offset)
            local adj_pos_str = POS_STR(adj_pos)
            if adj_node then
                -- if a target machine, record a link to it
                if base_mach.get_class_property(adj_node.name, 'heatline_target') then
                    if not link_pos_list[adj_pos_str] then
                        links[#links+1] = {pos=adj_pos, dist=vdist}
                        link_pos_list[adj_pos_str]=#links
                    else
                        -- if already linked, check if this was a shorter distance
                        local oldlink = links[link_pos_list[adj_pos_str]]
                        if oldlink.dist > vdist then
                            -- if we made a shorter distance to a machine, overwrite it
                            oldlink.dist = vdist
                        end
                    end
                -- if another heatline and not yet visited, try to add to stack
                elseif is_heatline(adj_node) and (not visited[adj_pos_str]) then
                    if vdist > opts.MAX_DIST then
                        -- if this next node exceeds maximum distance, display a smoke warning
                        base_mach.generate_smoke(adj_pos, 3)
                        --minetest.chat_send_all('WARNING DIST REACHED '..vdist)
                    else
                        -- otherwise add it to the stack of nodes to visit
                        visit_stack[#visit_stack+1] = {pos=adj_pos, dist=vdist}
                    end
                end
            end
        end
        visited[POS_STR(vpos)] = true
    end
    
    -- sort links by ascending distance
    table.sort(links, function(la,lb)
        return la.dist < lb.dist
    end)
    base_hlin.links[POS_STR(machine.pos)] = links
end

function base_hlin.distribute(hlin)
    if hlin.heat_level > 0 then
        hlin.last_sent = 0
        local links = base_hlin.get_links(hlin)
        if #links > 0 then
            local total_send = opts.HEAT_TRANSFER_MAX
            if base_mach.has_upgrade(hlin, 'heat_xfer') then total_send = total_send * 2 end
            -- if we can't send max amount, divide up what IS available
            total_send = math.min(hlin.heat_level, total_send)
            -- TODO ignore machines that don't need/request heat in division
            local try_each_send = math.ceil(total_send / #links)
            -- go to each target in order of ascending distance
            for _,link in ipairs(links) do
                if hlin.heat_level == 0 then break end
                local target = base_mach.read_state(link.pos)
                if target then
                    local this_send_max = try_each_send
                    if base_mach.has_upgrade(target, 'heat_xfer') then this_send_max = math.floor(this_send_max * 1.25) end
                    local real_send = math.min(hlin.heat_level, this_send_max, target.max_heat - base_mach.get_current_heat(target))
                    if real_send > 0 then
                        base_mach.external_send_heat(target, real_send)
                        hlin.heat_level = hlin.heat_level - real_send
                        hlin.last_sent = hlin.last_sent + real_send
                    end
                end
            end
        end
        hlin.state = base_hlin.STATE.ACTIVE
    else
        hlin.state = base_hlin.STATE.IDLE
        --hlin.state_time = -0.1 -- force next wakeup to recheck links
        hlin.status_text = 'Idle'
    end
end

function base_hlin.tick(pos, dt)
    local hlin = base_mach.tick_read_state(pos)
    local venting = base_mach.check_overheat(hlin, opts.MAX_HEAT)
    if not venting then
        hlin.state_time = hlin.state_time - dt
        if hlin.state_time <= 0 then
            base_hlin.delete_links(pos)
            hlin.state_time = opts.RECHECK_LINKS_TIMER
        end
        hlin.status_text = string.format('%.1f seconds until recheck', hlin.state_time)
        base_hlin.distribute(hlin)
    end

    base_mach.write_state(pos, hlin)
    return venting or (hlin.state == base_hlin.STATE.ACTIVE)
end

base_hlin.nodedef = base_mach.nodedef{
    -- node properties
    description = 'Heatline Distributor',
    tiles = {terumet.tex('hline_in')},
    -- callbacks
    on_construct = base_hlin.init,
    on_timer = base_hlin.tick,
    -- terumet machine class data
    _terumach_class = {
        name = 'Heatline Distributor',
        timer = 1.0,
        -- heatlines cannot send heat to this machine
        heatline_target = false,
        fsdef = FSDEF,
        default_heat_xfer = base_mach.HEAT_XFER_MODE.ACCEPT,
        drop_id = base_hlin.id,
        get_drop_contents = base_hlin.get_drop_contents,
        on_remove = function(pos, machine)
            -- cleanup stored links from server
            base_hlin.delete_links(pos)
        end
    }
}

-- manually add input machine as a connect target for heatline nodes even if they are not technically a target
base_hlin.nodedef.groups['terumet_hltarget']=1

minetest.register_node( base_hlin.id, base_hlin.nodedef )

minetest.register_craft{ output = base_hlin.id, recipe = {
    {terumet.id('block_ceramic'), terumet.id('item_coil_tgol'), terumet.id('block_ceramic')},
    {terumet.id('item_coil_tgol'), terumet.id('block_thermese'), terumet.id('item_coil_tgol')},
    {terumet.id('block_ceramic'), terumet.id('item_coil_tgol'), terumet.id('block_ceramic')}
}}