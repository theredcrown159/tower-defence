--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AnimationPlayer = require(script.Parent.Parent.Util.AnimationPlayer)
local EnemyController = require(script.Parent.EnemyController)
local TowerNameUI = require(script.Parent.TowerNameUI)
local TowerSelectionController = require(script.Parent.TowerSelectionController)
local VFXController = require(script.Parent.VFXController)

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local placedEvent = towerRemotes:WaitForChild("Placed")
local removedEvent = towerRemotes:WaitForChild("Removed")
local attackedEvent = towerRemotes:WaitForChild("Attacked")
local upgradedEvent = towerRemotes:WaitForChild("Upgraded")
local targetModeChangedEvent = towerRemotes:WaitForChild("TargetModeChanged")
local readyEvent = towerRemotes:WaitForChild("Ready")

local towerModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towers")
local gameSpeedValue = ReplicatedStorage:WaitForChild("GameInfo"):WaitForChild("GameSpeed") :: NumberValue

local TowerController = {}

type TowerPacket = {
	Kind: "TargetChanged" | "Attack",
	TowerId: number,
	TargetId: number,
}

local towers: { [number]: Model } = {}
local attackTracks: { [number]: AnimationTrack } = {}
local attackCycleTargets: { [number]: number } = {}
local attackMarkerConnections: { [number]: RBXScriptConnection } = {}
local attackStoppedConnections: { [number]: RBXScriptConnection } = {}
local towerTargets: { [number]: number } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local MIN_DIRECTION_MAGNITUDE = 0.001
local TURN_SPEED = 12
local TOWER_YAW_OFFSET = CFrame.Angles(0, 0, 0)
local ATTACK_ANIMATION_ID = "85779923101020"

local function getVisualsFolder(): Folder
	local existing = Workspace:FindFirstChild("TowerVisuals")

	if existing then
		if not existing:IsA("Folder") then
			error("Workspace.TowerVisuals must be a Folder")
		end

		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "TowerVisuals"
	folder.Parent = Workspace

	return folder
end

local function prepareVisualModel(model: Model)
	local rootPart = model:FindFirstChild("HumanoidRootPart", true)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = descendant == rootPart
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function getHumanoidRootPart(model: Model): BasePart?
	local rootPart = model:FindFirstChild("HumanoidRootPart", true)

	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function faceTarget(model: Model, targetPosition: Vector3, deltaTime: number)
	local pivot = model:GetPivot()
	local flatTarget = Vector3.new(targetPosition.X, pivot.Position.Y, targetPosition.Z)
	local direction = flatTarget - pivot.Position

	if direction.Magnitude <= MIN_DIRECTION_MAGNITUDE then
		return
	end

	local targetCFrame = CFrame.lookAt(pivot.Position, flatTarget) * TOWER_YAW_OFFSET
	local alpha = 1 - math.exp(-TURN_SPEED * deltaTime)

	model:PivotTo(pivot:Lerp(targetCFrame, alpha))
end

local function showAttackHit(towerId: number, handName: string)
	local targetId = attackCycleTargets[towerId]
	local towerModel = towers[towerId]

	if not targetId or not towerModel then
		return
	end

	local enemyModel = EnemyController.GetModel(targetId)

	if not enemyModel then
		return
	end

	local towerRootPart = getHumanoidRootPart(towerModel)
	local enemyRootPart = getHumanoidRootPart(enemyModel)

	if not towerRootPart or not enemyRootPart then
		return
	end

	local hand = towerModel:FindFirstChild(handName)
	local origin = if hand and hand:IsA("BasePart") then hand else towerRootPart
	VFXController.PlayWebAttack(origin, enemyRootPart, gameSpeedValue.Value)
end

local function clearAttackTrack(towerId: number)
	local markerConnection = attackMarkerConnections[towerId]
	local stoppedConnection = attackStoppedConnections[towerId]
	local attackTrack = attackTracks[towerId]

	if markerConnection then
		markerConnection:Disconnect()
	end

	if stoppedConnection then
		stoppedConnection:Disconnect()
	end

	attackMarkerConnections[towerId] = nil
	attackStoppedConnections[towerId] = nil
	attackTracks[towerId] = nil
	attackCycleTargets[towerId] = nil
	AnimationPlayer.Stop(attackTrack)
end

local function loadAttackTrack(towerId: number, model: Model)
	local attackTrack = AnimationPlayer.Load(model, ATTACK_ANIMATION_ID, false, Enum.AnimationPriority.Action)

	if not attackTrack then
		return
	end

	local hitIndex = 0
	attackTracks[towerId] = attackTrack
	attackMarkerConnections[towerId] = attackTrack:GetMarkerReachedSignal("hit"):Connect(function()
		hitIndex += 1
		showAttackHit(towerId, if hitIndex % 2 == 1 then "RightHand" else "LeftHand")
	end)
	attackStoppedConnections[towerId] = attackTrack.Stopped:Connect(function()
		hitIndex = 0
		if attackTracks[towerId] == attackTrack then
			attackCycleTargets[towerId] = nil
		end
	end)
