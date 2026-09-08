--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyDefinitions = require(ReplicatedStorage.Shared.Config.EnemyDefinitions)
local EnemyService = require(script.Parent.EnemyService)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SimulationService = require(script.Parent.SimulationService)
local WaveDefinitions = require(ReplicatedStorage.Shared.Config.WaveDefinitions)

type EnemyGroup = WaveDefinitions.EnemyGroup
export type WaveState = "Stopped" | "Ready" | "Spawning" | "WaitingForEnemies" | "Intermission" | "Finished"

local WaveService = {}

local waveStartedEvent = Instance.new("BindableEvent")
WaveService.WaveStarted = waveStartedEvent.Event

local waveCompletedEvent = Instance.new("BindableEvent")
WaveService.WaveCompleted = waveCompletedEvent.Event

local allWavesCompletedEvent = Instance.new("BindableEvent")
WaveService.AllWavesCompleted = allWavesCompletedEvent.Event

local state: WaveState = "Stopped"
local currentWaveIndex = 0
local currentGroupIndex = 0
local spawnedInCurrentGroup = 0
local timeUntilNextSpawn = 0
local intermissionRemaining = 0
local simulationConnection: RBXScriptConnection? = nil

local function validateDefinitions()
	if #WaveDefinitions == 0 then
		error("WaveDefinitions must contain at least one wave")
	end

	for waveIndex, wave in ipairs(WaveDefinitions) do
		if #wave.Groups == 0 then
			error(`Wave {waveIndex} must contain at least one enemy group`)
		end

		for groupIndex, group in ipairs(wave.Groups) do
			if not EnemyDefinitions[group.EnemyName] then
				error(`Wave {waveIndex}, group {groupIndex}: unknown enemy "{group.EnemyName}"`)
			end

			if group.Count <= 0 or group.Count % 1 ~= 0 then
				error(`Wave {waveIndex}, group {groupIndex}: Count must be a positive integer`)
			end

			if group.SpawnInterval < 0 then
				error(`Wave {waveIndex}, group {groupIndex}: SpawnInterval cannot be negative`)
			end
		end
	end
end

local function getCurrentGroup(): EnemyGroup?
	local wave = WaveDefinitions[currentWaveIndex]

	if not wave then
		return nil
	end

	return wave.Groups[currentGroupIndex]
end

local function finishWave()
	local completedWaveIndex = currentWaveIndex

	if completedWaveIndex >= #WaveDefinitions then
		state = "Finished"
	else
		state = "Intermission"
		intermissionRemaining = GameConfig.WaveIntermissionDuration
	end

	waveCompletedEvent:Fire(completedWaveIndex)

	if state == "Finished" then
		allWavesCompletedEvent:Fire()
	end
end

local function advanceToNextGroup()
	currentGroupIndex += 1
	spawnedInCurrentGroup = 0

	if getCurrentGroup() then
		timeUntilNextSpawn = 0
	else
		state = "WaitingForEnemies"
	end
end

local function spawnReadyEnemies(fixedDeltaTime: number)
	timeUntilNextSpawn -= fixedDeltaTime

	while state == "Spawning" and timeUntilNextSpawn <= 0 do
		local group = getCurrentGroup()

		if not group then
			state = "WaitingForEnemies"
			break
		end

		EnemyService.Spawn(group.EnemyName)
		spawnedInCurrentGroup += 1

		if spawnedInCurrentGroup >= group.Count then
			advanceToNextGroup()
		else
			timeUntilNextSpawn += group.SpawnInterval
		end
	end
end

local function startNextWave(): boolean
	if state ~= "Ready" and state ~= "Intermission" then
		return false
	end

	if EnemyService.GetCount() > 0 then
		return false
	end

	local nextWaveIndex = currentWaveIndex + 1

	if not WaveDefinitions[nextWaveIndex] then
		state = "Finished"
		return false
	end

	currentWaveIndex = nextWaveIndex
	currentGroupIndex = 1
	spawnedInCurrentGroup = 0
	timeUntilNextSpawn = 0
	intermissionRemaining = 0
	state = "Spawning"

	waveStartedEvent:Fire(currentWaveIndex)

	return true
end

local function onSimulationStep(fixedDeltaTime: number, _gameTime: number)
	if state == "Spawning" then
		spawnReadyEnemies(fixedDeltaTime)
	elseif state == "WaitingForEnemies" and EnemyService.GetCount() == 0 then
		finishWave()
	elseif state == "Intermission" then
		intermissionRemaining = math.max(0, intermissionRemaining - fixedDeltaTime)

		if intermissionRemaining == 0 then
			startNextWave()
		end
	end
end

function WaveService.GetState(): WaveState
	return state
end

function WaveService.GetCurrentWaveIndex(): number
	return currentWaveIndex
end

function WaveService.GetWaveCount(): number
	return #WaveDefinitions
end

function WaveService.GetIntermissionRemaining(): number
	return intermissionRemaining
end

function WaveService.IsRunning(): boolean
	return simulationConnection ~= nil
end

function WaveService.StartNextWave(): boolean
	if not simulationConnection then
		return false
	end

	return startNextWave()
end

function WaveService.Start(): boolean
	if simulationConnection then
		return false
	end

	if not EnemyService.IsRunning() then
		error("WaveService cannot start before EnemyService")
	end

	validateDefinitions()

	state = if currentWaveIndex >= #WaveDefinitions then "Finished" else "Ready"
	simulationConnection = SimulationService.Stepped:Connect(onSimulationStep)

	return true
end

function WaveService.Stop(): boolean
	if not simulationConnection then
		return false
	end

	simulationConnection:Disconnect()
	simulationConnection = nil
	state = "Stopped"

	return true
end

function WaveService.Reset(): boolean
	if simulationConnection then
		return false
	end

	currentWaveIndex = 0
	currentGroupIndex = 0
	spawnedInCurrentGroup = 0
	timeUntilNextSpawn = 0
	intermissionRemaining = 0
	state = "Stopped"

	return true
end

return WaveService
