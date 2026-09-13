--!strict

export type TargetMode = "First" | "Last" | "Strongest"

export type TowerLevelDefinition = {
	Damage: number,
	Range: number,
	AttackCooldown: number,
	Cost: number,
}

export type TowerDefinition = {
	ModelName: string,
	Levels: { TowerLevelDefinition },
	AttackDuration: number,
	AttackHitTimes: { number },
	TargetModes: { TargetMode },
	AbilityIds: { string },
}

local TowerDefinitions: { [string]: TowerDefinition } = {
	Classical = {
		ModelName = "Classical",
		AttackDuration = 3.1667,
		AttackHitTimes = { 0.5833, 0.8, 0.95, 1.1333, 1.2833, 1.4333, 1.6167, 1.7833, 1.95, 2.1333 },
		Levels = {
			{
				Cost = 100,
				Damage = 100,
				Range = 18,
				AttackCooldown = 4,
			},
			{
				Cost = 200,
				Damage = 180,
				Range = 20,
				AttackCooldown = 3.75,
			},
			{
				Cost = 400,
				Damage = 300,
				Range = 23,
				AttackCooldown = 3.5,
			},
		},
		TargetModes = { "First", "Last", "Strongest" },
		AbilityIds = {},
	},
}

return TowerDefinitions
