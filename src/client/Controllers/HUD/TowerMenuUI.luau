--!strict

local Players = game:GetService("Players")

local TowerMenuUI = {}

local menu: GuiObject? = nil
local titleLabel: TextLabel? = nil
local ownerLabel: TextLabel? = nil

local function getOwnerName(ownerUserId: number): string
	local owner = Players:GetPlayerByUserId(ownerUserId)

	if owner == Players.LocalPlayer then
		return "Me"
	end

	return if owner then owner.DisplayName else tostring(ownerUserId)
end

function TowerMenuUI.Start(unitUpgrade: GuiObject)
	menu = unitUpgrade
	titleLabel = unitUpgrade:WaitForChild("Title") :: TextLabel
	ownerLabel = unitUpgrade:WaitForChild("Owner") :: TextLabel
	unitUpgrade.Active = true
	unitUpgrade.Visible = false
end

function TowerMenuUI.Show(towerName: string, ownerUserId: number)
	if not menu or not titleLabel or not ownerLabel then
		return
	end

	titleLabel.Text = towerName:gsub("_", " ")
	ownerLabel.Text = `Owner: {getOwnerName(ownerUserId)}`
	menu.Visible = true
end

function TowerMenuUI.Hide()
	if menu then
		menu.Visible = false
	end
end

function TowerMenuUI.Stop()
	TowerMenuUI.Hide()
	menu = nil
	titleLabel = nil
	ownerLabel = nil
end

return TowerMenuUI
