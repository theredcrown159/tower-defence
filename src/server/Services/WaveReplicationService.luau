--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveService = require(script.Parent.WaveService)

local waveRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Waves")
local voteSkipEvent = waveRemotes:WaitForChild("VoteSkip")

local WaveReplicationService = {}

local voteConnection: RBXScriptConnection? = nil

local function onVoteRequested(player: Player, wantsToSkip: unknown)
	if typeof(wantsToSkip) ~= "boolean" then
		return
	end

	WaveService.TryVoteSkip(player, wantsToSkip)
end

function WaveReplicationService.Start(): boolean
	if voteConnection then
		return false
	end

	voteConnection = voteSkipEvent.OnServerEvent:Connect(onVoteRequested)

	return true
end

function WaveReplicationService.Stop(): boolean
	if not voteConnection then
		return false
	end

	voteConnection:Disconnect()
	voteConnection = nil

	return true
end

return WaveReplicationService
