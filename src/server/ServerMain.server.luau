--!strict

local Workspace = game:GetService("Workspace")

local BaseService = require(script.Parent.Services.BaseService)
local EconomyService = require(script.Parent.Services.EconomyService)
local EnemyReplicationService = require(script.Parent.Services.EnemyReplicationService)
local EnemyService = require(script.Parent.Services.EnemyService)
local MapService = require(script.Parent.Services.MapService)
local SimulationService = require(script.Parent.Services.SimulationService)
local TowerReplicationService = require(script.Parent.Services.TowerReplicationService)
local TowerService = require(script.Parent.Services.TowerService)
local WaveService = require(script.Parent.Services.WaveService)

EnemyReplicationService.Start()
TowerReplicationService.Start()
EconomyService.Start()

local mapFolder = Workspace:WaitForChild("MapData", 10)
MapService.Load(mapFolder)

EnemyService.Start()
BaseService.Start()
TowerService.Start()
WaveService.Start()

BaseService.HealthChanged:Connect(function(currentHealth: number, _previousHealth: number, maxHealth: number)
	print(`Base health: {currentHealth}/{maxHealth}`)
end)

BaseService.BaseDestroyed:Connect(function()
	print("Base destroyed")
	WaveService.Stop()
	TowerService.Stop()
	TowerService.Clear()
	EnemyService.Clear()
	EnemyService.Stop()
end)

SimulationService.Start()

TowerService.Place("Classical", Vector3.new(214.213, -367.609, 226.373), 0)

WaveService.StartNextWave()
