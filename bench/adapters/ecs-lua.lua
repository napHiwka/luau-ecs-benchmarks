return function(ecs)
	local Adapter = {
		name = "ecs-lua",
		note = "each ComponentClass wraps values in { value = ... }",
	}

	-- To bench the library, you need to comment out
	-- or remove these lines from the library's code:
	--[[
	if _G.ECS == nil then
	   _G.ECS = ECS
	else
	   local warn = _G.warn or print
	   warn("ECS Lua was not registered in the global variables, there is already another object registered.")
	end
	--]]

	function Adapter.createContext()
		local world = ecs.World(nil, 30, true)
		return { world = world }
	end

	function Adapter.allocComponent(_context, _index)
		return ecs.Component({ value = 0 })
	end

	function Adapter.createEntity(context)
		return context.world:Entity()
	end

	function Adapter.spawn(context, data)
		local instances = {}
		for compClass, value in pairs(data) do
			instances[#instances + 1] = compClass({ value = value })
		end
		return context.world:Entity(table.unpack(instances))
	end

	function Adapter.set(_context, entity, component, value)
		entity:Set(component, component({ value = value }))
	end

	function Adapter.get(_context, entity, component)
		local instance = entity[component]
		return instance and instance.value or nil
	end

	function Adapter.has(_context, entity, component)
		return entity[component] ~= nil
	end

	function Adapter.remove(_context, entity, component)
		entity[component] = nil
	end

	function Adapter.query(context, components)
		context.world:Update("process", os.clock())
		local q = ecs.Query.All(table.unpack(components))
		local entities = context.world:Exec(q):ToArray()
		return {
			entities = entities,
			components = components,
			get = function(entity, component)
				local inst = entity[component]
				return inst and inst.value or nil
			end,
		}
	end

	return Adapter
end
