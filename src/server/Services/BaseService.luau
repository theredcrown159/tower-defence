--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseConfig = require(ReplicatedStorage.Shared.Config.BaseConfig)
local EnemyService = require(script.Parent.EnemyService)

local BaseService = {}

local healthChangedEvent = Instance.new("BindableEvent")
BaseService.HealthChanged = healthChangedEvent.Event

local baseDestroyedEvent = Instance.new("BindableEvent")
BaseService.BaseDestroyed = baseDestroyedEvent.Event

local health = BaseConfig.MaxHealth
local enemyRemovedConnection: RBXScriptConnection? = nil

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

	if health ~= previousHealth then
		healthChangedEvent:Fire(health, previousHealth, BaseConfig.MaxHealth)
	end

	return true
end

return BaseService
