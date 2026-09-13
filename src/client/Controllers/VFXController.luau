--!strict

local WebAttack = require(script.Parent.Parent.VFX.WebAttack)

local VFXController = {}
local started = false

-- Called by the animation marker handler with the confirmed attack target.
function VFXController.PlayWebAttack(origin: BasePart, target: BasePart, gameSpeed: number)
	if not started then
		return
	end

	WebAttack.Play(origin, target, gameSpeed)
end

function VFXController.Start(): boolean
	if started then
		return false
	end

	started = true
	return true
end

function VFXController.Stop(): boolean
	if not started then
		return false
	end

	started = false
	WebAttack.Clear()
	return true
end

return VFXController
