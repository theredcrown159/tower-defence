--!strict

local EnemyController = require(script.Parent.Controllers.EnemyController)
local HUDController = require(script.Parent.Controllers.HUDController)
local TowerController = require(script.Parent.Controllers.TowerController)
local TowerPlacementController = require(script.Parent.Controllers.TowerPlacementController)
local TowerSelectionController = require(script.Parent.Controllers.TowerSelectionController)
local VFXController = require(script.Parent.Controllers.VFXController)

VFXController.Start()
EnemyController.Start()
HUDController.Start()
TowerController.Start()
TowerSelectionController.Start()
TowerPlacementController.Start()
