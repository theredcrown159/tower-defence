--!strict

local WaveUI = {}

local label: TextLabel? = nil

function WaveUI.Start(waveLabel: TextLabel)
	label = waveLabel
	label.Text = "WAVE ..."
end

function WaveUI.Set(wave: number)
	if label then
		label.Text = `WAVE {wave}`
	end
end

function WaveUI.Stop()
	label = nil
end

return WaveUI
