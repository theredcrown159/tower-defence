--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyCountUI = {}

local MATCH_STATE_NAME = "MatchState"
local ENEMY_COUNT_ATTRIBUTE = "EnemyCount"

local label: TextLabel? = nil
local countChangedConnection: RBXScriptConnection? = nil

local function update()
	local matchState = ReplicatedStorage:FindFirstChild(MATCH_STATE_NAME)

	if not matchState then
		return
	end

	local count = matchState:GetAttribute(ENEMY_COUNT_ATTRIBUTE)

	if label and typeof(count) == "number" then
		label.Text = tostring(math.max(0, math.floor(count)))
	end
end

function EnemyCountUI.Start(enemyCountLabel: TextLabel)
	local matchState = ReplicatedStorage:WaitForChild(MATCH_STATE_NAME)

	label = enemyCountLabel
	label.Text = "..."

	countChangedConnection = matchState:GetAttributeChangedSignal(ENEMY_COUNT_ATTRIBUTE):Connect(update)
	update()
end

function EnemyCountUI.Set(count: number)
	if label then
		label.Text = tostring(math.max(0, math.floor(count)))
	end
end

function EnemyCountUI.Stop()
	if countChangedConnection then
		countChangedConnection:Disconnect()
		countChangedConnection = nil
	end

	label = nil
end

return EnemyCountUI
