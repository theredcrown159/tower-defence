--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemyController = require(script.Parent.EnemyController)
local TowerController = require(script.Parent.TowerController)

type TargetChangedPacket = {
	Kind: "TargetChanged",
	TowerId: number,
	TargetId: number,
}

type AttackPacket = {
	Kind: "Attack",
	Sequence: number,
	TowerId: number,
	TargetId: number,
	Damage: number,
	HealthAfter: number,
	Killed: boolean,
}

type CombatPacket = TargetChangedPacket | AttackPacket

type ActiveBeam = {
	Beam: Beam,
	Remaining: number,
}

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local combatEvent = towerRemotes:WaitForChild("Attacked")

local CombatController = {}

local availableBeams: { Beam } = {}
local activeBeams: { ActiveBeam } = {}
local connections: { RBXScriptConnection } = {}
local lastAttackSequence = 0
local started = false

local BEAM_LIFETIME = 0.15
local BEAM_WIDTH = 0.12

local function getEffectsFolder(): Folder
	local existing = Workspace:FindFirstChild("CombatEffects")

	if existing then
		if not existing:IsA("Folder") then
			error("Workspace.CombatEffects must be a Folder")
		end

		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "CombatEffects"
	folder.Parent = Workspace

	return folder
end

local function getHumanoidRootPart(model: Model): BasePart?
	local rootPart = model:FindFirstChild("HumanoidRootPart", true)

	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getOrCreateAttachment(part: BasePart, name: string): Attachment
	local existing = part:FindFirstChild(name)

	if existing and existing:IsA("Attachment") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Parent = part

	return attachment
end

local function createBeam(): Beam
	local beam = Instance.new("Beam")
	beam.Name = "TowerAttackBeam"
	beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	beam.Transparency = NumberSequence.new(0)
	beam.Width0 = BEAM_WIDTH
	beam.Width1 = BEAM_WIDTH * 0.75
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Enabled = false
	beam.Parent = getEffectsFolder()

	return beam
end

local function acquireBeam(): Beam?
	local beam = table.remove(availableBeams)

	if not beam then
		beam = createBeam()
	elseif not beam.Parent then
		beam.Parent = getEffectsFolder()
	end

	return beam
end

local function releaseBeam(beam: Beam)
	beam.Enabled = false
	beam.Attachment0 = nil
	beam.Attachment1 = nil
	table.insert(availableBeams, beam)
end

local function showAttack(towerId: number, targetId: number)
	local towerModel = TowerController.GetModel(towerId)
	local enemyModel = EnemyController.GetModel(targetId)

	if not towerModel or not enemyModel then
		return
	end

	local towerRootPart = getHumanoidRootPart(towerModel)
	local enemyRootPart = getHumanoidRootPart(enemyModel)

	if not towerRootPart or not enemyRootPart then
		return
	end

	local beam = acquireBeam()
	beam.Attachment0 = getOrCreateAttachment(towerRootPart, "AttackOrigin")
	beam.Attachment1 = getOrCreateAttachment(enemyRootPart, "HitTarget")
	beam.Enabled = true

	table.insert(activeBeams, {
		Beam = beam,
		Remaining = BEAM_LIFETIME,
	})
end

local function onCombatPacket(packet: CombatPacket)
	if packet.Kind == "TargetChanged" then
		TowerController.SetTarget(packet.TowerId, packet.TargetId)
		return
	end

	if packet.Sequence <= lastAttackSequence then
		return
	end

	lastAttackSequence = packet.Sequence
	showAttack(packet.TowerId, packet.TargetId)

	if packet.Killed then
		EnemyController.BeginDeath(packet.TargetId)
	end
end

local function onRenderStep(deltaTime: number)
	for index = #activeBeams, 1, -1 do
		local activeBeam = activeBeams[index]
		activeBeam.Remaining -= deltaTime

		if activeBeam.Remaining <= 0 then
			releaseBeam(activeBeam.Beam)
			table.remove(activeBeams, index)
		end
	end
end

function CombatController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, combatEvent.OnClientEvent:Connect(onCombatPacket))
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
	started = true

	return true
end

function CombatController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	for _, activeBeam in activeBeams do
		activeBeam.Beam:Destroy()
	end

	for _, beam in availableBeams do
		beam:Destroy()
	end

	table.clear(activeBeams)
	table.clear(availableBeams)
	table.clear(connections)
	lastAttackSequence = 0
	started = false

	return true
end

return CombatController
