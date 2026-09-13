--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyService = require(script.Parent.EconomyService)
local Enemy = require(script.Parent.Parent.Domain.Enemies.Enemy)
local EnemyService = require(script.Parent.EnemyService)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MapService = require(script.Parent.MapService)
local SimulationService = require(script.Parent.SimulationService)
local Tower = require(script.Parent.Parent.Domain.Towers.Tower)
local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

type TowerType = Tower.Tower
type TargetMode = Tower.TargetMode

local TowerService = {}

local towerPlacedEvent = Instance.new("BindableEvent")
TowerService.TowerPlaced = towerPlacedEvent.Event

local towerRemovedEvent = Instance.new("BindableEvent")
TowerService.TowerRemoved = towerRemovedEvent.Event

local towerAttackedEvent = Instance.new("BindableEvent")
TowerService.TowerAttacked = towerAttackedEvent.Event

local towerTargetChangedEvent = Instance.new("BindableEvent")
TowerService.TowerTargetChanged = towerTargetChangedEvent.Event

local towerUpgradedEvent = Instance.new("BindableEvent")
TowerService.TowerUpgraded = towerUpgradedEvent.Event

local towerTargetModeChangedEvent = Instance.new("BindableEvent")
TowerService.TowerTargetModeChanged = towerTargetModeChangedEvent.Event

local activeTowers: { [number]: TowerType } = {}
local activeTargets: { [number]: number } = {}
local nextTowerId = 0
local simulationConnection: RBXScriptConnection? = nil

local function isPositionFree(position: Vector3): boolean
	for _, tower in activeTowers do
		local towerPosition = tower:GetPosition()
		local offsetX = towerPosition.X - position.X
		local offsetZ = towerPosition.Z - position.Z
		local distanceSquared = offsetX * offsetX + offsetZ * offsetZ

		if distanceSquared < GameConfig.MinimumTowerDistance ^ 2 then
			return false
		end
	end

	return true
end

local function isEnemyInRange(tower: TowerType, enemyPosition: Vector3): boolean
	local towerPosition = tower:GetPosition()
	local offsetX = enemyPosition.X - towerPosition.X
	local offsetZ = enemyPosition.Z - towerPosition.Z
	local distanceSquared = offsetX * offsetX + offsetZ * offsetZ
	local range = tower:GetRange()

	return distanceSquared <= range * range
end

local function getTargetPriority(tower: TowerType, enemy: Enemy.Enemy): number
	local targetMode = tower:GetTargetMode()

	if targetMode == "First" then
		return enemy:GetDistanceTraveled()
	elseif targetMode == "Last" then
		return -enemy:GetDistanceTraveled()
	else
		return enemy:GetHealth()
	end
end

local function findTarget(tower: TowerType, enemies: { [number]: Enemy.Enemy }): number?
	local targetId: number? = nil
	local targetPriority = -math.huge

	for enemyId, enemy in enemies do
		if enemy:IsDead() or enemy:HasReachedBase() then
			continue
		end

		if not isEnemyInRange(tower, enemy:GetPosition()) then
			continue
		end

		local priority = getTargetPriority(tower, enemy)

		if priority > targetPriority then
			targetId = enemyId
			targetPriority = priority
		elseif priority == targetPriority and targetId and enemyId < targetId then
			targetId = enemyId
		end
	end

	return targetId
end

local function setTarget(towerId: number, targetId: number?)
	if activeTargets[towerId] == targetId then
		return
	end

	activeTargets[towerId] = targetId
	towerTargetChangedEvent:Fire(towerId, targetId or 0)
end

local function onSimulationStep(fixedDeltaTime: number, _gameTime: number)
	local enemies = EnemyService.GetAll()

	for towerId, tower in activeTowers do
		tower:Step(fixedDeltaTime)
		local targetId = findTarget(tower, enemies)
		setTarget(towerId, targetId)

		if not targetId or not tower:CanAttack() then
			continue
		end

		local enemy = enemies[targetId]
		if not enemy then
			continue
		end

		local damage = tower:GetDamage()
		local killed = EnemyService.DamageEnemy(targetId, damage)

		tower:TriggerAttack()
		towerAttackedEvent:Fire(towerId, targetId)

		if killed then
			EconomyService.AddMoney(tower:GetOwnerUserId(), enemy:GetReward())
			setTarget(towerId, nil)
		end
	end
end

