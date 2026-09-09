--!strict

local PositionBuffer = {}

type Snapshot = {
	Time: number,
	Position: Vector3,
}

export type Buffer = { Snapshot }

local MAX_SNAPSHOTS = 32

function PositionBuffer.Push(buffer: Buffer, timestamp: number, position: Vector3)
	local latest = buffer[#buffer]
	if latest and timestamp <= latest.Time then
		return
	end

	table.insert(buffer, { Time = timestamp, Position = position })
	if #buffer > MAX_SNAPSHOTS then
		table.remove(buffer, 1)
	end
end

function PositionBuffer.Sample(buffer: Buffer, timestamp: number): Vector3?
	-- Keep the last sample before render time and all samples after it.
	while #buffer > 1 and buffer[2].Time <= timestamp do
		table.remove(buffer, 1)
	end

	local first = buffer[1]
	if not first then
		return nil
	end

	local second = buffer[2]
	if not second or timestamp <= first.Time then
		-- Hold at the endpoint instead of extrapolating through turns or the base.
		return first.Position
	end

	local alpha = (timestamp - first.Time) / (second.Time - first.Time)
	return first.Position:Lerp(second.Position, alpha)
end

return PositionBuffer
