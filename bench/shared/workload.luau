local Config = require("../config")
local Workload = {}

local function newRng(seed)
	local state = math.floor(math.abs(seed)) % 2147483646 + 1
	return {
		nextUInt = function()
			state = (state * 48271) % 2147483647
			return state
		end,
		nextFloat = function()
			state = (state * 48271) % 2147483647
			return state / 2147483647
		end,
		nextInt = function(_, minValue, maxValue)
			state = (state * 48271) % 2147483647
			return minValue + (state % (maxValue - minValue + 1))
		end,
	}
end

local function componentFill(config, componentIndex)
	if componentIndex == 1 then
		return config.dataset.hotComponentFill
	elseif componentIndex <= 3 then
		return config.dataset.primaryQueryComponentFill
	end
	return config.dataset.baseComponentFill
end

local function makeBlueprint(rng, config)
	local components = {}
	local values = {}

	for componentIndex = 1, config.dataset.componentsPerWorld do
		if rng:nextFloat() <= componentFill(config, componentIndex) then
			components[#components + 1] = componentIndex
			values[#values + 1] = rng:nextFloat()
		end
	end

	if #components == 0 then
		components[1] = 1
		values[1] = rng:nextFloat()
	end

	return {
		components = components,
		values = values,
	}
end

local function chooseExistingComponent(rng, blueprint)
	return blueprint.components[rng:nextInt(1, #blueprint.components)]
end

local function makeQueryDefinitions(config, rng)
	local queryDefinitions = {}
	local queryCount = config.queryWorkloads.multiQueryCount
	local componentCount = config.dataset.componentsPerWorld

	for queryIndex = 1, queryCount do
		local width
		if queryIndex % 6 == 0 then
			width = 4
		elseif queryIndex % 3 == 0 then
			width = 3
		elseif queryIndex % 2 == 0 then
			width = 2
		else
			width = 1
		end

		local used = {}
		local components = {}
		while #components < width do
			local componentIndex
			-- pin the leading component across the first 8 queries to
			-- guarantee coverage of the primary query components (1-4)
			if #components == 0 and queryIndex <= 8 then
				componentIndex = ((queryIndex - 1) % 4) + 1
			else
				componentIndex = rng:nextInt(1, componentCount)
			end
			if not used[componentIndex] then
				used[componentIndex] = true
				components[#components + 1] = componentIndex
			end
		end
		queryDefinitions[#queryDefinitions + 1] = components
	end
	return queryDefinitions
end

function Workload.build(config)
	local rng = newRng(config.execution.seed)

	local blueprints = {}
	for entityIndex = 1, config.dataset.entitiesPerRun do
		blueprints[entityIndex] = makeBlueprint(rng, config)
	end

	local updateOps = {}
	for opIndex = 1, config.mutationWorkloads.writesPerPhase do
		local entityIndex = rng:nextInt(1, config.dataset.entitiesPerRun)
		local componentIndex = chooseExistingComponent(rng, blueprints[entityIndex])
		updateOps[opIndex] = {
			entityIndex = entityIndex,
			componentIndex = componentIndex,
			value = rng:nextFloat(),
		}
	end

	local structuralOps = {}
	for opIndex = 1, config.mutationWorkloads.structuralChangesPerPhase do
		structuralOps[opIndex] = {
			entityIndex = rng:nextInt(1, config.dataset.entitiesPerRun),
			componentIndex = rng:nextInt(1, config.dataset.componentsPerWorld),
			value = rng:nextFloat(),
		}
	end

	local randomReadOps = {}
	for readIndex = 1, config.queryWorkloads.randomReadCount do
		randomReadOps[readIndex] = {
			entityIndex = rng:nextInt(1, config.dataset.entitiesPerRun),
			componentIndex = rng:nextInt(1, config.dataset.componentsPerWorld),
		}
	end

	local wideQueryComponents = {}
	for componentIndex = 1, config.queryWorkloads.wideQueryWidth do
		wideQueryComponents[componentIndex] = componentIndex
	end

	return {
		config = config,
		blueprints = blueprints,
		updateOps = updateOps,
		structuralOps = structuralOps,
		randomReadOps = randomReadOps,
		primaryQueryComponents = { 1, 2, 3 },
		wideQueryComponents = wideQueryComponents,
		hotComponent = 1,
		workQueryDefinitions = makeQueryDefinitions(config, rng),
	}
end

return Workload
