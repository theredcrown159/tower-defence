--!strict

local CombatController = require(script.Parent.Controllers.CombatController)
local EnemyController = require(script.Parent.Controllers.EnemyController)
local TowerController = require(script.Parent.Controllers.TowerController)

CombatController.Start()
TowerController.Start()
EnemyController.Start()
