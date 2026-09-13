--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local healthBarTemplate =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("EnemyHealthBar") :: BillboardGui
local titleTemplate = healthBarTemplate:WaitForChild("HPbar"):WaitForChild("Title") :: TextLabel

local TowerNameUI = {}

local labels: { [number]: BillboardGui } = {}

local function getRootPart(model: Model): BasePart?
	local rootPart = model:FindFirstChild("HumanoidRootPart", true)

	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

function TowerNameUI.Remove(id: number)
	local label = labels[id]

	if label then
		label:Destroy()
		labels[id] = nil
	end
end

function TowerNameUI.Create(id: number, model: Model, displayName: string): boolean
	local rootPart = getRootPart(model)

	if not rootPart then
		return false
	end

	TowerNameUI.Remove(id)

	local gui = Instance.new("BillboardGui")
	gui.Name = "TowerName"
	gui.Adornee = rootPart
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Size = UDim2.fromOffset(180, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)

	local title = titleTemplate:Clone()
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.5)
	title.Size = UDim2.fromScale(1, 1)
	title.Text = displayName:gsub("_", " ")
	title.Parent = gui

	gui.Parent = rootPart
	labels[id] = gui

	return true
end

function TowerNameUI.Clear()
	local ids: { number } = {}

	for id in labels do
		table.insert(ids, id)
	end

	for _, id in ids do
		TowerNameUI.Remove(id)
	end
end

return TowerNameUI
