return function(ECS)
    local Adapter = {
        name = "ecr",
        note = "uses cached ECR registry views.",
    }

    local function ensureRegistry(context)
        local registry = context.registry
        if registry == nil then
            registry = ECS.registry()
            context.registry = registry
        end
        return registry
    end

    function Adapter.createContext()
        return {
            views = {},
        }
    end

    function Adapter.allocComponent(_, _)
        return ECS.component()
    end

    function Adapter.createEntity(context)
        return ensureRegistry(context):create()
    end

    function Adapter.set(context, entity, component, value)
        ensureRegistry(context):set(entity, component, value)
    end

    function Adapter.get(context, entity, component)
        return ensureRegistry(context):try_get(entity, component)
    end

    function Adapter.has(context, entity, component)
        return ensureRegistry(context):has(entity, component)
    end

    function Adapter.remove(context, entity, component)
        return ensureRegistry(context):remove(entity, component)
    end

    function Adapter.query(context, components)
        local registry = ensureRegistry(context)
        local node = context.views
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
            query = registry:view(unpack(components))
            node.query = query
        end
        return query:iter()
    end

    return Adapter
end
