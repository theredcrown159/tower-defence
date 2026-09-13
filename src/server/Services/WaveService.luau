--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyDefinitions = require(ReplicatedStorage.Shared.Config.EnemyDefinitions)
local EnemyService = require(script.Parent.EnemyService)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SimulationService = require(script.Parent.SimulationService)
local WaveDefinitions = require(ReplicatedStorage.Shared.Config.WaveDefinitions)

type EnemyGroup = WaveDefinitions.EnemyGroup
type WaveDefinition = WaveDefinitions.WaveDefinition
export type WaveState = "Stopped" | "Ready" | "Spawning" | "WaitingForEnemies" | "Intermission" | "Finished"

local WaveService = {}

local MATCH_STATE_NAME = "MatchState"
local WAVE_ATTRIBUTE = "Wave"
local TIME_REMAINING_ATTRIBUTE = "TimeRemaining"
local CAN_SKIP_ATTRIBUTE = "CanSkip"
local SKIP_VOTES_ATTRIBUTE = "SkipVotes"
local SKIP_VOTES_REQUIRED_ATTRIBUTE = "SkipVotesRequired"

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
local waveTimeRemaining = 0
local intermissionRemaining = 0
local currentWaveEnemyIds: { [number]: boolean } = {}
local currentWaveEnemyCount = 0
local skipVotesByUserId: { [number]: boolean } = {}
local simulationConnection: RBXScriptConnection? = nil
local enemyRemovedConnection: RBXScriptConnection? = nil

local function getMatchState(): Folder
	local existing = ReplicatedStorage:FindFirstChild(MATCH_STATE_NAME)

	if existing then
		if not existing:IsA("Folder") then
			error(`ReplicatedStorage.{MATCH_STATE_NAME} must be a Folder`)
		end

		return existing
	end

	local matchState = Instance.new("Folder")
	matchState.Name = MATCH_STATE_NAME
	matchState.Parent = ReplicatedStorage

	return matchState
end

local function replicateWave()
	getMatchState():SetAttribute(WAVE_ATTRIBUTE, currentWaveIndex)
end

local function replicateTimeRemaining(seconds: number)
	local displayedSeconds = math.max(0, math.ceil(seconds))
	local matchState = getMatchState()

	if matchState:GetAttribute(TIME_REMAINING_ATTRIBUTE) ~= displayedSeconds then
		matchState:SetAttribute(TIME_REMAINING_ATTRIBUTE, displayedSeconds)
	end
end

local function canSkipCurrentWave(): boolean
	return state == "WaitingForEnemies"
		and currentWaveIndex < #WaveDefinitions
		and waveTimeRemaining > 0
		and waveTimeRemaining <= GameConfig.SkipVoteDuration
end

