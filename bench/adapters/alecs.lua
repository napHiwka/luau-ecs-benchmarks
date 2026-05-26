return function(library)
	local Adapter = {
		name = "alecs",
		note = "result includes adapter-side conversion from alecs:filter() entity lists into benchmark result rows.",
	}

	function Adapter.createContext()
		return {
			world = library(),
		}
	end

	function Adapter.createEntity(context)
		-- addEntity returns the id, but we need the entity table itself
		-- for direct field access in set/get/has/remove
		local entity = {}
		context.world:addEntity(entity)
		return entity
	end

	function Adapter.allocComponent(_context, index)
		-- Alecs identifies components by string keys on the entity table
		return "c" .. index
	end

	function Adapter.set(_context, entity, component, value)
		entity[component] = value
	end

	function Adapter.get(_context, entity, component)
		return entity[component]
	end

	function Adapter.has(_context, entity, component)
		return entity[component] ~= nil
	end

	function Adapter.remove(_context, entity, component)
		entity[component] = nil
	end

	function Adapter.query(context, components)
		return {
			rows = context.world:filter(components),
			components = components,
		}
	end

	return Adapter
end
