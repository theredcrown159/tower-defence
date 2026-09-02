--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local SimulationService = {}

local steppedEvent = Instance.new("BindableEvent")
SimulationService.Stepped = steppedEvent.Event

local speed: number = GameConfig.DefaultSpeed
local gameTime: number = 0
local accumulator: number = 0
local heartbeatConnection: RBXScriptConnection? = nil

local function stepSimulation()
	gameTime += GameConfig.FixedStep
	steppedEvent:Fire(GameConfig.FixedStep, gameTime)
end

local function onHeartbeat(realDeltaTime: number)
	accumulator += realDeltaTime * speed

	local completedSteps = 0

	while accumulator >= GameConfig.FixedStep and completedSteps < GameConfig.MaximumStepsPerFrame do
		accumulator -= GameConfig.FixedStep
		stepSimulation()

		completedSteps += 1
	end

	if completedSteps == GameConfig.MaximumStepsPerFrame then
		accumulator = math.min(accumulator, GameConfig.FixedStep)
	end
end

function SimulationService.GetSpeed(): number
	return speed
end

function SimulationService.GetGameTime(): number
	return gameTime
end

function SimulationService.SetSpeed(newSpeed: number): boolean
	local isAllowed = table.find(GameConfig.AllowedSpeeds, newSpeed) ~= nil

	if not isAllowed then
		return false
	end

	speed = newSpeed

	return true
end

function SimulationService.Start(): boolean
	if heartbeatConnection then
		return false
	end

	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)

	return true
end

function SimulationService.Stop(): boolean
	if not heartbeatConnection then
		return false
	end

	heartbeatConnection:Disconnect()
	heartbeatConnection = nil

	accumulator = 0

	return true
end

function SimulationService.Reset(): boolean
	if heartbeatConnection then
		return false
	end

	speed = GameConfig.DefaultSpeed
	gameTime = 0
	accumulator = 0

	return true
end

return SimulationService
