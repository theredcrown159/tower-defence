--!strict

local Workspace = game:GetService("Workspace")

local BaseService = require(script.Parent.Services.BaseService)
local EconomyService = require(script.Parent.Services.EconomyService)
local EnemyReplicationService = require(script.Parent.Services.EnemyReplicationService)
local EnemyService = require(script.Parent.Services.EnemyService)
local GameSpeedReplicationService = require(script.Parent.Services.GameSpeedReplicationService)
local MapService = require(script.Parent.Services.MapService)
local SimulationService = require(script.Parent.Services.SimulationService)
local TowerReplicationService = require(script.Parent.Services.TowerReplicationService)
local TowerService = require(script.Parent.Services.TowerService)
local WaveReplicationService = require(script.Parent.Services.WaveReplicationService)
local WaveService = require(script.Parent.Services.WaveService)

type MatchResult = "Victory" | "Defeat"

local mapFolder = Workspace:WaitForChild("MapData", 10)

if not mapFolder or not mapFolder:IsA("Folder") then
	error("MapData folder was not found")
end

if not MapService.Load(mapFolder) then
	error("MapData is invalid")
end

EnemyReplicationService.Start()
TowerReplicationService.Start()
EconomyService.Start()
GameSpeedReplicationService.Start()

EnemyService.Start()
BaseService.Start()
TowerService.Start()
WaveService.Start()
WaveReplicationService.Start()

local matchFinished = false

local function finishMatch(result: MatchResult)
	if matchFinished then
		return
	end

	matchFinished = true
	print("Match finished: " .. result)

	SimulationService.Stop()
	GameSpeedReplicationService.Stop()
	WaveService.Stop()
	TowerService.Stop()
	EnemyService.Stop()
	BaseService.Stop()

	if result == "Defeat" then
		TowerService.Clear()
		EnemyService.Clear()
	end
end

BaseService.HealthChanged:Connect(function(currentHealth: number, _previousHealth: number, maxHealth: number)
	print(`Base health: {currentHealth}/{maxHealth}`)
end)

BaseService.BaseDestroyed:Connect(function()
	finishMatch("Defeat")
end)

WaveService.AllWavesCompleted:Connect(function()
	finishMatch("Victory")
end)

SimulationService.Start()

WaveService.StartNextWave()