local function getRequiredSkipVotes(): number
	return math.max(1, math.floor(#Players:GetPlayers() / 2) + 1)
end

local function getSkipVoteCount(): number
	local count = 0

	for _, player in Players:GetPlayers() do
		if skipVotesByUserId[player.UserId] then
			count += 1
		end
	end

	return count
end

local function replicateSkipState()
	local matchState = getMatchState()
	local canSkip = canSkipCurrentWave()
	local skipVotes = getSkipVoteCount()
	local skipVotesRequired = getRequiredSkipVotes()

	if matchState:GetAttribute(CAN_SKIP_ATTRIBUTE) ~= canSkip then
		matchState:SetAttribute(CAN_SKIP_ATTRIBUTE, canSkip)
	end

	if matchState:GetAttribute(SKIP_VOTES_ATTRIBUTE) ~= skipVotes then
		matchState:SetAttribute(SKIP_VOTES_ATTRIBUTE, skipVotes)
	end

	if matchState:GetAttribute(SKIP_VOTES_REQUIRED_ATTRIBUTE) ~= skipVotesRequired then
		matchState:SetAttribute(SKIP_VOTES_REQUIRED_ATTRIBUTE, skipVotesRequired)
	end
end

local function clearSkipVotes()
	table.clear(skipVotesByUserId)
	replicateSkipState()
end

local function validateDefinitions()
	if #WaveDefinitions == 0 then
		error("WaveDefinitions must contain at least one wave")
	end

	for waveIndex, wave in ipairs(WaveDefinitions) do
		if wave.Duration <= 0 then
			error(`Wave {waveIndex}: Duration must be greater than zero`)
		end

		if #wave.Groups == 0 then
			error(`Wave {waveIndex} must contain at least one enemy group`)
		end

		local spawnDuration = 0

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

			spawnDuration += (group.Count - 1) * group.SpawnInterval
		end

		if wave.Duration <= spawnDuration then
			error(`Wave {waveIndex}: Duration must be longer than its spawn schedule`)
		end
	end
end

local function getCurrentWave(): WaveDefinition?
	return WaveDefinitions[currentWaveIndex]
end

local function getCurrentGroup(): EnemyGroup?
	local wave = getCurrentWave()

	if not wave then
		return nil
	end

	return wave.Groups[currentGroupIndex]
end

local function clearCurrentWaveTracking()
	currentWaveEnemyIds = {}
	currentWaveEnemyCount = 0
end

local function onEnemyRemoved(
	enemyId: number,
	_reason: EnemyService.RemovalReason,
	_baseDamage: number,
	_reward: number
)
	if not currentWaveEnemyIds[enemyId] then
		return
	end

	currentWaveEnemyIds[enemyId] = nil
	currentWaveEnemyCount -= 1
end

local function finishWave(withIntermission: boolean)
	local completedWaveIndex = currentWaveIndex

	if completedWaveIndex >= #WaveDefinitions then
		state = "Finished"
		replicateTimeRemaining(0)
	else
		state = if withIntermission then "Intermission" else "Ready"
		intermissionRemaining = if withIntermission then GameConfig.WaveIntermissionDuration else 0
		replicateTimeRemaining(intermissionRemaining)
	end

	clearSkipVotes()
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
		replicateSkipState()
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

		local enemyId = EnemyService.Spawn(group.EnemyName)
		currentWaveEnemyIds[enemyId] = true
		currentWaveEnemyCount += 1
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

	local nextWaveIndex = currentWaveIndex + 1
	local nextWave = WaveDefinitions[nextWaveIndex]

	if not nextWave then
		return false
	end

	currentWaveIndex = nextWaveIndex
	currentGroupIndex = 1
	spawnedInCurrentGroup = 0
	timeUntilNextSpawn = 0
	waveTimeRemaining = nextWave.Duration
	intermissionRemaining = 0
	clearCurrentWaveTracking()
	state = "Spawning"
	clearSkipVotes()

	replicateWave()
	replicateTimeRemaining(waveTimeRemaining)
	waveStartedEvent:Fire(currentWaveIndex)

	return true
end

local function updateActiveWave(fixedDeltaTime: number)
	waveTimeRemaining = math.max(0, waveTimeRemaining - fixedDeltaTime)
	replicateTimeRemaining(waveTimeRemaining)
	replicateSkipState()

	if state == "Spawning" then
		spawnReadyEnemies(fixedDeltaTime)
	end

	if state ~= "WaitingForEnemies" then
		return
	end

	local isFinalWave = currentWaveIndex >= #WaveDefinitions

	if isFinalWave then
		if EnemyService.GetCount() == 0 then
			finishWave(false)
		end

		return
	end

	if currentWaveEnemyCount == 0 then
		finishWave(true)
	elseif waveTimeRemaining == 0 then
		finishWave(false)
		startNextWave()
	end
end

local function onSimulationStep(fixedDeltaTime: number, _gameTime: number)
	if state == "Spawning" or state == "WaitingForEnemies" then
		updateActiveWave(fixedDeltaTime)
	elseif state == "Intermission" then
		intermissionRemaining = math.max(0, intermissionRemaining - fixedDeltaTime)
		replicateTimeRemaining(intermissionRemaining)

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

function WaveService.GetWaveTimeRemaining(): number
	return waveTimeRemaining
end

function WaveService.GetIntermissionRemaining(): number
	return intermissionRemaining
end

function WaveService.TryVoteSkip(player: Player, wantsToSkip: boolean): boolean
	if not simulationConnection or not player:IsDescendantOf(Players) or not canSkipCurrentWave() then
		return false
	end

	skipVotesByUserId[player.UserId] = if wantsToSkip then true else nil
	replicateSkipState()

	if getSkipVoteCount() < getRequiredSkipVotes() then
		return true
	end

	finishWave(false)

	return startNextWave()
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
	enemyRemovedConnection = EnemyService.EnemyRemoved:Connect(onEnemyRemoved)
	simulationConnection = SimulationService.Stepped:Connect(onSimulationStep)
	replicateWave()
	replicateTimeRemaining(0)
	clearSkipVotes()

	return true
end

function WaveService.Stop(): boolean
	if not simulationConnection then
		return false
	end

	simulationConnection:Disconnect()
	simulationConnection = nil

	if enemyRemovedConnection then
		enemyRemovedConnection:Disconnect()
		enemyRemovedConnection = nil
	end

	state = "Stopped"
	replicateTimeRemaining(0)
	clearSkipVotes()

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
	waveTimeRemaining = 0
	intermissionRemaining = 0
	clearCurrentWaveTracking()
	state = "Stopped"
	replicateWave()
	replicateTimeRemaining(0)
	clearSkipVotes()

	return true
end

return WaveService
