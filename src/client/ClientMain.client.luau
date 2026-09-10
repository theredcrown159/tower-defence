--!strict

local EnemyController = require(script.Parent.Controllers.EnemyController)
local TowerController = require(script.Parent.Controllers.TowerController)
local TowerPlacementController = require(script.Parent.Controllers.TowerPlacementController)

EnemyController.Start()
TowerController.Start()
TowerPlacementController.Start()