end

local function updateAttackSpeeds()
	local gameSpeed = gameSpeedValue.Value

	for _, attackTrack in attackTracks do
		if attackTrack.IsPlaying then
			attackTrack:AdjustSpeed(gameSpeed)
		end
	end
end

local function onTowerPlaced(
	id: number,
	modelName: string,
	position: Vector3,
	ownerUserId: number,
	level: number,
	targetMode: string
)
	local template = towerModels:FindFirstChild(modelName)

	if not template or not template:IsA("Model") then
		warn(`Tower model "{modelName}" not found`)
		return
	end

	local existing = towers[id]

	if existing then
		clearAttackTrack(id)
		TowerNameUI.Remove(id)
		TowerSelectionController.Unregister(existing)
		existing:Destroy()
	end

	local model = template:Clone()
	model:SetAttribute("TowerId", id)
	model:SetAttribute("TowerName", modelName)
	model:SetAttribute("OwnerUserId", ownerUserId)
	model:SetAttribute("TowerLevel", level)
	model:SetAttribute("TargetMode", targetMode)
	prepareVisualModel(model)
	model:PivotTo(CFrame.new(position))
	model.Parent = getVisualsFolder()
	towers[id] = model
	TowerNameUI.Create(id, model, modelName)
	TowerSelectionController.Register(model)
	loadAttackTrack(id, model)
end

local function onTowerUpgraded(id: number, level: number)
	local model = towers[id]

	if model then
		model:SetAttribute("TowerLevel", level)
	end
end

local function onTowerTargetModeChanged(id: number, targetMode: string)
	local model = towers[id]

	if model then
		model:SetAttribute("TargetMode", targetMode)
	end
end

local function onTowerRemoved(id: number)
	local model = towers[id]

	clearAttackTrack(id)
	TowerNameUI.Remove(id)

	if model then
		TowerSelectionController.Unregister(model)
		model:Destroy()
	end

	towers[id] = nil
	towerTargets[id] = nil
end

local function playAttackAnimation(towerId: number, targetId: number)
	local attackTrack = attackTracks[towerId]

	if not attackTrack or attackTrack.IsPlaying then
		return
	end

	attackCycleTargets[towerId] = targetId
	attackTrack:Play(0, 1, gameSpeedValue.Value)
end

local function onTowerPacket(packet: TowerPacket)
	if packet.Kind == "TargetChanged" then
		if packet.TargetId == 0 then
			towerTargets[packet.TowerId] = nil
		else
			towerTargets[packet.TowerId] = packet.TargetId
		end

		local attackTrack = attackTracks[packet.TowerId]

		if attackTrack and attackTrack.IsPlaying then
			attackCycleTargets[packet.TowerId] = if packet.TargetId == 0 then nil else packet.TargetId
		end

		return
	end

	playAttackAnimation(packet.TowerId, packet.TargetId)
end

local function onRenderStep(deltaTime: number)
	for towerId, targetId in towerTargets do
		local towerModel = towers[towerId]
		local enemyModel = EnemyController.GetModel(targetId)

		if not towerModel or not enemyModel then
			continue
		end

		local enemyRootPart = getHumanoidRootPart(enemyModel)

		if enemyRootPart then
			faceTarget(towerModel, enemyRootPart.Position, deltaTime)
		end
	end
end

function TowerController.GetModel(id: number): Model?
	return towers[id]
end

function TowerController.Start(): boolean
	if started then
		return false
	end

	getVisualsFolder()
	table.insert(connections, placedEvent.OnClientEvent:Connect(onTowerPlaced))
	table.insert(connections, removedEvent.OnClientEvent:Connect(onTowerRemoved))
	table.insert(connections, attackedEvent.OnClientEvent:Connect(onTowerPacket))
	table.insert(connections, upgradedEvent.OnClientEvent:Connect(onTowerUpgraded))
	table.insert(connections, targetModeChangedEvent.OnClientEvent:Connect(onTowerTargetModeChanged))
	table.insert(connections, gameSpeedValue:GetPropertyChangedSignal("Value"):Connect(updateAttackSpeeds))
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
	started = true

	readyEvent:FireServer()

	return true
end

function TowerController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	TowerNameUI.Clear()

	for id, model in towers do
		clearAttackTrack(id)
		TowerSelectionController.Unregister(model)
		model:Destroy()
		towers[id] = nil
	end

	table.clear(attackCycleTargets)
	table.clear(attackMarkerConnections)
	table.clear(attackStoppedConnections)
	table.clear(towerTargets)
	table.clear(connections)
	started = false

	return true
end

return TowerController
