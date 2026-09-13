--!strict

local WebAttack = {}

local LIFETIME = 0.15
local active: { [Beam]: () -> () } = {}

function WebAttack.Play(origin: BasePart, target: BasePart, gameSpeed: number)
	if not origin:IsDescendantOf(workspace) or not target:IsDescendantOf(workspace) then
		return
	end

	if gameSpeed ~= 1 and gameSpeed ~= 2 and gameSpeed ~= 3 then
		return
	end

	local originAttachment = Instance.new("Attachment")
	originAttachment.Name = "WebAttackOrigin"
	originAttachment.Parent = origin

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "WebAttackTarget"
	targetAttachment.Parent = target

	local beam = Instance.new("Beam")
	beam.Name = "WebAttack"
	beam.Attachment0 = originAttachment
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	beam.Transparency = NumberSequence.new(0)
	beam.Width0 = 0.12
	beam.Width1 = 0.09
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Parent = originAttachment

	local connections: { RBXScriptConnection } = {}
	local cleaned = false

	local function cleanup()
		if cleaned then
			return
		end

		cleaned = true
		active[beam] = nil
		for _, connection in connections do
			connection:Disconnect()
		end
		originAttachment:Destroy()
		targetAttachment:Destroy()
	end

	local function onAncestryChanged()
		if not origin:IsDescendantOf(workspace) or not target:IsDescendantOf(workspace) then
			cleanup()
		end
	end

	active[beam] = cleanup
	table.insert(connections, origin.AncestryChanged:Connect(onAncestryChanged))
	table.insert(connections, target.AncestryChanged:Connect(onAncestryChanged))
	task.delay(LIFETIME / gameSpeed, cleanup)
end

function WebAttack.Clear()
	for _, cleanup in active do
		cleanup()
	end
end

return WebAttack
