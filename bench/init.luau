local Runner = require("./bench/shared/runner")
local Reporter = require("./bench/shared/reporter")

local adapterSpecs = {
	-- Links to libs can be found `bootstrap\libs_urls.json`. Some
	-- libs are commented out because they take a long time to run
	-- with the default settings or can'be run in luau without changes.
	{
		adapterPath = "../adapters/ecr",
		libraryPath = "../libraries/ecr",
	},
	{
		adapterPath = "../adapters/jecs",
		libraryPath = "../libraries/jecs",
	},
	{
		adapterPath = "../adapters/table-based",
		libraryPath = "../libraries/_empty",
	},
	{
		adapterPath = "../adapters/hash-based",
		libraryPath = "../libraries/_empty",
	},
	{
		adapterPath = "../adapters/sparse-based",
		libraryPath = "../libraries/_empty",
	},
	{
		adapterPath = "../adapters/tiny-ecs",
		libraryPath = "../libraries/tiny-ecs/",
	},
	{
		adapterPath = "../adapters/alecs",
		libraryPath = "../libraries/alecs/",
	},
	{
		adapterPath = "../adapters/rune",
		libraryPath = "../libraries/rune/",
	},
	{
		adapterPath = "../adapters/concord",
		libraryPath = "../libraries/concord/",
	},
	{
		adapterPath = "../adapters/lovetoys",
		libraryPath = "../libraries/lovetoys/",
	},
	-- {
	-- 	adapterPath = "../adapters/tiny-ecs-no-reuse",
	-- 	libraryPath = "../libraries/tiny-ecs/",
	-- },
	-- {
	-- 	adapterPath = "../adapters/evolved",
	-- 	libraryPath = "../libraries/evolved/",
	-- },
	-- { -- Needs manual changes in lib to run correctly; check adapter.
	-- 	adapterPath = "../adapters/ecs-lua",
	-- 	libraryPath = "../libraries/ecs-lua/",
	-- },
	-- {
	-- 	adapterPath = "../adapters/ecs-lib",
	-- 	libraryPath = "../libraries/ecs-lib/",
	-- },
}

local config = Runner.getConfig()
local adapters = Runner.loadAdapters(adapterSpecs)

if config.output.showConfig then
	Reporter.printConfig(config)
end

Runner.runAll(adapters, Reporter)
