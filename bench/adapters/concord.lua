return function(Concord)
	local Adapter = {
		name = "concord",
		note = "uses cached systems",
	}

	function Adapter.sync(context)
		context.world:__flush()
	end

	-- Concord.component errors on duplicate names
	local registered = {}

	function Adapter.createContext()
		return {
			world = Concord.world(),
			systems = {},
		}
	end

	function Adapter.allocComponent(_context, index)
		local name = "c" .. index -- need string
		if not registered[name] then
			Concord.component(name, function(c, v)
				c.value = v
			end)
			registered[name] = true
		end
		return name
	end

	function Adapter.createEntity(context)
		return Concord.entity(context.world)
	end

	function Adapter.set(_context, entity, component, value)
		entity:give(component, value)
	end

	function Adapter.get(_context, entity, component)
		local c = entity[component]
		return c and c.value or nil
	end

	function Adapter.has(_context, entity, component)
		return entity[component] ~= nil
	end

	function Adapter.remove(_context, entity, component)
		entity:remove(component)
	end

	function Adapter.query(context, components)
		local key = table.concat(components, "|")
		if not context.systems[key] then
			local SystemClass = Concord.system({ pool = components })
			context.world:addSystem(SystemClass)
			context.systems[key] = SystemClass
		end
		local system = context.world:getSystem(context.systems[key])

		return {
			entities = system.pool,
			components = components,
			get = function(entity, component)
				local c = entity[component]
				return c and c.value or nil
			end,
		}
	end

	return Adapter
end
