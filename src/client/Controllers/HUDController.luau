--!strict

local Players = game:GetService("Players")

local BaseHealthUI = require(script.Parent.HUD.BaseHealthUI)
local EnemyCountUI = require(script.Parent.HUD.EnemyCountUI)
local MoneyUI = require(script.Parent.HUD.MoneyUI)
local SkipWaveUI = require(script.Parent.HUD.SkipWaveUI)
local TimerUI = require(script.Parent.HUD.TimerUI)
local TowerMenuUI = require(script.Parent.HUD.TowerMenuUI)
local WaveUI = require(script.Parent.HUD.WaveUI)

local HUDController = {}

local started = false

function HUDController.SetMoney(amount: number)
	MoneyUI.Set(amount)
end

function HUDController.SetWave(wave: number)
	WaveUI.Set(wave)
end

function HUDController.SetTimer(seconds: number)
	TimerUI.Set(seconds)
end

function HUDController.SetEnemyCount(count: number)
	EnemyCountUI.Set(count)
end

function HUDController.SetBaseHealth(health: number, maxHealth: number)
	BaseHealthUI.Set(health, maxHealth)
end

function HUDController.ShowTowerMenu(towerName: string, ownerUserId: number)
	TowerMenuUI.Show(towerName, ownerUserId)
end

function HUDController.HideTowerMenu()
	TowerMenuUI.Hide()
end

function HUDController.Start(): boolean
	if started then
		return false
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = playerGui:WaitForChild("ScreenGui") :: ScreenGui
	local hud = screenGui:WaitForChild("HUD")
	local top = hud:WaitForChild("Top")

	screenGui.ResetOnSpawn = false

	MoneyUI.Start(hud:WaitForChild("Coins"))
	WaveUI.Start(top:WaitForChild("Wave") :: TextLabel)
	TimerUI.Start(top:WaitForChild("Timer") :: TextLabel)
	EnemyCountUI.Start(top:WaitForChild("EnemyCount") :: TextLabel)
	BaseHealthUI.Start(hud:WaitForChild("HPbar"))
	SkipWaveUI.Start(hud:WaitForChild("SkipWave") :: GuiObject)
	TowerMenuUI.Start(hud:WaitForChild("UnitUpgrade") :: GuiObject)

	started = true

	return true
end

function HUDController.Stop(): boolean
	if not started then
		return false
	end

	MoneyUI.Stop()
	WaveUI.Stop()
	TimerUI.Stop()
	EnemyCountUI.Stop()
	BaseHealthUI.Stop()
	SkipWaveUI.Stop()
	TowerMenuUI.Stop()
	started = false

	return true
end

return HUDController
