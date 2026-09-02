--!strict

local SimulationService = require(script.Parent.Services.SimulationService)

local nextLogTime = 1

SimulationService.Stepped:Connect(function(fixedDeltaTime: number, gameTime: number)
	if gameTime >= nextLogTime then
		print(
			"Simulation:",
			"gameTime =",
			gameTime,
			"fixedDeltaTime =",
			fixedDeltaTime,
			"speed =",
			SimulationService.GetSpeed()
		)

		nextLogTime += 1
	end
end)

local started = SimulationService.Start()

assert(started, "SimulationService is already running")
