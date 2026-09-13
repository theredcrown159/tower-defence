--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TimerUI = {}

local MATCH_STATE_NAME = "MatchState"
local TIME_REMAINING_ATTRIBUTE = "TimeRemaining"

local label: TextLabel? = nil
local timeChangedConnection: RBXScriptConnection? = nil

local function update()
	local matchState = ReplicatedStorage:FindFirstChild(MATCH_STATE_NAME)

	if not matchState then
		return
	end

	local seconds = matchState:GetAttribute(TIME_REMAINING_ATTRIBUTE)

	if typeof(seconds) == "number" then
		TimerUI.Set(seconds)
	end
end

function TimerUI.Start(timerLabel: TextLabel)
	local matchState = ReplicatedStorage:WaitForChild(MATCH_STATE_NAME)

	label = timerLabel
	label.Text = "--:--"

	timeChangedConnection = matchState:GetAttributeChangedSignal(TIME_REMAINING_ATTRIBUTE):Connect(update)
	update()
end

function TimerUI.Set(seconds: number)
	if label then
		local totalSeconds = math.max(0, math.floor(seconds))
		label.Text = string.format("%02d:%02d", math.floor(totalSeconds / 60), totalSeconds % 60)
	end
end

function TimerUI.Stop()
	if timeChangedConnection then
		timeChangedConnection:Disconnect()
		timeChangedConnection = nil
	end

	label = nil
end

return TimerUI
