--!strict

local RangeIndicator = require(script.Parent.Parent.VFX.RangeIndicator)
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

function VFXController.CreateRangeIndicator(range: number): Model?
	if not started then
		return nil
	end

	return RangeIndicator.Create(range)
end

function VFXController.SetRangeIndicatorPosition(indicator: Model, position: Vector3)
	if not started then
		return
	end

	RangeIndicator.SetPosition(indicator, position)
end

function VFXController.RemoveRangeIndicator(indicator: Model)
	RangeIndicator.Remove(indicator)
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
	RangeIndicator.Clear()
	return true
end

return VFXController
