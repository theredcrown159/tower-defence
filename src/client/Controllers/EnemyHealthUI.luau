--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local healthBarTemplate =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("EnemyHealthBar") :: BillboardGui

local EnemyHealthUI = {}

type HealthBar = {
	Gui: BillboardGui,
	Fill: ImageLabel,
	Health: TextLabel,
	FullSize: UDim2,
	MaxHealth: number,
}

local healthBars: { [number]: HealthBar } = {}

local function getRootPart(model: Model): BasePart?
	local rootPart = model:FindFirstChild("HumanoidRootPart")

	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

function EnemyHealthUI.Update(id: number, health: number)
	local healthBar = healthBars[id]

	if not healthBar then
		return
	end

	local currentHealth = math.clamp(health, 0, healthBar.MaxHealth)
	local ratio = currentHealth / healthBar.MaxHealth
	local fullSize = healthBar.FullSize

	healthBar.Health.Text = string.format("%d/%d", math.floor(currentHealth), math.floor(healthBar.MaxHealth))
	healthBar.Fill.Size =
		UDim2.new(fullSize.X.Scale * ratio, fullSize.X.Offset * ratio, fullSize.Y.Scale, fullSize.Y.Offset)
end

function EnemyHealthUI.Remove(id: number)
	local healthBar = healthBars[id]

	if healthBar then
		healthBar.Gui:Destroy()
		healthBars[id] = nil
	end
end

function EnemyHealthUI.Create(id: number, model: Model, displayName: string, health: number, maxHealth: number): boolean
	local rootPart = getRootPart(model)

	if not rootPart or maxHealth <= 0 then
		return false
	end

	EnemyHealthUI.Remove(id)

	local gui = healthBarTemplate:Clone()
	local container = gui:WaitForChild("HPbar")
	local fill = container:WaitForChild("ImageLabel") :: ImageLabel
	local healthLabel = container:WaitForChild("Health") :: TextLabel
	local title = container:WaitForChild("Title") :: TextLabel

	title.Text = displayName:gsub("_", " ")
	gui.Adornee = rootPart
	gui.Parent = rootPart

	healthBars[id] = {
		Gui = gui,
		Fill = fill,
		Health = healthLabel,
		FullSize = fill.Size,
		MaxHealth = maxHealth,
	}

	EnemyHealthUI.Update(id, health)

	return true
end

function EnemyHealthUI.Clear()
	local ids: { number } = {}

	for id in healthBars do
		table.insert(ids, id)
	end

	for _, id in ids do
		EnemyHealthUI.Remove(id)
	end
end

return EnemyHealthUI
