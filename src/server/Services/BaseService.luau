--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseConfig = require(ReplicatedStorage.Shared.Config.BaseConfig)
local EnemyService = require(script.Parent.EnemyService)

local BaseService = {}

local MATCH_STATE_NAME = "MatchState"
local HEALTH_ATTRIBUTE = "BaseHealth"
local MAX_HEALTH_ATTRIBUTE = "BaseMaxHealth"

local healthChangedEvent = Instance.new("BindableEvent")
BaseService.HealthChanged = healthChangedEvent.Event

local baseDestroyedEvent = Instance.new("BindableEvent")
BaseService.BaseDestroyed = baseDestroyedEvent.Event

local health = BaseConfig.MaxHealth
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

local function replicateHealth()
	local matchState = getMatchState()
	matchState:SetAttribute(HEALTH_ATTRIBUTE, health)
	matchState:SetAttribute(MAX_HEALTH_ATTRIBUTE, BaseConfig.MaxHealth)
end

local function onEnemyRemoved(_enemyId: number, reason: EnemyService.RemovalReason, baseDamage: number, _reward: number)
	if reason == "ReachedBase" then
		BaseService.Damage(baseDamage)
	end
end

function BaseService.GetHealth(): number
	return health
end

function BaseService.GetMaxHealth(): number
	return BaseConfig.MaxHealth
end

function BaseService.IsDestroyed(): boolean
	return health <= 0
end

function BaseService.IsRunning(): boolean
	return enemyRemovedConnection ~= nil
end

function BaseService.Damage(amount: number): boolean
	if amount < 0 then
		error("Base damage cannot be negative")
	end

	if amount == 0 or health <= 0 then
		return false
	end

	local previousHealth = health
	health = math.max(0, health - amount)
	replicateHealth()

	healthChangedEvent:Fire(health, previousHealth, BaseConfig.MaxHealth)

	if health == 0 then
		baseDestroyedEvent:Fire()
	end

	return true
end

function BaseService.Start(): boolean
	if enemyRemovedConnection then
		return false
	end

	if BaseConfig.MaxHealth <= 0 then
		error("BaseConfig.MaxHealth must be greater than zero")
	end

	enemyRemovedConnection = EnemyService.EnemyRemoved:Connect(onEnemyRemoved)
	replicateHealth()

	return true
end

function BaseService.Stop(): boolean
	if not enemyRemovedConnection then
		return false
	end

	enemyRemovedConnection:Disconnect()
	enemyRemovedConnection = nil

	return true
end

function BaseService.Reset(): boolean
	if enemyRemovedConnection then
		return false
	end

	local previousHealth = health
	health = BaseConfig.MaxHealth
	replicateHealth()

	if health ~= previousHealth then
		healthChangedEvent:Fire(health, previousHealth, BaseConfig.MaxHealth)
	end

	return true
end

return BaseService
