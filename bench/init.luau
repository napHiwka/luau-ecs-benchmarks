local Runner = require("./bench/shared/runner")
local Reporter = require("./bench/shared/reporter")

local adapterSpecs = {
	{
		adapterPath = "./bench/adapters/table-based",
		libraryPath = "./bench/libraries/_empty/",
	},
	{
		adapterPath = "./bench/adapters/hash-based",
		libraryPath = "./bench/libraries/_empty/",
	},
	{
		adapterPath = "./bench/adapters/sparse-based",
		libraryPath = "./bench/libraries/_empty/",
	},
	{
		adapterPath = "./bench/adapters/concord",
		libraryPath = "./bench/libraries/concord/",
	},
	{
		adapterPath = "./bench/adapters/rune",
		libraryPath = "./bench/libraries/rune/",
	},
	{
		adapterPath = "./bench/adapters/alecs",
		libraryPath = "./bench/libraries/alecs/",
	},
	{
		adapterPath = "./bench/adapters/lovetoys",
		libraryPath = "./bench/libraries/lovetoys/",
	},
	{
		adapterPath = "./bench/adapters/tiny-ecs-reuse",
		libraryPath = "./bench/libraries/tiny-ecs/",
	},
	{
		adapterPath = "./bench/adapters/tiny-ecs-no-reuse",
		libraryPath = "./bench/libraries/tiny-ecs/",
	},
	{
		adapterPath = "./bench/adapters/evolved",
		libraryPath = "./bench/libraries/evolved/",
	},
	-- {
	-- 	adapterPath = "./bench/adapters/ecs-lua",
	-- 	libraryPath = "./bench/libraries/ecs-lua/",
	-- },
	{
		adapterPath = "./bench/adapters/ecs-lib",
		libraryPath = "./bench/libraries/ecs-lib/",
	},
}

local adapters = {}
for index = 1, #adapterSpecs do
	local spec = adapterSpecs[index]
	local adapterOk, adapterFactory = pcall(require, spec.adapterPath)
	local libraryOk, libraryModule = pcall(require, spec.libraryPath)
	if adapterOk and libraryOk then
		adapters[#adapters + 1] = adapterFactory(libraryModule)
	else
		local reason = if not adapterOk then adapterFactory else libraryModule
		print(string.format("Skipping %s: %s", spec.adapterPath, tostring(reason)))
	end
end

if #adapters == 0 then
	error("no benchmark adapters could be loaded")
end

Reporter.printConfig(Runner.getConfig())

local allSummaries = {}

for index = 1, #adapters do
	local adapter = adapters[index]
	Reporter.printSection("Running " .. adapter.name .. "...")
	local report = Runner.runAdapter(adapter)
	Reporter.printAdapterHeader(adapter)

	for runIndex = 1, #report.runs do
		Reporter.printRun(runIndex, #report.runs, report.runs[runIndex])
	end
	Reporter.printAggregate(report.summary, adapter.name)

	report.summary.adapterName = adapter.name
	allSummaries[#allSummaries + 1] = report.summary
end

if #adapters > 1 then
	Reporter.printSummaryTable(allSummaries)
end
