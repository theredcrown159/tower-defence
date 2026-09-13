--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveUI = {}

local MATCH_STATE_NAME = "MatchState"
local WAVE_ATTRIBUTE = "Wave"

local label: TextLabel? = nil
local waveChangedConnection: RBXScriptConnection? = nil

local function update()
	local matchState = ReplicatedStorage:FindFirstChild(MATCH_STATE_NAME)

	if not matchState then
		return
	end

	local wave = matchState:GetAttribute(WAVE_ATTRIBUTE)

	if label and typeof(wave) == "number" then
		label.Text = `WAVE {math.max(0, math.floor(wave))}`
	end
end

function WaveUI.Start(waveLabel: TextLabel)
	local matchState = ReplicatedStorage:WaitForChild(MATCH_STATE_NAME)

	label = waveLabel
	label.Text = "WAVE ..."

	waveChangedConnection = matchState:GetAttributeChangedSignal(WAVE_ATTRIBUTE):Connect(update)
	update()
end

function WaveUI.Set(wave: number)
	if label then
		label.Text = `WAVE {wave}`
	end
end

function WaveUI.Stop()
	if waveChangedConnection then
		waveChangedConnection:Disconnect()
		waveChangedConnection = nil
	end

	label = nil
end

return WaveUI
