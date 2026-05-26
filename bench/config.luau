return {
	validation = {
		fingerprintState = false,
		autoDetectChecksumMismatches = true,
		checksumRelativeTolerance = 1e-6,
	},

	output = {
		showConfig = true,
		shortConfig = true,
		showMemoryTable = false,
		maxDisplayedRuns = 2,
	},

	execution = {
		seed = 1337,
		runsPerAdapter = 5,
		includeStressScenarios = true,
	},

	garbageCollection = {
		collectBeforeScenario = true,
		collectAfterScenario = true,
	},

	dataset = {
		entitiesPerRun = 2000,
		componentsPerWorld = 16,
		baseComponentFill = 0.55,
		primaryQueryComponentFill = 0.45,
		hotComponentFill = 1.0,
	},

	queryWorkloads = {
		queryIterations = 300,
		wideQueryWidth = 12,
		randomReadCount = 20000,
		multiQueryCount = 12,
		workFrameCount = 60,
		writesPerWorkFrame = 100,
	},

	mutationWorkloads = {
		writesPerPhase = 20000,
		structuralChangesPerPhase = 10000,
	},

	stress = {
		frameCount = 300,
		writePasses = 50,
		structuralPasses = 100,
	},
}
