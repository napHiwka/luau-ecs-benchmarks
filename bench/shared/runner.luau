local Stats = require("./stats")
local Workload = require("./workload")
local Scenarios = require("./scenarios")
local config = require("../config")
local Runner = {}

local spec = Workload.build(config)
local scenarioFunctions = Scenarios.build(spec)

function Runner.loadAdapters(adapterSpecs)
	local adapters = {}
	for index = 1, #adapterSpecs do
		local spec = adapterSpecs[index]
		local ok, result = pcall(function()
			local adapterFactory = require(spec.adapterPath)
			local libraryModule
			if spec.libraryPath then
				libraryModule = require(spec.libraryPath)
			else
				print(string.format("No library path provided for %s, using empty library", spec.adapterPath))
				libraryModule = require("../libraries/_empty")
			end
			return adapterFactory(libraryModule)
		end)

		if ok then
			adapters[#adapters + 1] = result
		else
			print(string.format("Skipping %s: %s\n", spec.adapterPath, tostring(result)))
		end
	end
	print("")
	if #adapters == 0 then
		error("no benchmark adapters could be loaded")
	end
	return adapters
end

local function summarizeRuns(runResults)
	local scenarioSummaries = {}
	local totalTimes = {}
	for runIndex = 1, #runResults do
		local totalTime = 0
		local results = runResults[runIndex]
		for scenarioIndex = 1, #results do
			local result = results[scenarioIndex]
			totalTime = totalTime + result.seconds
			local summary = scenarioSummaries[scenarioIndex]
			if not summary then
				summary = {
					name = result.name,
					seconds = {},
					memoryDeltaKB = {},
					checksums = {},
				}
				scenarioSummaries[scenarioIndex] = summary
			end
			summary.seconds[#summary.seconds + 1] = result.seconds
			summary.memoryDeltaKB[#summary.memoryDeltaKB + 1] = result.memoryDeltaKB
			summary.checksums[#summary.checksums + 1] = result.checksum
		end
		totalTimes[#totalTimes + 1] = totalTime
	end

	for scenarioIndex = 1, #scenarioSummaries do
		local summary = scenarioSummaries[scenarioIndex]
		summary.timing = Stats.summarize(summary.seconds)
		summary.memory = Stats.summarize(summary.memoryDeltaKB)
		summary.checksum = Stats.summarize(summary.checksums)
	end

	return {
		scenarios = scenarioSummaries,
		totalTiming = Stats.summarize(totalTimes),
	}
end

function Runner.runAdapter(adapter)
	local runResults = {}
	for runIndex = 1, config.execution.runsPerAdapter do
		local results = {}
		for scenarioIndex = 1, #scenarioFunctions do
			results[scenarioIndex] = scenarioFunctions[scenarioIndex](adapter, spec)
		end
		runResults[runIndex] = results
	end
	return {
		runs = runResults,
		summary = summarizeRuns(runResults),
	}
end

function Runner.runAll(adapters, Reporter)
	local allSummaries = {}
	local maxDisplayedRuns = config.output.maxDisplayedRuns
	local totalRuns = config.execution.runsPerAdapter

	if maxDisplayedRuns < totalRuns then
		print(
			string.format(
				"Will display %d of %d runs. Aggregate statistics include all runs.\n",
				maxDisplayedRuns,
				totalRuns
			)
		)
	end

	for index = 1, #adapters do
		local adapter = adapters[index]
		Reporter.printSection("Running " .. adapter.name .. "...")
		local report = Runner.runAdapter(adapter)
		Reporter.printAdapterReport(config, adapter, report)
		report.summary.adapterName = adapter.name
		allSummaries[#allSummaries + 1] = report.summary
	end

	if #adapters > 1 then
		Reporter.printSummaryTable(config, allSummaries)
	end

	if config.validation.autoDetectChecksumMismatches then
		Reporter.printChecksumWarnings(allSummaries, config.validation.checksumRelativeTolerance)
	end
end

function Runner.getConfig()
	return config
end

return Runner
