--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameSpeedUI = {}

type VisualColor = {
	Object: GuiObject,
	Color: Color3,
}

type SpeedButton = {
	Button: GuiButton,
	ActiveIndicator: GuiObject,
	InactiveIndicator: GuiObject,
	ImageColors: { VisualColor },
	TextColors: { VisualColor },
	Speed: number,
}

local DISABLED_COLOR_MULTIPLIER = 0.45

local speedButtons: { SpeedButton } = {}
local buttonConnections: { RBXScriptConnection } = {}
local gameSpeedValue: NumberValue? = nil
local canChangeGameSpeedValue: BoolValue? = nil
local gameSpeedChangedConnection: RBXScriptConnection? = nil
local canChangeGameSpeedChangedConnection: RBXScriptConnection? = nil
local setGameSpeedEvent: RemoteEvent? = nil

local function getDisplayColor(color: Color3, enabled: boolean): Color3
	if enabled then
		return color
	end

	return Color3.new(
		color.R * DISABLED_COLOR_MULTIPLIER,
		color.G * DISABLED_COLOR_MULTIPLIER,
		color.B * DISABLED_COLOR_MULTIPLIER
	)
end

local function setButtonEnabled(speedButton: SpeedButton, enabled: boolean)
	speedButton.Button.Active = enabled
	speedButton.Button.Interactable = enabled
	speedButton.Button.AutoButtonColor = enabled

	for _, visual in speedButton.ImageColors do
		local object = visual.Object

		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			object.ImageColor3 = getDisplayColor(visual.Color, enabled)
		end
	end

	for _, visual in speedButton.TextColors do
		local object = visual.Object

		if object:IsA("TextLabel") or object:IsA("TextButton") then
			object.TextColor3 = getDisplayColor(visual.Color, enabled)
		end
	end
end

local function update()
	local currentGameSpeedValue = gameSpeedValue
	local currentCanChangeGameSpeedValue = canChangeGameSpeedValue

	if not currentGameSpeedValue or not currentCanChangeGameSpeedValue then
		return
	end

	local confirmedSpeed = currentGameSpeedValue.Value
	local canChangeGameSpeed = currentCanChangeGameSpeedValue.Value

	for _, speedButton in speedButtons do
		local isActive = speedButton.Speed == confirmedSpeed

		speedButton.ActiveIndicator.Visible = isActive
		speedButton.InactiveIndicator.Visible = not isActive
		setButtonEnabled(speedButton, canChangeGameSpeed)
	end
end

local function addSpeedButton(gameSpeed: GuiObject, speed: number)
	local button = gameSpeed:WaitForChild(`{speed}x`) :: GuiButton
	local imageColors: { VisualColor } = {}
	local textColors: { VisualColor } = {}

	local function addVisual(object: Instance)
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			table.insert(imageColors, {
				Object = object,
				Color = object.ImageColor3,
			})
		elseif object:IsA("TextLabel") or object:IsA("TextButton") then
			table.insert(textColors, {
				Object = object,
				Color = object.TextColor3,
			})
		end
	end

	addVisual(button)

	for _, object in button:GetDescendants() do
		addVisual(object)
	end

	table.insert(speedButtons, {
		Button = button,
		ActiveIndicator = button:WaitForChild("ActiveB") :: GuiObject,
		InactiveIndicator = button:WaitForChild("UnactiveB") :: GuiObject,
		ImageColors = imageColors,
		TextColors = textColors,
		Speed = speed,
	})

	table.insert(
		buttonConnections,
		button.Activated:Connect(function()
			local event = setGameSpeedEvent
			local canChangeValue = canChangeGameSpeedValue

			if event and canChangeValue and canChangeValue.Value then
				event:FireServer(speed)
			end
		end)
	)
end

function GameSpeedUI.Start(gameSpeed: GuiObject)
	local gameInfo = ReplicatedStorage:WaitForChild("GameInfo")
	local gameSpeedRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameSpeed")

	gameSpeedValue = gameInfo:WaitForChild("GameSpeed") :: NumberValue
	canChangeGameSpeedValue = gameInfo:WaitForChild("CanChangeGameSpeed") :: BoolValue
	setGameSpeedEvent = gameSpeedRemotes:WaitForChild("Set") :: RemoteEvent

	for speed = 1, 3 do
		addSpeedButton(gameSpeed, speed)
	end

	gameSpeedChangedConnection = gameSpeedValue:GetPropertyChangedSignal("Value"):Connect(update)
	canChangeGameSpeedChangedConnection = canChangeGameSpeedValue:GetPropertyChangedSignal("Value"):Connect(update)
	update()
end

function GameSpeedUI.Stop()
	if gameSpeedChangedConnection then
		gameSpeedChangedConnection:Disconnect()
		gameSpeedChangedConnection = nil
	end

	if canChangeGameSpeedChangedConnection then
		canChangeGameSpeedChangedConnection:Disconnect()
		canChangeGameSpeedChangedConnection = nil
	end

	for _, connection in buttonConnections do
		connection:Disconnect()
	end

	table.clear(buttonConnections)
	table.clear(speedButtons)
	gameSpeedValue = nil
	canChangeGameSpeedValue = nil
	setGameSpeedEvent = nil
end

return GameSpeedUI
