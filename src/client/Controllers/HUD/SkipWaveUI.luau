--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local voteSkipEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Waves"):WaitForChild("VoteSkip") :: RemoteEvent

local SkipWaveUI = {}

local frame: GuiObject? = nil
local amountLabel: TextLabel? = nil
local timerLabel: TextLabel? = nil
local matchState: Instance? = nil
local shownPosition: UDim2? = nil
local hiddenPosition: UDim2? = nil
local visibilityTween: Tween? = nil
local tweenCompletedConnection: RBXScriptConnection? = nil
local connections: { RBXScriptConnection } = {}
local isShown = false

local SHOW_TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local HIDE_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local HIDDEN_MARGIN = 0.03

local function cancelVisibilityTween()
	if tweenCompletedConnection then
		tweenCompletedConnection:Disconnect()
		tweenCompletedConnection = nil
	end

	if visibilityTween then
		visibilityTween:Cancel()
		visibilityTween = nil
	end
end

local function setShown(shouldShow: boolean)
	local skipWave = frame
	local visiblePosition = shownPosition
	local hidden = hiddenPosition

	if not skipWave or not visiblePosition or not hidden or shouldShow == isShown then
		return
	end

	isShown = shouldShow
	cancelVisibilityTween()

	if shouldShow then
		if not skipWave.Visible then
			skipWave.Position = hidden
		end

		skipWave.Visible = true
	end

	local tweenInfo = if shouldShow then SHOW_TWEEN_INFO else HIDE_TWEEN_INFO
	local targetPosition = if shouldShow then visiblePosition else hidden
	local tween = TweenService:Create(skipWave, tweenInfo, { Position = targetPosition })

	visibilityTween = tween
	tweenCompletedConnection = tween.Completed:Connect(function()
		if visibilityTween ~= tween then
			return
		end

		if tweenCompletedConnection then
			tweenCompletedConnection:Disconnect()
			tweenCompletedConnection = nil
		end

		visibilityTween = nil

		if not isShown and frame then
			frame.Visible = false
		end
	end)

	tween:Play()
end

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

	amount.Visible = requiredVotes > 1
	amount.Text = string.format("(%d/%d)", getCount("SkipVotes"), requiredVotes)
	timerText.Text = tostring(getCount("TimeRemaining"))
	setShown(state:GetAttribute("CanSkip") == true)
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
	shownPosition = skipWave.Position
	local offscreenPosition = UDim2.new(
		skipWave.Position.X.Scale,
		skipWave.Position.X.Offset,
		-(1 - skipWave.AnchorPoint.Y) * skipWave.Size.Y.Scale - HIDDEN_MARGIN,
		-(1 - skipWave.AnchorPoint.Y) * skipWave.Size.Y.Offset
	)
	hiddenPosition = offscreenPosition
	isShown = false

	timer.Visible = true
	skipWave.Position = offscreenPosition
	skipWave.Visible = false

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
	cancelVisibilityTween()

	if frame then
		if shownPosition then
			frame.Position = shownPosition
		end

		frame.Visible = false
	end

	frame = nil
	amountLabel = nil
	timerLabel = nil
	matchState = nil
	shownPosition = nil
	hiddenPosition = nil
	isShown = false
end

return SkipWaveUI
