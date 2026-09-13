--!strict

local Players = game:GetService("Players")

local MoneyUI = {}

local MONEY_ATTRIBUTE = "Money"

local label: TextLabel? = nil
local moneyChangedConnection: RBXScriptConnection? = nil

local function update()
	local money = Players.LocalPlayer:GetAttribute(MONEY_ATTRIBUTE)

	if label and typeof(money) == "number" then
		label.Text = tostring(math.floor(money))
	end
end

function MoneyUI.Start(coins: Instance)
	label = coins:WaitForChild("TextLabel") :: TextLabel
	label.Text = "..."

	update()
	moneyChangedConnection = Players.LocalPlayer:GetAttributeChangedSignal(MONEY_ATTRIBUTE):Connect(update)
end

function MoneyUI.Set(amount: number)
	if label then
		label.Text = tostring(math.floor(amount))
	end
end

function MoneyUI.Stop()
	if moneyChangedConnection then
		moneyChangedConnection:Disconnect()
		moneyChangedConnection = nil
	end

	label = nil
end

return MoneyUI
