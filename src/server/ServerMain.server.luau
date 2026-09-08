--!strict

local Workspace = game:GetService("Workspace")

local EnemyReplicationService = require(script.Parent.Services.EnemyReplicationService)
local EnemyService = require(script.Parent.Services.EnemyService)
local MapService = require(script.Parent.Services.MapService)
local SimulationService = require(script.Parent.Services.SimulationService)

EnemyReplicationService.Start()

local mapFolder = Workspace:WaitForChild("MapData", 10)
MapService.Load(mapFolder)

EnemyService.Start()
SimulationService.Start()

local TEST_ENEMY_COUNT = 400
local SPAWN_DELAY = 0.03

task.spawn(function()
	for _ = 1, TEST_ENEMY_COUNT do
		EnemyService.Spawn("Basic")

		if SPAWN_DELAY > 0 then
			task.wait(SPAWN_DELAY)
		end
	end
end)
