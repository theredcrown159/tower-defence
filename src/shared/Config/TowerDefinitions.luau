--!strict

export type TowerDefinition = {
	ModelName: string,
	Damage: number,
	Range: number,
	AttackCooldown: number,
	Cost: number,
	AbilityIds: { string },
}

local TowerDefinitions: { [string]: TowerDefinition } = {
	Classical = {
		ModelName = "Classical",
		Damage = 100,
		Range = 18,
		AttackCooldown = 1,
		Cost = 100,
		AbilityIds = {},
	},
}

return TowerDefinitions
