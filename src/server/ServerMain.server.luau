--!strict

local Workspace = game:GetService("Workspace")

local BaseService = require(script.Parent.Services.BaseService)
local EnemyReplicationService = require(script.Parent.Services.EnemyReplicationService)
local EnemyService = require(script.Parent.Services.EnemyService)
local MapService = require(script.Parent.Services.MapService)
local SimulationService = require(script.Parent.Services.SimulationService)
local WaveService = require(script.Parent.Services.WaveService)

EnemyReplicationService.Start()

local mapFolder = Workspace:WaitForChild("MapData", 10)
MapService.Load(mapFolder)

EnemyService.Start()
BaseService.Start()
WaveService.Start()

BaseService.HealthChanged:Connect(function(currentHealth: number, _previousHealth: number, maxHealth: number)
	print(`[Base] Health: {currentHealth}/{maxHealth}`)
end)

BaseService.BaseDestroyed:Connect(function()
	print("[Base] Destroyed")
	WaveService.Stop()
	EnemyService.Clear()
	EnemyService.Stop()
end)

SimulationService.Start()

WaveService.StartNextWave()
