--!strict

local BaseHealthUI = {}

local fill: ImageLabel? = nil
local label: TextLabel? = nil
local fullSize: UDim2? = nil

function BaseHealthUI.Start(healthBar: Instance)
	fill = healthBar:WaitForChild("ImageLabel") :: ImageLabel
	label = healthBar:WaitForChild("TextLabel") :: TextLabel
	fullSize = fill.Size

	label.Text = ".../..."
	fill.Size = UDim2.new(0, 0, fullSize.Y.Scale, fullSize.Y.Offset)
end

function BaseHealthUI.Set(health: number, maxHealth: number)
	if not fill or not label or not fullSize then
		return
	end

	local currentHealth = math.max(0, health)
	local maximumHealth = math.max(0, maxHealth)
	local ratio = if maximumHealth > 0 then math.clamp(currentHealth / maximumHealth, 0, 1) else 0

	label.Text = string.format("%d/%d", math.floor(currentHealth), math.floor(maximumHealth))
	fill.Size = UDim2.new(fullSize.X.Scale * ratio, fullSize.X.Offset * ratio, fullSize.Y.Scale, fullSize.Y.Offset)
end

function BaseHealthUI.Stop()
	if fill and fullSize then
		fill.Size = fullSize
	end

	fill = nil
	label = nil
	fullSize = nil
end

return BaseHealthUI
