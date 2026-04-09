local Runner = require("./bench/shared/runner")
local Reporter = require("./bench/shared/reporter")

local adapterSpecs = {
	{
		name = "tiny-ecs-reuse",
		adapterPath = "./bench/adapters/tiny-ecs-reuse",
		libraryPath = "./bench/libraries/tiny-ecs/",
	},
	{
		name = "tiny-ecs-no-reuse",
		adapterPath = "./bench/adapters/tiny-ecs-no-reuse",
		libraryPath = "./bench/libraries/tiny-ecs/",
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

for index = 1, #adapters do
	local adapter = adapters[index]
	local report = Runner.runAdapter(adapter)

	Reporter.printAdapterHeader(adapter, #report.runs)
	for runIndex = 1, #report.runs do
		Reporter.printRun(runIndex, #report.runs, report.runs[runIndex])
	end
	Reporter.printAggregate(report.summary)
end
