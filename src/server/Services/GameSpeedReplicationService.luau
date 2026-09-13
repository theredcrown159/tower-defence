--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SimulationService = require(script.Parent.SimulationService)

local canChangeSpeedValue = ReplicatedStorage:WaitForChild("GameInfo"):WaitForChild("CanChangeGameSpeed") :: BoolValue
local gameSpeedValue = ReplicatedStorage:WaitForChild("GameInfo"):WaitForChild("GameSpeed") :: NumberValue
local setSpeedEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameSpeed"):WaitForChild("Set") :: RemoteEvent

local GameSpeedReplicationService = {}

local requestConnection: RBXScriptConnection? = nil
local changeLocked = false

local function unlockSpeedChange()
	if not requestConnection then
		return
	end

	changeLocked = false
	canChangeSpeedValue.Value = true
end

local function onSpeedRequested(_player: Player, requestedSpeed: unknown)
	if changeLocked or typeof(requestedSpeed) ~= "number" or requestedSpeed == SimulationService.GetSpeed() then
		return
	end

	if SimulationService.SetSpeed(requestedSpeed) then
		gameSpeedValue.Value = SimulationService.GetSpeed()
		changeLocked = true
		canChangeSpeedValue.Value = false
		task.delay(GameConfig.GameSpeedChangeCooldown, unlockSpeedChange)
	end
end

function GameSpeedReplicationService.Start(): boolean
	if requestConnection then
		return false
	end

	changeLocked = false
	canChangeSpeedValue.Value = true
	gameSpeedValue.Value = SimulationService.GetSpeed()
	requestConnection = setSpeedEvent.OnServerEvent:Connect(onSpeedRequested)

	return true
end

function GameSpeedReplicationService.Stop(): boolean
	if not requestConnection then
		return false
	end

	requestConnection:Disconnect()
	requestConnection = nil
	changeLocked = true
	canChangeSpeedValue.Value = false

	return true
end

return GameSpeedReplicationService
