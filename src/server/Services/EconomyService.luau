--!strict

local Players = game:GetService("Players")

local EconomyService = {}

local STARTING_MONEY = 500

local balances: { [number]: number } = {}
local started = false

local function addPlayer(player: Player)
	if balances[player.UserId] == nil then
		balances[player.UserId] = STARTING_MONEY
	end
end

local function removePlayer(player: Player)
	balances[player.UserId] = nil
end

function EconomyService.GetMoney(userId: number): number
	return balances[userId] or 0
end

function EconomyService.AddMoney(userId: number, amount: number): boolean
	local currentMoney = balances[userId]

	if not currentMoney or amount <= 0 then
		return false
	end

	balances[userId] = currentMoney + amount

	return true
end

function EconomyService.AddMoneyToAll(amount: number)
	if amount <= 0 then
		return
	end

	for userId in balances do
		EconomyService.AddMoney(userId, amount)
	end
end

function EconomyService.SpendMoney(userId: number, amount: number): boolean
	local currentMoney = balances[userId]

	if not currentMoney or amount <= 0 or currentMoney < amount then
		return false
	end

	balances[userId] = currentMoney - amount

	return true
end

function EconomyService.Start(): boolean
	if started then
		return false
	end

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end

	started = true

	return true
end

return EconomyService
