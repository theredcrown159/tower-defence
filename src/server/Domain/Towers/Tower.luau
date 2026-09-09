--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

type TowerDefinition = TowerDefinitions.TowerDefinition

local Tower = {}
Tower.__index = Tower

export type Tower = typeof(setmetatable(
	{} :: {
		_definition: TowerDefinition,
		_position: Vector3,
		_ownerUserId: number,
		_cooldownRemaining: number,
	},
	Tower
))

function Tower.new(definition: TowerDefinition, position: Vector3, ownerUserId: number): Tower
	if definition.Damage <= 0 then
		error("Tower Damage must be greater than zero")
	end

	if definition.Range <= 0 then
		error("Tower Range must be greater than zero")
	end

	if definition.AttackCooldown <= 0 then
		error("Tower AttackCooldown must be greater than zero")
	end

	if definition.Cost < 0 then
		error("Tower Cost cannot be negative")
	end

	local self: Tower = setmetatable({
		_definition = definition,
		_position = position,
		_ownerUserId = ownerUserId,
		_cooldownRemaining = 0,
	}, Tower)

	return self
end

function Tower.Step(self: Tower, fixedDeltaTime: number)
	if fixedDeltaTime < 0 then
		error("Tower fixedDeltaTime cannot be negative")
	end

	self._cooldownRemaining = math.max(0, self._cooldownRemaining - fixedDeltaTime)
end

function Tower.CanAttack(self: Tower): boolean
	return self._cooldownRemaining <= 0
end

function Tower.TriggerAttack(self: Tower): boolean
	if not self:CanAttack() then
		return false
	end

	self._cooldownRemaining = self._definition.AttackCooldown

	return true
end

function Tower.GetPosition(self: Tower): Vector3
	return self._position
end

function Tower.GetOwnerUserId(self: Tower): number
	return self._ownerUserId
end

function Tower.GetModelName(self: Tower): string
	return self._definition.ModelName
end

function Tower.GetDamage(self: Tower): number
	return self._definition.Damage
end

function Tower.GetRange(self: Tower): number
	return self._definition.Range
end

function Tower.GetAttackCooldown(self: Tower): number
	return self._definition.AttackCooldown
end

function Tower.GetCooldownRemaining(self: Tower): number
	return self._cooldownRemaining
end

function Tower.GetCost(self: Tower): number
	return self._definition.Cost
end

return Tower
