--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local voteSkipEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Waves"):WaitForChild("VoteSkip") :: RemoteEvent

local SkipWaveUI = {}

local frame: GuiObject? = nil
local amountLabel: TextLabel? = nil
local timerLabel: TextLabel? = nil
local matchState: Instance? = nil
local connections: { RBXScriptConnection } = {}

local function getCount(attributeName: string): number
	local state = matchState

	if not state then
		return 0
	end

	local value = state:GetAttribute(attributeName)
	return if typeof(value) == "number" then math.max(0, math.floor(value)) else 0
end

local function update()
	local skipWave = frame
	local amount = amountLabel
	local timerText = timerLabel
	local state = matchState

	if not skipWave or not amount or not timerText or not state then
		return
	end

	local requiredVotes = getCount("SkipVotesRequired")

	skipWave.Visible = state:GetAttribute("CanSkip") == true
	amount.Visible = requiredVotes > 1
	amount.Text = string.format("(%d/%d)", getCount("SkipVotes"), requiredVotes)
	timerText.Text = tostring(getCount("TimeRemaining"))
end

function SkipWaveUI.Start(skipWave: GuiObject)
	local state = ReplicatedStorage:WaitForChild("MatchState")
	local yesButton = skipWave:WaitForChild("Yes") :: GuiButton
	local noButton = skipWave:WaitForChild("No") :: GuiButton
	local timer = skipWave:WaitForChild("Timer") :: GuiObject

	frame = skipWave
	amountLabel = yesButton:WaitForChild("Amount") :: TextLabel
	timerLabel = timer:WaitForChild("TextLabel") :: TextLabel
	matchState = state

	timer.Visible = true

	table.insert(connections, state:GetAttributeChangedSignal("CanSkip"):Connect(update))
	table.insert(connections, state:GetAttributeChangedSignal("SkipVotes"):Connect(update))
	table.insert(connections, state:GetAttributeChangedSignal("SkipVotesRequired"):Connect(update))
	table.insert(connections, state:GetAttributeChangedSignal("TimeRemaining"):Connect(update))
	table.insert(
		connections,
		yesButton.Activated:Connect(function()
			voteSkipEvent:FireServer(true)
		end)
	)
	table.insert(
		connections,
		noButton.Activated:Connect(function()
			voteSkipEvent:FireServer(false)
		end)
	)

	update()
end

function SkipWaveUI.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)

	if frame then
		frame.Visible = false
	end

	frame = nil
	amountLabel = nil
	timerLabel = nil
	matchState = nil
end

return SkipWaveUI
