return function(rune)
	local Adapter = {
		name = "rune",
		note = "component reads and writes bypass the deferred queue to satisfy the benchmark's synchronous read-after-write contract; doesn't have native query - uses linear entities scan.",
	}

	function Adapter.createContext()
		return { world = rune.World() }
	end

	function Adapter.allocComponent(_context, index)
		return { name = tostring(index) }
	end

	-- Flushes promised_changes (entity creation/deletion).
	-- Component mutations bypass the queue so this is only needed
	-- after createEntity / spawn calls, not after set/remove.
	function Adapter.sync(context)
		context.world.update(context.world, 0)
	end

	function Adapter.createEntity(context)
		return context.world.add_entity({})
	end

	function Adapter.spawn(context, data)
		local components = {}
		for handle, value in pairs(data) do
			table.insert(components, { name = handle.name, value = value })
		end
		return context.world.add_entity(components)
	end

	-- Direct mutation
	function Adapter.set(context, entity, component, value)
		local e = context.world.entities[entity]
		if not e then
			return
		end
		e[component.name] = { name = component.name, value = value }
	end

	function Adapter.get(context, entity, component)
		local e = context.world.entities[entity]
		if not e then
			return nil
		end
		local c = e[component.name]
		return c and c.value or nil
	end

	function Adapter.has(context, entity, component)
		local e = context.world.entities[entity]
		return e ~= nil and e[component.name] ~= nil
	end

	function Adapter.remove(context, entity, component)
		local e = context.world.entities[entity]
		if not e then
			return
		end
		e[component.name] = nil
	end

	-- Rune has no query API;
	function Adapter.query(context, components)
		local width = #components
		local names = {}
		for i = 1, width do
			names[i] = components[i].name
		end

		local matched = {}
		local count = 0

		for _, entity in pairs(context.world.entities) do
			local ok = true
			for i = 1, width do
				if entity[names[i]] == nil then
					ok = false
					break
				end
			end
			if ok then
				count = count + 1
				matched[count] = entity
			end
		end

		return {
			entities = matched,
			components = components,
			get = function(entity, component)
				local c = entity[component.name]
				return c and c.value or nil
			end,
		}
	end

	return Adapter
end
