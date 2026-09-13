--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseHealthUI = {}

local MATCH_STATE_NAME = "MatchState"
local HEALTH_ATTRIBUTE = "BaseHealth"
local MAX_HEALTH_ATTRIBUTE = "BaseMaxHealth"

local fill: ImageLabel? = nil
local label: TextLabel? = nil
local fullSize: UDim2? = nil
local connections: { RBXScriptConnection } = {}

local function render(health: number, maxHealth: number)
	if not fill or not label or not fullSize then
		return
	end

	local currentHealth = math.max(0, health)
	local maximumHealth = math.max(0, maxHealth)
	local ratio = if maximumHealth > 0 then math.clamp(currentHealth / maximumHealth, 0, 1) else 0

	label.Text = string.format("%d/%d", math.floor(currentHealth), math.floor(maximumHealth))
	fill.Size = UDim2.new(fullSize.X.Scale * ratio, fullSize.X.Offset * ratio, fullSize.Y.Scale, fullSize.Y.Offset)
end

local function update()
	local matchState = ReplicatedStorage:FindFirstChild(MATCH_STATE_NAME)

	if not matchState then
		return
	end

	local health = matchState:GetAttribute(HEALTH_ATTRIBUTE)
	local maxHealth = matchState:GetAttribute(MAX_HEALTH_ATTRIBUTE)

	if typeof(health) == "number" and typeof(maxHealth) == "number" then
		render(health, maxHealth)
	end
end

function BaseHealthUI.Start(healthBar: Instance)
	local fillImage = healthBar:WaitForChild("ImageLabel") :: ImageLabel
	local healthLabel = healthBar:WaitForChild("TextLabel") :: TextLabel
	local matchState = ReplicatedStorage:WaitForChild(MATCH_STATE_NAME)
	local initialSize = fillImage.Size

	fill = fillImage
	label = healthLabel
	fullSize = initialSize

	healthLabel.Text = ".../..."
	fillImage.Size = UDim2.new(0, 0, initialSize.Y.Scale, initialSize.Y.Offset)

	table.insert(connections, matchState:GetAttributeChangedSignal(HEALTH_ATTRIBUTE):Connect(update))
	table.insert(connections, matchState:GetAttributeChangedSignal(MAX_HEALTH_ATTRIBUTE):Connect(update))
	update()
end

function BaseHealthUI.Set(health: number, maxHealth: number)
	render(health, maxHealth)
end

function BaseHealthUI.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end

	if fill and fullSize then
		fill.Size = fullSize
	end

	table.clear(connections)
	fill = nil
	label = nil
	fullSize = nil
end

return BaseHealthUI
