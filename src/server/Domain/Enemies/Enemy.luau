--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyDefinitions = require(ReplicatedStorage.Shared.Config.EnemyDefinitions)
local PathFollower = require(script.Parent.PathFollower)

type EnemyDefinition = EnemyDefinitions.EnemyDefinition
type PathFollowerType = PathFollower.PathFollower
type EnemyState = "Moving" | "Dead" | "ReachedBase"

local Enemy = {}
Enemy.__index = Enemy

export type Enemy = typeof(setmetatable(
	{} :: {
		_definition: EnemyDefinition,
		_health: number,
		_pathFollower: PathFollowerType,
		_state: EnemyState,
	},
	Enemy
))

function Enemy.new(definition: EnemyDefinition, route: { Vector3 }): Enemy
	if definition.MaxHealth <= 0 then
		error("Enemy MaxHealth must be greater than zero")
	end

	if definition.MoveSpeed < 0 then
		error("Enemy MoveSpeed cannot be negative")
	end

	local self: Enemy = setmetatable({
		_definition = definition,
		_health = definition.MaxHealth,
		_pathFollower = PathFollower.new(route),
		_state = "Moving" :: EnemyState,
	}, Enemy)

	return self
end

function Enemy.Step(self: Enemy, fixedDeltaTime: number)
	if fixedDeltaTime < 0 then
		error("Enemy fixedDeltaTime cannot be negative")
	end

	if self._state ~= "Moving" then
		return
	end

	local distance = self._definition.MoveSpeed * fixedDeltaTime
	local reachedBase = self._pathFollower:Advance(distance)

	if reachedBase then
		self._state = "ReachedBase"
	end
end

function Enemy.GetPosition(self: Enemy): Vector3
	return self._pathFollower:GetPosition()
end

function Enemy.GetDistanceTraveled(self: Enemy): number
	return self._pathFollower:GetDistanceTraveled()
end

function Enemy.HasReachedBase(self: Enemy): boolean
	return self._state == "ReachedBase"
end

function Enemy.IsDead(self: Enemy): boolean
	return self._state == "Dead"
end

function Enemy.TakeDamage(self: Enemy, amount: number): boolean
	if amount < 0 then
		error("Damage cannot be negative")
	end

	if self._state ~= "Moving" then
		return false
	end

	self._health = math.clamp(self._health - amount, 0, self._health)

	if self._health == 0 then
		self._state = "Dead"
		return true
	end

	return false
end

function Enemy.GetHealth(self: Enemy): number
	return self._health
end

function Enemy.GetMaxHealth(self: Enemy): number
	return self._definition.MaxHealth
end

function Enemy.GetBaseDamage(self: Enemy): number
	return self._definition.BaseDamage
end

function Enemy.GetReward(self: Enemy): number
	return self._definition.Reward
end

function Enemy.GetModelName(self: Enemy): string
	return self._definition.ModelName
end

return Enemy
