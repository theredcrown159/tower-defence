--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

type TowerDefinition = TowerDefinitions.TowerDefinition
type TowerLevelDefinition = TowerDefinitions.TowerLevelDefinition
export type TargetMode = TowerDefinitions.TargetMode

local Tower = {}
Tower.__index = Tower

export type Tower = typeof(setmetatable(
	{} :: {
		_definition: TowerDefinition,
		_position: Vector3,
		_ownerUserId: number,
		_cooldownRemaining: number,
		_level: number,
		_targetMode: TargetMode,
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

	if definition.AttackDuration <= 0 then
		error("Tower AttackDuration must be greater than zero")
	end

	if #definition.AttackHitTimes == 0 then
		error("Tower must have at least one attack hit")
	end

	local previousHitTime = 0

	for hitIndex, hitTime in ipairs(definition.AttackHitTimes) do
		if hitTime <= previousHitTime or hitTime > definition.AttackDuration then
			error(`Tower attack hit {hitIndex} has an invalid time`)
		end

		previousHitTime = hitTime
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

	local defaultTargetMode = definition.TargetModes[1]

	if not defaultTargetMode then
		error("Tower must have at least one target mode")
	end

	local self: Tower = setmetatable({
		_definition = definition,
		_position = position,
		_ownerUserId = ownerUserId,
		_cooldownRemaining = 0,
		_level = 1,
		_targetMode = defaultTargetMode,
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

	self._cooldownRemaining = math.max(self:GetAttackCooldown(), self:GetAttackDuration())

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

function Tower.GetTargetMode(self: Tower): TargetMode
	return self._targetMode
end

function Tower.SetTargetMode(self: Tower, targetMode: TargetMode): boolean
	if not table.find(self._definition.TargetModes, targetMode) then
		return false
	end

	self._targetMode = targetMode

	return true
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

function Tower.GetAttackDuration(self: Tower): number
	return self._definition.AttackDuration
end

function Tower.GetAttackHitTimes(self: Tower): { number }
	return self._definition.AttackHitTimes
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

function Tower.GetTotalCost(self: Tower): number
	local totalCost = 0

	for levelIndex = 1, self._level do
		totalCost += self._definition.Levels[levelIndex].Cost
	end

	return totalCost
end

return Tower
