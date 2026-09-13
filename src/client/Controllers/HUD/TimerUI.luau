--!strict

local TimerUI = {}

local label: TextLabel? = nil

function TimerUI.Start(timerLabel: TextLabel)
	label = timerLabel
	label.Text = "--:--"
end

function TimerUI.Set(seconds: number)
	if label then
		local totalSeconds = math.max(0, math.floor(seconds))
		label.Text = string.format("%02d:%02d", math.floor(totalSeconds / 60), totalSeconds % 60)
	end
end

function TimerUI.Stop()
	label = nil
end

return TimerUI
