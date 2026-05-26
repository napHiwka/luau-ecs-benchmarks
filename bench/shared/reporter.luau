local Reporter = {}

local function printConfigSection(title, lines)
	print(title)
	for index = 1, #lines do
		print("  " .. lines[index])
	end
	print("")
end

local function formatNumber(value)
	return string.format("%.4f", value)
end

local function makeSampler(seed)
	local state = seed % 2147483647
	if state <= 0 then
		state = 1
	end
	return function(max)
		state = (state * 48271) % 2147483647
		return (state % max) + 1
	end
end

function Reporter.printSection(title)
	print(title)
	print(string.rep("-", #title))
end

local function printConfigShort(config)
	local exec = config.execution
	local dataset = config.dataset
	local query = config.queryWorkloads
	local mutation = config.mutationWorkloads
	local stress = config.stress
	local validat = config.validation

	print(
		string.format(
			"Benchmark Configuration: `seed %d` `runs %d` `stress %s` `fingerprint %s`",
			exec.seed,
			exec.runsPerAdapter,
			exec.includeStressScenarios and "on" or "off",
			validat.fingerprintState and "on" or "off"
		)
	)
	print(
		string.format(
			"dataset: `entities %d` `components %d` fill: `base=%.2f` `query=%.2f` `hot=%.2f`",
			dataset.entitiesPerRun,
			dataset.componentsPerWorld,
			dataset.baseComponentFill,
			dataset.primaryQueryComponentFill,
			dataset.hotComponentFill
		)
	)
	print(
		string.format(
			"workloads: `query-iter %d`  `wide %d`  `rand-reads %d` `frames %d`",
			query.queryIterations,
			query.wideQueryWidth,
			query.randomReadCount,
			query.workFrameCount
		)
	)
	print(
		string.format(
			"workloads: `writes/frame %d` `mutations %d/%d` `stress-frames %d`",
			query.writesPerWorkFrame,
			mutation.writesPerPhase,
			mutation.structuralChangesPerPhase,
			stress.frameCount
		)
	)
	print("")
end

function Reporter.printConfig(config)
	if config.output.shortConfig then
		printConfigShort(config)
		return
	end

	Reporter.printSection("Benchmark Configuration")
	printConfigSection("Output", {
		string.format("show config: %s", tostring(config.output.showConfig)),
		string.format("max displayed runs: %d", config.output.maxDisplayedRuns),
		string.format("show memory table: %s", tostring(config.output.showMemoryTable)),
	})
	printConfigSection("Validation", {
		string.format("fingerprint state: %s", tostring(config.validation.fingerprintState)),
		string.format("auto-detect checksum mismatches: %s", tostring(config.validation.autoDetectChecksumMismatches)),
		string.format("checksum relative tolerance: %.2g", config.validation.checksumRelativeTolerance),
	})
	printConfigSection("Execution", {
		string.format("seed: %d", config.execution.seed),
		string.format("runs per adapter: %d", config.execution.runsPerAdapter),
		string.format("include stress scenarios: %s", tostring(config.execution.includeStressScenarios)),
	})
	printConfigSection("Garbage Collection", {
		string.format("collect before scenario: %s", tostring(config.garbageCollection.collectBeforeScenario)),
		string.format("collect after scenario:  %s", tostring(config.garbageCollection.collectAfterScenario)),
	})
	printConfigSection("Dataset", {
		string.format("entities per run: %d", config.dataset.entitiesPerRun),
		string.format("components per world: %d", config.dataset.componentsPerWorld),
		string.format("base component fill: %.2f", config.dataset.baseComponentFill),
		string.format("primary query fill: %.2f", config.dataset.primaryQueryComponentFill),
		string.format("hot component fill: %.2f", config.dataset.hotComponentFill),
	})
	printConfigSection("Query Workloads", {
		string.format("query iterations: %d", config.queryWorkloads.queryIterations),
		string.format("wide query width: %d", config.queryWorkloads.wideQueryWidth),
		string.format("random read count: %d", config.queryWorkloads.randomReadCount),
		string.format("work query count: %d", config.queryWorkloads.multiQueryCount),
		string.format("work frame count: %d", config.queryWorkloads.workFrameCount),
		string.format("writes per work frame: %d", config.queryWorkloads.writesPerWorkFrame),
	})
	printConfigSection("Mutation Workloads", {
		string.format("writes per phase: %d", config.mutationWorkloads.writesPerPhase),
		string.format("structural changes per phase: %d", config.mutationWorkloads.structuralChangesPerPhase),
	})
	printConfigSection("Stress", {
		string.format("frame count: %d", config.stress.frameCount),
		string.format("write passes: %d", config.stress.writePasses),
		string.format("structural passes: %d", config.stress.structuralPasses),
	})
end

function Reporter.getDisplayedRunIndexes(config, runCount)
	local maxDisplayedRuns = config.output.maxDisplayedRuns or runCount
	if maxDisplayedRuns <= 0 then
		return {}
	end
	if runCount <= maxDisplayedRuns then
		local all = {}
		for index = 1, runCount do
			all[index] = index
		end
		return all
	end

	local selected = {}
	local selectedSet = {}
	local nextRandom = makeSampler(config.execution.seed + runCount * 97)
	while #selected < maxDisplayedRuns do
		local runIndex = nextRandom(runCount)
		if not selectedSet[runIndex] then
			selectedSet[runIndex] = true
			selected[#selected + 1] = runIndex
		end
	end
	table.sort(selected)
	return selected
end

function Reporter.printAdapterReport(config, adapter, report)
	Reporter.printAdapterHeader(adapter)

	local runs = report.runs
	local displayedRuns = Reporter.getDisplayedRunIndexes(config, #runs)
	for displayIndex = 1, #displayedRuns do
		local runIndex = displayedRuns[displayIndex]
		Reporter.printRun(runIndex, #runs, runs[runIndex], displayIndex == 1)
	end
	Reporter.printAggregate(report.summary, adapter.name)
end

function Reporter.printAdapterHeader(adapter)
	if adapter.note and adapter.note ~= "" then
		print("Note: " .. adapter.note .. "\n")
	end
end

function Reporter.printRun(runIndex, runCount, results, includeResult)
	print(string.format("Run %d/%d", runIndex, runCount))
	local totalMemKB = 0
	for resultIndex = 1, #results do
		local result = results[resultIndex]
		local line = string.format("  %-24s %9.4f s", result.name, result.seconds)
		if includeResult then
			line = line .. string.format("  checksum %.2f", result.checksum)
			if result.verifyCount > 0 then
				line = line .. string.format("  verify %d / %.3f", result.verifyCount, result.verifySum)
			end
		end

		totalMemKB = totalMemKB + result.memoryDeltaKB
		print(line)
	end
	print(string.format("  %-27s %.1f KB", "total_memory", totalMemKB))
	print("")
end

function Reporter.printAggregate(summary, adapterName)
	local timingFmt = "  %-24s mean %7s  p50 %7s  p90 %7s  p95 %7s  min %7s  max %7s"
	Reporter.printSection(string.format("Aggregated (%s)", adapterName))

	for scenarioIndex = 1, #summary.scenarios do
		local scenario = summary.scenarios[scenarioIndex]
		local t = scenario.timing
		print(
			string.format(
				timingFmt,
				scenario.name,
				formatNumber(t.mean),
				formatNumber(t.p50),
				formatNumber(t.p90),
				formatNumber(t.p95),
				formatNumber(t.min),
				formatNumber(t.max)
			)
		)
	end
	local total = summary.totalTiming
	print(
		string.format(
			timingFmt,
			"total",
			formatNumber(total.mean),
			formatNumber(total.p50),
			formatNumber(total.p90),
			formatNumber(total.p95),
			formatNumber(total.min),
			formatNumber(total.max)
		)
	)
	print("")
end

function Reporter.printSummaryTable(config, allSummaries)
	if #allSummaries == 0 then
		return
	end

	local MAX_LINE_WIDTH = 110
	local COL_WIDTH = 10 -- "X.XXXX" = 8 chars + 2 sep = 10
	local SEP = "  "

	local scenarioNames = {}
	for scenarioIndex = 1, #allSummaries[1].scenarios do
		scenarioNames[#scenarioNames + 1] = allSummaries[1].scenarios[scenarioIndex].name
	end
	scenarioNames[#scenarioNames + 1] = "total"

	local adapterNames = {}
	for summaryIndex = 1, #allSummaries do
		adapterNames[#adapterNames + 1] = allSummaries[summaryIndex].adapterName or "Unknown"
	end

	local maxScenarioWidth = 0
	for _, name in ipairs(scenarioNames) do
		maxScenarioWidth = math.max(maxScenarioWidth, #name)
	end

	-- Split adapters into groups that fit within MAX_LINE_WIDTH
	local groups = {}
	local currentGroup = {}
	local currentWidth = maxScenarioWidth
	for i, name in ipairs(adapterNames) do
		local colWidth = #SEP + math.max(COL_WIDTH, #name)
		if #currentGroup > 0 and currentWidth + colWidth > MAX_LINE_WIDTH then
			groups[#groups + 1] = currentGroup
			currentGroup = {}
			currentWidth = maxScenarioWidth
		end
		currentGroup[#currentGroup + 1] = i
		currentWidth = currentWidth + colWidth
	end
	if #currentGroup > 0 then
		groups[#groups + 1] = currentGroup
	end

	local function printTableHeader(group)
		local header = string.format("%-" .. maxScenarioWidth .. "s", "Scenario")
		for _, idx in ipairs(group) do
			local colWidth = math.max(COL_WIDTH, #adapterNames[idx])
			header = header .. SEP .. string.format("%" .. colWidth .. "s", adapterNames[idx])
		end
		print(header)
		print(string.rep("-", #header))
	end

	local function getTimingP50(summary, scenarioName)
		if scenarioName == "total" then
			return summary.totalTiming.p50
		end
		for _, scenario in ipairs(summary.scenarios) do
			if scenario.name == scenarioName then
				return scenario.timing.p50
			end
		end
	end

	local function getMemoryP50(summary, scenarioName)
		for _, scenario in ipairs(summary.scenarios) do
			if scenario.name == scenarioName and scenario.memory.count > 0 then
				return scenario.memory.p50
			end
		end
	end

	-- Timing table
	print("Summary Table (P50) seconds\n")
	for _, group in ipairs(groups) do
		printTableHeader(group)
		for _, scenarioName in ipairs(scenarioNames) do
			local row = string.format("%-" .. maxScenarioWidth .. "s", scenarioName)
			for _, idx in ipairs(group) do
				local colWidth = math.max(COL_WIDTH, #adapterNames[idx])
				local timing = getTimingP50(allSummaries[idx], scenarioName)
				if timing then
					row = row .. SEP .. string.format("%" .. colWidth .. ".4f", timing)
				else
					row = row .. SEP .. string.format("%" .. colWidth .. "s", "N/A")
				end
			end
			print(row)
		end
		print("")
	end

	-- Per-scenario memory table
	if not config.output.showMemoryTable then
		return
	end

	print("Memory Table (P50) KB\n")
	for _, group in ipairs(groups) do
		printTableHeader(group)
		for scenarioIndex = 1, #scenarioNames - 1 do
			local scenarioName = scenarioNames[scenarioIndex]
			local row = string.format("%-" .. maxScenarioWidth .. "s", scenarioName)
			for _, idx in ipairs(group) do
				local colWidth = math.max(COL_WIDTH, #adapterNames[idx])
				local memory = getMemoryP50(allSummaries[idx], scenarioName)
				if memory then
					row = row .. SEP .. string.format("%" .. colWidth .. ".4f", memory)
				else
					row = row .. SEP .. string.format("%" .. colWidth .. "s", "N/A")
				end
			end
			print(row)
		end
		print("")
	end
end

function Reporter.printChecksumWarnings(allSummaries, relativeTolerance)
	-- majority-vote identification of outliers requires at least 3 adapters
	if #allSummaries < 3 then
		return
	end

	local tolerance = relativeTolerance or 1e-6
	local warnings = {}

	for scenarioIndex = 1, #allSummaries[1].scenarios do
		local scenarioName = allSummaries[1].scenarios[scenarioIndex].name
		local groups = {}
		for summaryIndex = 1, #allSummaries do
			local summary = allSummaries[summaryIndex]
			local scenario = summary.scenarios[scenarioIndex]
			local checksum = scenario and scenario.checksum and scenario.checksum.p50
			if checksum then
				local matched
				for groupIndex = 1, #groups do
					local group = groups[groupIndex]
					local scale = math.max(1, math.abs(group.value), math.abs(checksum))
					if math.abs(group.value - checksum) <= scale * tolerance then
						group.adapters[#group.adapters + 1] = summary.adapterName or "Unknown"
						matched = true
						break
					end
				end
				if not matched then
					groups[#groups + 1] = {
						value = checksum,
						adapters = { summary.adapterName or "Unknown" },
					}
				end
			end
		end

		if #groups >= 2 then
			table.sort(groups, function(left, right)
				return #left.adapters > #right.adapters
			end)
			local majority = groups[1]
			local tied = groups[2] and #groups[2].adapters == #majority.adapters
			if #majority.adapters >= 2 and not tied then
				for groupIndex = 2, #groups do
					local group = groups[groupIndex]
					warnings[#warnings + 1] = string.format(
						"  %s: expected near %.2f from %s; got %.2f from %s",
						scenarioName,
						majority.value,
						table.concat(majority.adapters, ", "),
						group.value,
						table.concat(group.adapters, ", ")
					)
				end
			end
		end
	end

	if #warnings == 0 then
		return
	end

	Reporter.printSection("Checksum Warnings")
	for index = 1, #warnings do
		print(warnings[index])
	end
	print("")
end

return Reporter
