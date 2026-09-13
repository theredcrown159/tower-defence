--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

type TowerDefinition = TowerDefinitions.TowerDefinition
type TowerLevelDefinition = TowerDefinitions.TowerLevelDefinition

local Tower = {}
Tower.__index = Tower

export type Tower = typeof(setmetatable(
	{} :: {
		_definition: TowerDefinition,
		_position: Vector3,
		_ownerUserId: number,
		_cooldownRemaining: number,
		_level: number,
	},
	Tower
))

local function getCurrentLevel(self: Tower): TowerLevelDefinition
	local level = self._definition.Levels[self._level]

	if not level then
		error("Tower current level is invalid")
	end

	return level
end

function Tower.new(definition: TowerDefinition, position: Vector3, ownerUserId: number): Tower
	if #definition.Levels == 0 then
		error("Tower must have at least one level")
	end

	for levelIndex, level in ipairs(definition.Levels) do
		if level.Damage <= 0 then
			error("Tower level " .. levelIndex .. " Damage must be greater than zero")
		end

		if level.Range <= 0 then
			error("Tower level " .. levelIndex .. " Range must be greater than zero")
		end

		if level.AttackCooldown <= 0 then
			error("Tower level " .. levelIndex .. " AttackCooldown must be greater than zero")
		end

		if level.Cost < 0 then
			error("Tower level " .. levelIndex .. " Cost cannot be negative")
		end
	end

	local self: Tower = setmetatable({
		_definition = definition,
		_position = position,
		_ownerUserId = ownerUserId,
		_cooldownRemaining = 0,
		_level = 1,
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

	self._cooldownRemaining = self:GetAttackCooldown()

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

function Tower.GetLevel(self: Tower): number
	return self._level
end

function Tower.GetMaxLevel(self: Tower): number
	return #self._definition.Levels
end

function Tower.GetUpgradeCost(self: Tower): number?
	local nextLevel = self._definition.Levels[self._level + 1]

	return if nextLevel then nextLevel.Cost else nil
end

function Tower.Upgrade(self: Tower): boolean
	if self._level >= self:GetMaxLevel() then
		return false
	end

	self._level += 1
	self._cooldownRemaining = math.min(self._cooldownRemaining, self:GetAttackCooldown())

	return true
end

function Tower.GetDamage(self: Tower): number
	return getCurrentLevel(self).Damage
end

function Tower.GetRange(self: Tower): number
	return getCurrentLevel(self).Range
end

function Tower.GetAttackCooldown(self: Tower): number
	return getCurrentLevel(self).AttackCooldown
end

function Tower.GetCooldownRemaining(self: Tower): number
	return self._cooldownRemaining
end

function Tower.GetCost(self: Tower): number
	return getCurrentLevel(self).Cost
end

return Tower
