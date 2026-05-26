return function(ECS)
    local Adapter = {
        name = "jecs",
        note = "uses cached Jecs query handles.",
    }

    function Adapter.createContext()
        return {
            world = ECS.world(),
            queries = {},
        }
    end

    function Adapter.allocComponent(context, index)
        return context.world:component()
    end

    function Adapter.createEntity(context)
        return context.world:entity()
    end

    function Adapter.set(context, entity, component, value)
        context.world:set(entity, component, value)
    end

    function Adapter.get(context, entity, component)
        return context.world:get(entity, component)
    end

    function Adapter.has(context, entity, component)
        return context.world:has(entity, component)
    end

    function Adapter.remove(context, entity, component)
        return context.world:remove(entity, component)
    end

    -- looks scary, but it's just trie cache
    function Adapter.query(context, components)
        local node = context.queries
        for i = 1, #components do
            local c = components[i]
            local next = node[c]
            if next == nil then
                next = {}
                node[c] = next
            end
            node = next
        end
        local query = node.query
        if query == nil then
            query = context.world:query(unpack(components)):cached()
            node.query = query
        end
        return query:iter()
    end

    return Adapter
end
