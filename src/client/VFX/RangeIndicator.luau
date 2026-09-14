--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RangeIndicator = {}
local rotations: { [Model]: CFrame } = {}
local warnedMissingTemplate = false

local HEIGHT_OFFSET = 0.05

local function getTemplate(): Model?
	local current: Instance? = ReplicatedStorage
	for _, name in { "Assets1", "VFX", "UpgradeVFX", "Range" } do
		current = if current then current:FindFirstChild(name) else nil
	end
	return if current and current:IsA("Model") then current else nil
end

local function prepare(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
		end
	end
end

function RangeIndicator.Create(range: number): Model?
	if range <= 0 then
		return nil
	end

	local template = getTemplate()
	if not template then
		if not warnedMissingTemplate then
			warn("Range template not found in ReplicatedStorage.Assets1.VFX.UpgradeVFX")
			warnedMissingTemplate = true
		end
		return nil
	end

	local templateField = template:FindFirstChild("Field")
	if not templateField or not templateField:IsA("BasePart") or templateField.Size.X <= 0 then
		warn("Range template must contain a non-empty Field BasePart")
		return nil
	end

	local model = template:Clone()
	model.Name = "TowerRangeIndicator"
	prepare(model)
	local diameter = range * 2
	local scale = model:GetScale() * diameter / templateField.Size.X
	model:ScaleTo(scale)
	rotations[model] = model:GetPivot().Rotation
	return model
end

function RangeIndicator.SetPosition(model: Model, position: Vector3)
	local rotation = rotations[model]
	if not rotation then
		return
	end

	model:PivotTo(CFrame.new(position + Vector3.new(0, HEIGHT_OFFSET, 0)) * rotation)
	if not model.Parent then
		model.Parent = Workspace
	end
end

function RangeIndicator.Remove(model: Model)
	rotations[model] = nil
	model:Destroy()
end

function RangeIndicator.Clear()
	for model in rotations do
		model:Destroy()
		rotations[model] = nil
	end
end

return RangeIndicator
