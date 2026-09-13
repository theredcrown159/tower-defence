--!strict

local Workspace = game:GetService("Workspace")

local MapService = {}

local mapDataFolder: Folder?
local spawnPart: BasePart?
local basePart: BasePart?
local towerZonesFolder: Folder?
local routePoints: { Vector3 } = {}

local GROUND_RAY_HEIGHT = 100
local GROUND_RAY_DISTANCE = 200

local groundRaycastParams = RaycastParams.new()
groundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

function MapService.Load(folder: Folder): boolean
	if mapDataFolder ~= nil then
		return false
	end

	local spawn = folder:FindFirstChild("Spawn")
	if not spawn or not spawn:IsA("BasePart") then
		return false
	end

	local base = folder:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		return false
	end

	local pathFolder = folder:FindFirstChild("Path")
	if not pathFolder or not pathFolder:IsA("Folder") then
		return false
	end

	local towerZones = folder:FindFirstChild("TowerZones")
	if not towerZones or not towerZones:IsA("Folder") then
		return false
	end

	local hasTowerZone = false

	for _, child in towerZones:GetChildren() do
		if child:IsA("BasePart") then
			hasTowerZone = true
			break
		end
	end

	if not hasTowerZone then
		return false
	end

	local pathParts: { BasePart } = {}

	for _, child in pathFolder:GetChildren() do
		if not child:IsA("BasePart") then
			continue
		end

		if tonumber(child.Name) == nil then
			return false
		end

		table.insert(pathParts, child)
	end

	if #pathParts == 0 then
		return false
	end

	table.sort(pathParts, function(first: BasePart, second: BasePart): boolean
		return (tonumber(first.Name) or 0) < (tonumber(second.Name) or 0)
	end)

	local newRoutePoints: { Vector3 } = {
		spawn.Position,
	}

	for _, point in pathParts do
		table.insert(newRoutePoints, point.Position)
	end

	table.insert(newRoutePoints, base.Position)

	mapDataFolder = folder
	spawnPart = spawn
	basePart = base
	towerZonesFolder = towerZones
	routePoints = newRoutePoints
	groundRaycastParams.FilterDescendantsInstances = { towerZones }

	return true
end

function MapService.IsLoaded(): boolean
	return mapDataFolder ~= nil
end

function MapService.GetSpawn(): BasePart?
	if not MapService.IsLoaded() then
		return nil
	end

	return spawnPart
end

function MapService.GetBase(): BasePart?
	if not MapService.IsLoaded() then
		return nil
	end

	return basePart
end

function MapService.GetRoute(): { Vector3 }?
	if not MapService.IsLoaded() then
		return nil
	end

	return table.clone(routePoints)
end

function MapService.GetValidTowerPosition(position: Vector3): Vector3?
	if not MapService.IsLoaded() or not towerZonesFolder then
		return nil
	end

	for _, zone in towerZonesFolder:GetChildren() do
		if not zone:IsA("BasePart") then
			continue
		end

		local localPosition = zone.CFrame:PointToObjectSpace(position)
		local halfSize = zone.Size / 2
		local isInsideX = math.abs(localPosition.X) <= halfSize.X
		local isInsideZ = math.abs(localPosition.Z) <= halfSize.Z

		if isInsideX and isInsideZ then
			local rayOrigin = Vector3.new(position.X, zone.Position.Y + GROUND_RAY_HEIGHT, position.Z)
			local rayDirection = Vector3.new(0, -GROUND_RAY_DISTANCE, 0)
			local result = Workspace:Raycast(rayOrigin, rayDirection, groundRaycastParams)

			return if result then result.Position else nil
		end
	end

	return nil
end

function MapService.Unload()
	mapDataFolder = nil
	spawnPart = nil
	basePart = nil
	towerZonesFolder = nil
	routePoints = {}
	groundRaycastParams.FilterDescendantsInstances = {}
end

return MapService
