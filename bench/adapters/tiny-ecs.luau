return function(tiny)
	local Adapter = {
		name = "tiny-ecs",
		note = "tiny-ECS does not provide native ECS queries. The adapter reuses emulated systems",
	}

	function Adapter.createContext()
		return {
			world = tiny.world(),
			systems = {},
		}
	end

	function Adapter.allocComponent(_, index)
		return index
	end

	function Adapter.createEntity(context)
		local entity = {}
		tiny.addEntity(context.world, entity)
		return entity
	end

	function Adapter.set(context, entity, component, value)
		entity[component] = value
		tiny.addEntity(context.world, entity)
	end

	function Adapter.get(_, entity, component)
		return entity[component]
	end

	function Adapter.has(_, entity, component)
		return entity[component] ~= nil
	end

	function Adapter.remove(context, entity, component)
		entity[component] = nil
		tiny.addEntity(context.world, entity)
	end

	function Adapter.sync(context)
		tiny.refresh(context.world)
	end

	local function makeQueryKey(components)
		local ids = {}
		for index = 1, #components do
			ids[index] = tostring(components[index])
		end
		return table.concat(ids, "|")
	end

	local function makeSystem(components)
		return tiny.system({
			filter = function(_, entity)
				for index = 1, #components do
					if entity[components[index]] == nil then
						return false
					end
				end
				return true
			end,
		})
	end

	local function getSystem(context, components)
		local key = makeQueryKey(components)
		local system = context.systems[key]
		if not system then
			system = makeSystem(components)
			context.systems[key] = system
			tiny.addSystem(context.world, system)
			tiny.refresh(context.world)
		end
		return system
	end

	function Adapter.query(context, components)
		local system = getSystem(context, components)
		return {
			entities = system.entities,
			components = components,
		}
	end

	return Adapter
end
