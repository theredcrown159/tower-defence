export type EnemyDefinition = {
	ModelName: string,
	MaxHealth: number,
	MoveSpeed: number,
	BaseDamage: number,
	Reward: number,
	AbilityIds: { string },
}

local EnemyDefinitions: { [string]: EnemyDefinition } = {
	Basic = {
		ModelName = "Basic",
		MaxHealth = 100,
		MoveSpeed = 6,
		BaseDamage = 1,
		Reward = 10,
		AbilityIds = {},
	},
}

return EnemyDefinitions
