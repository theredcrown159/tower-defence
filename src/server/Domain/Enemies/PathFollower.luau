--!strict

local PathFollower = {}
PathFollower.__index = PathFollower

export type PathFollower = typeof(setmetatable(
	{} :: {
		_route: { Vector3 },
		_position: Vector3,
		_segmentIndex: number,
		_distanceTraveled: number,
		_finished: boolean,
	},
	PathFollower
))

function PathFollower.new(route: { Vector3 }): PathFollower
	if #route < 2 then
		error("PathFollower requires at least two route points")
	end

	local self: PathFollower = setmetatable({
		_route = table.clone(route),
		_position = route[1],
		_segmentIndex = 1,
		_distanceTraveled = 0,
		_finished = false,
	}, PathFollower)

	return self
end

function PathFollower.GetPosition(self: PathFollower): Vector3
	return self._position
end

function PathFollower.GetDistanceTraveled(self: PathFollower): number
	return self._distanceTraveled
end

function PathFollower.IsFinished(self: PathFollower): boolean
	return self._finished
end

function PathFollower.Advance(self: PathFollower, distance: number): boolean
	if distance < 0 then
		error("PathFollower distance cannot be negative")
	end

	if self._finished or distance == 0 then
		return self._finished
	end

	local remainingDistance = distance

	while remainingDistance > 0 and not self._finished do
		local targetIndex = self._segmentIndex + 1
		local targetPosition = self._route[targetIndex]

		local offset = targetPosition - self._position
		local distanceToTarget = offset.Magnitude

		if distanceToTarget == 0 then
			self._position = targetPosition
			self._segmentIndex = targetIndex
		elseif remainingDistance < distanceToTarget then
			local direction = offset.Unit

			self._position += direction * remainingDistance
			self._distanceTraveled += remainingDistance
			remainingDistance = 0
		else
			self._position = targetPosition
			self._distanceTraveled += distanceToTarget
			remainingDistance -= distanceToTarget
			self._segmentIndex = targetIndex
		end

		if self._segmentIndex >= #self._route then
			self._finished = true
		end
	end

	return self._finished
end

return PathFollower
