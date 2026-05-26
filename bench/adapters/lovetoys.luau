return function(library)
	local Adapter = {
		name = "lovetoys",
		note = "result includes adapter-side overhead for component class construction and component lookup to match the benchmark query API.",
	}

	library.initialize({ debug = false, globals = false })

	local registeredClasses = {}

	function Adapter.createContext()
		return {
			engine = library.Engine(),
			componentClasses = {},
		}
	end

	function Adapter.allocComponent(context, index)
		local name = "Comp" .. index
		if not registeredClasses[name] then
			local cls = library.Component.create(name, { "value" }, { value = 0 })
			registeredClasses[name] = cls
		end
		context.componentClasses[name] = registeredClasses[name]
		return name
	end

	function Adapter.createEntity(context)
		local entity = library.Entity()
		context.engine:addEntity(entity)
		return entity
	end

	function Adapter.set(context, entity, component, value)
		local cls = context.componentClasses[component]
		if cls then
			entity:set(cls(value))
		end
	end

	function Adapter.get(_context, entity, component)
		local comp = entity:get(component)
		return comp and comp.value or nil
	end

	function Adapter.has(_context, entity, component)
		return entity:has(component)
	end

	function Adapter.remove(_context, entity, component)
		entity:remove(component)
	end

	local function getQueryValue(entity, component)
		local comp = entity:get(component)
		return comp and comp.value or nil
	end

	-- engine:getEntitiesWithComponent returns { [entity.id] = entity }
	function Adapter.query(context, components)
		local primary = components[1]
		local candidates = context.engine:getEntitiesWithComponent(primary) or {}

		local entities = {}
		local count = 0

		for _, entity in pairs(candidates) do
			local allMatch = true
			for i = 2, #components do
				if not entity:has(components[i]) then
					allMatch = false
					break
				end
			end

			if allMatch then
				count = count + 1
				entities[count] = entity
			end
		end

		return {
			entities = entities,
			components = components,
			get = getQueryValue,
		}
	end

	return Adapter
end
