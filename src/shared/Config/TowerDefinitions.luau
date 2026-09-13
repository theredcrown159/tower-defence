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
	TargetModes: { TargetMode },
	AbilityIds: { string },
}

local TowerDefinitions: { [string]: TowerDefinition } = {
	Classical = {
		ModelName = "Classical",
		Levels = {
			{
				Cost = 100,
				Damage = 100,
				Range = 18,
				AttackCooldown = 1,
			},
			{
				Cost = 200,
				Damage = 180,
				Range = 20,
				AttackCooldown = 0.9,
			},
			{
				Cost = 400,
				Damage = 300,
				Range = 23,
				AttackCooldown = 0.75,
			},
		},
		TargetModes = { "First", "Last", "Strongest" },
		AbilityIds = {},
	},
}

return TowerDefinitions
