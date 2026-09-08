--!strict

local Workspace = game:GetService("Workspace")

local EnemyReplicationService = require(script.Parent.Services.EnemyReplicationService)
local EnemyService = require(script.Parent.Services.EnemyService)
local MapService = require(script.Parent.Services.MapService)
local SimulationService = require(script.Parent.Services.SimulationService)
local WaveService = require(script.Parent.Services.WaveService)

EnemyReplicationService.Start()

local mapFolder = Workspace:WaitForChild("MapData", 10)
MapService.Load(mapFolder)

EnemyService.Start()
WaveService.Start()
SimulationService.Start()

WaveService.StartNextWave()
