--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WebAttack = {}
local active: { [Instance]: () -> () } = {}
local warnedMissingTemplate = false

local BEAM_DELAY = 0.03
local BEAM_DURATION = 0.15
local WEB_LIFETIME = 1.5
local WEB_ROTATION_SPEED = 120
local RING_LIFETIME_MULTIPLIER = 1.5

local RING_PARTICLES: { [string]: boolean } = {
	EffectWave1 = true,
	EffectWave3 = true,
	Shockwave = true,
}

local function getTemplate(): BasePart?
	local current: Instance? = ReplicatedStorage
	for _, name in { "Assets1", "VFX", "Towers", "Classical", "WebEffect" } do
		current = if current then current:FindFirstChild(name) else nil
	end
	return if current and current:IsA("BasePart") then current else nil
end

local function getNumber(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then math.max(0, value) else default
end

local function configureParticle(emitter: ParticleEmitter, gameSpeed: number)
	local lifetimeMultiplier = if RING_PARTICLES[emitter.Name] then RING_LIFETIME_MULTIPLIER else 1
	emitter.Enabled = false
	emitter.Lifetime = NumberRange.new(
		emitter.Lifetime.Min * lifetimeMultiplier / gameSpeed,
		emitter.Lifetime.Max * lifetimeMultiplier / gameSpeed
	)
	emitter.Speed = NumberRange.new(emitter.Speed.Min * gameSpeed, emitter.Speed.Max * gameSpeed)
	emitter.RotSpeed = NumberRange.new(emitter.RotSpeed.Min * gameSpeed, emitter.RotSpeed.Max * gameSpeed)
	emitter.Acceleration *= gameSpeed * gameSpeed
	emitter.Drag *= gameSpeed

	if emitter.Name == "Web" then
		emitter.Lifetime = NumberRange.new(WEB_LIFETIME / gameSpeed)
		emitter.RotSpeed = NumberRange.new(WEB_ROTATION_SPEED * gameSpeed)
	end
end

function WebAttack.Play(origin: BasePart, target: BasePart, gameSpeed: number)
	if not origin:IsDescendantOf(workspace) or not target:IsDescendantOf(workspace) then
		return
	end
	if gameSpeed ~= 1 and gameSpeed ~= 2 and gameSpeed ~= 3 then
		return
	end

	local template = getTemplate()
	if not template then
		if not warnedMissingTemplate then
			warn("Classical WebEffect template not found in ReplicatedStorage.Assets1.VFX.Towers.Classical")
			warnedMissingTemplate = true
		end
		return
	end

	local effect = template:Clone()
	local originAttachment = effect:FindFirstChild("Effect")
	local targetPart = effect:FindFirstChild("WebEffect2")
	local targetAttachment = if targetPart then targetPart:FindFirstChild("BeamReceptor") else nil
	if
		not originAttachment
		or not originAttachment:IsA("Attachment")
		or not targetPart
		or not targetPart:IsA("BasePart")
		or not targetAttachment
		or not targetAttachment:IsA("Attachment")
	then
		effect:Destroy()
		return
	end

	effect.Name = "WebAttack"
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanQuery = false
	effect.CanTouch = false
	effect.CastShadow = false
	effect.CFrame = origin.CFrame
	targetPart.Anchored = true
	targetPart.CanCollide = false
	targetPart.CanQuery = false
	targetPart.CanTouch = false
	targetPart.CastShadow = false
	targetPart.CFrame = origin.CFrame
	originAttachment.Position = Vector3.zero
	targetAttachment.Position = Vector3.zero
	effect.Parent = workspace

	local connections: { RBXScriptConnection } = {}
	local cleaned = false
	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		active[effect] = nil
		for _, connection in connections do
			connection:Disconnect()
		end
		targetAttachment:Destroy()
		effect:Destroy()
	end

	local function onAncestryChanged()
		if not origin:IsDescendantOf(workspace) or not target:IsDescendantOf(workspace) then
			cleanup()
		end
	end
	active[effect] = cleanup
	table.insert(connections, origin.AncestryChanged:Connect(onAncestryChanged))
	table.insert(connections, target.AncestryChanged:Connect(onAncestryChanged))

	local beams: { Beam } = {}
	local handParticles: { ParticleEmitter } = {}
	local impactParticles: { ParticleEmitter } = {}
	for _, descendant in originAttachment:GetDescendants() do
		if descendant:IsA("Beam") then
			descendant.Attachment0 = originAttachment
			descendant.Attachment1 = targetAttachment
			descendant.Enabled = false
			descendant.TextureSpeed *= gameSpeed
			table.insert(beams, descendant)
		elseif descendant:IsA("ParticleEmitter") then
			configureParticle(descendant, gameSpeed)
			table.insert(handParticles, descendant)
		end
	end
	for _, descendant in targetAttachment:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			configureParticle(descendant, gameSpeed)
			table.insert(impactParticles, descendant)
		end
	end

	local maximumLifetime = 0
	for _, emitter in handParticles do
		local delay = getNumber(emitter, "EmitDelay", 0) / gameSpeed
		local count = math.floor(getNumber(emitter, "EmitCount", 1))
		maximumLifetime = math.max(maximumLifetime, delay + emitter.Lifetime.Max)
		task.delay(delay, function()
			if not cleaned then
				emitter:Emit(count)
			end
		end)
	end

	local rightBeam = originAttachment:FindFirstChild("RightBeam1")
	local beamDuration = if rightBeam then getNumber(rightBeam, "EmitDuration", BEAM_DURATION) else BEAM_DURATION
	beamDuration /= gameSpeed
	local beamDelay = BEAM_DELAY / gameSpeed
	local impactStart = beamDelay + beamDuration

	for _, emitter in impactParticles do
		local emitDelay = getNumber(emitter, "EmitDelay", 0) / gameSpeed
		maximumLifetime = math.max(maximumLifetime, impactStart + emitDelay + emitter.Lifetime.Max)
	end

	maximumLifetime = math.max(maximumLifetime, impactStart)
	task.delay(beamDelay, function()
		if cleaned then
			return
		end
		for _, beam in beams do
			beam.Enabled = true
		end

		local tween = TweenService:Create(
			originAttachment,
			TweenInfo.new(beamDuration, Enum.EasingStyle.Linear),
			{ WorldPosition = target.Position }
		)
		tween:Play()
		tween.Completed:Once(function(playbackState)
			for _, beam in beams do
				beam.Enabled = false
			end
			if cleaned or playbackState ~= Enum.PlaybackState.Completed then
				return
			end
			targetAttachment.Position = Vector3.zero
			targetAttachment.Parent = target
			for _, emitter in impactParticles do
				local emitDelay = getNumber(emitter, "EmitDelay", 0) / gameSpeed
				local count = if emitter.Name == "Web" then 1 else math.floor(getNumber(emitter, "EmitCount", 1))
				task.delay(emitDelay, function()
					if not cleaned then
						emitter:Emit(count)
					end
				end)
			end
		end)
	end)

	task.delay(maximumLifetime + 0.05, cleanup)
end

function WebAttack.Clear()
	for _, cleanup in active do
		cleanup()
	end
end

return WebAttack