local function place(towerName: string, position: Vector3, ownerUserId: number): number
	local definition = TowerDefinitions[towerName]

	if not definition then
		error(`Tower with name "{towerName}" not found`)
	end

	local tower = Tower.new(definition, position, ownerUserId)

	nextTowerId += 1
	local towerId = nextTowerId

	activeTowers[towerId] = tower
	towerPlacedEvent:Fire(towerId, tower:GetModelName(), position, ownerUserId, tower:GetLevel(), tower:GetTargetMode())

	return towerId
end

function TowerService.TryPlace(player: Player, towerName: string, requestedPosition: Vector3): boolean
	if not simulationConnection then
		return false
	end

	local definition = TowerDefinitions[towerName]

	if not definition then
		return false
	end

	local position = MapService.GetValidTowerPosition(requestedPosition)

	if not position then
		return false
	end

	if not isPositionFree(position) then
		return false
	end

	local firstLevel = definition.Levels[1]

	if not firstLevel then
		return false
	end

	if not EconomyService.SpendMoney(player.UserId, firstLevel.Cost) then
		return false
	end

	place(towerName, position, player.UserId)

	return true
end

function TowerService.TryUpgrade(player: Player, towerId: number): boolean
	if not simulationConnection then
		return false
	end

	local tower = activeTowers[towerId]

	if not tower or tower:GetOwnerUserId() ~= player.UserId then
		return false
	end

	local upgradeCost = tower:GetUpgradeCost()

	if not upgradeCost then
		return false
	end

	if not EconomyService.SpendMoney(player.UserId, upgradeCost) then
		return false
	end

	if not tower:Upgrade() then
		return false
	end

	towerUpgradedEvent:Fire(towerId, tower:GetLevel())

	return true
end

function TowerService.TrySell(player: Player, towerId: number): boolean
	if not simulationConnection then
		return false
	end

	local tower = activeTowers[towerId]

	if not tower or tower:GetOwnerUserId() ~= player.UserId then
		return false
	end

	local refund = math.floor(tower:GetTotalCost() * GameConfig.TowerSellRefundRate)

	if not TowerService.Remove(towerId) then
		return false
	end

	EconomyService.AddMoney(player.UserId, refund)

	return true
end

function TowerService.TrySetTargetMode(player: Player, towerId: number, targetMode: TargetMode): boolean
	if not simulationConnection then
		return false
	end

	local tower = activeTowers[towerId]

	if not tower or tower:GetOwnerUserId() ~= player.UserId then
		return false
	end

	if tower:GetTargetMode() == targetMode then
		return true
	end

	if not tower:SetTargetMode(targetMode) then
		return false
	end

	towerTargetModeChangedEvent:Fire(towerId, targetMode)

	return true
end

function TowerService.GetById(id: number): TowerType?
	return activeTowers[id]
end

function TowerService.GetAll(): { [number]: TowerType }
	return table.clone(activeTowers)
end

function TowerService.GetTargetId(id: number): number?
	return activeTargets[id]
end

function TowerService.GetCount(): number
	local count = 0

	for _ in activeTowers do
		count += 1
	end

	return count
end

function TowerService.Remove(id: number): boolean
	if not activeTowers[id] then
		return false
	end

	setTarget(id, nil)
	activeTowers[id] = nil
	towerRemovedEvent:Fire(id)

	return true
end

function TowerService.Clear(): number
	local ids: { number } = {}

	for id in activeTowers do
		table.insert(ids, id)
	end

	for _, id in ids do
		TowerService.Remove(id)
	end

	return #ids
end

function TowerService.IsRunning(): boolean
	return simulationConnection ~= nil
end

function TowerService.Start(): boolean
	if simulationConnection then
		return false
	end

	if not EnemyService.IsRunning() then
		error("TowerService cannot start before EnemyService")
	end

	if GameConfig.TowerSellRefundRate < 0 or GameConfig.TowerSellRefundRate > 1 then
		error("GameConfig.TowerSellRefundRate must be between 0 and 1")
	end

	simulationConnection = SimulationService.Stepped:Connect(onSimulationStep)

	return true
end

function TowerService.Stop(): boolean
	if not simulationConnection then
		return false
	end

	simulationConnection:Disconnect()
	simulationConnection = nil

	return true
end

function TowerService.Reset(): boolean
	if simulationConnection then
		return false
	end

	TowerService.Clear()
	nextTowerId = 0

	return true
end

return TowerService
