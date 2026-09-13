--!strict

local AnimationPlayer = {}

local function getOrCreateAnimator(model: Model): Animator?
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)

	if not humanoid then
		warn(`Humanoid not found in model "{model.Name}"`)
		return nil
	end

	local existing = humanoid:FindFirstChildOfClass("Animator")

	if existing then
		return existing
	end

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	return animator
end

function AnimationPlayer.Load(
	model: Model,
	animationId: string,
	looped: boolean,
	priority: Enum.AnimationPriority
): AnimationTrack?
	local animator = getOrCreateAnimator(model)

	if not animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = `rbxassetid://{animationId}`

	local success, result = pcall(animator.LoadAnimation, animator, animation)
	animation:Destroy()

	if not success then
		warn(`Failed to load animation {animationId} for model "{model.Name}": {result}`)
		return nil
	end

	local track = result :: AnimationTrack
	track.Looped = looped
	track.Priority = priority

	return track
end

function AnimationPlayer.Play(
	model: Model,
	animationId: string,
	looped: boolean,
	priority: Enum.AnimationPriority
): AnimationTrack?
	local track = AnimationPlayer.Load(model, animationId, looped, priority)

	if track then
		track:Play()
	end

	return track
end

function AnimationPlayer.Stop(track: AnimationTrack?)
	if not track then
		return
	end

	track:Stop()
	track:Destroy()
end

return AnimationPlayer
