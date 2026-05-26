return function(library)
	local Adapter = {
		name = "name",
		note = "",
	}

	function Adapter.createContext()
		return {}
	end

	function Adapter.createEntity(context) end

	function Adapter.allocComponent(context, index) end

	function Adapter.set(context, entity, component, value) end

	function Adapter.get(context, entity, component) end

	function Adapter.has(context, entity, component) end

	function Adapter.remove(context, entity, component) end

	-- Must return one of:
	-- Iterator: function() -> entity, v1, v2, ...  (nil when exhausted)
	-- Array: { { entity, v1, v2, ... }, ... }
	-- Entity rows: { entities = matchedEntities, components = components }
	-- Getter rows: { entities = matchedEntities, components = components, get = function(entity, component) ... end }
	-- Raw rows: { rows = matchedRows, components = components }
	function Adapter.query(context, components) end

	-- Optional: implement if your library has an efficient batch-creation API
	-- If omitted, the harness calls createEntity + set for each component
	-- function Adapter.spawn(context, data) end

	-- Optional: implement if your library needs the deferred sync changes on adding & removing components.
	-- function Adapter.sync(context) end

	return Adapter
end
