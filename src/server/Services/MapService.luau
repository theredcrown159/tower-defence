--!strict

local MapService = {}

local mapDataFolder: Folder?
local spawnPart: BasePart?
local basePart: BasePart?
local routePoints: { Vector3 } = {}

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
	routePoints = newRoutePoints

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

return MapService
