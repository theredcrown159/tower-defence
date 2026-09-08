--!strict

export type EnemyDefinition = {
	ModelName: string,
	MaxHealth: number,
	MoveSpeed: number,
	BaseDamage: number,
	Reward: number,
	AbilityIds: { string },
}

local EnemyDefinitions: { [string]: EnemyDefinition } = {
	Bat_1 = {
		ModelName = "Bat_1",
		MaxHealth = 140,
		MoveSpeed = 4,
		BaseDamage = 5,
		Reward = 40,
		AbilityIds = {},
	},

	Bat_2 = {
		ModelName = "Bat_2",
		MaxHealth = 100,
		MoveSpeed = 6.5,
		BaseDamage = 4,
		Reward = 45,
		AbilityIds = {},
	},

	Shotgun = {
		ModelName = "Shotgun",
		MaxHealth = 350,
		MoveSpeed = 3,
		BaseDamage = 12,
		Reward = 100,
		AbilityIds = {},
	},

	Electric = {
		ModelName = "Electric",
		MaxHealth = 650,
		MoveSpeed = 4.5,
		BaseDamage = 15,
		Reward = 160,
		AbilityIds = {},
	},

	GreenGoblin = {
		ModelName = "GreenGoblin",
		MaxHealth = 3000,
		MoveSpeed = 2.5,
		BaseDamage = 50,
		Reward = 750,
		AbilityIds = {},
	},
}

return EnemyDefinitions
