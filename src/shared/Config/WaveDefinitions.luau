--!strict

export type EnemyGroup = {
	EnemyName: string,
	Count: number,
	SpawnInterval: number,
}

export type WaveDefinition = {
	Duration: number,
	Groups: { EnemyGroup },
}

local WaveDefinitions: { WaveDefinition } = {
	-- {
	-- 	Groups = {
	-- 		{ EnemyName = "Bat_1", Count = 1, SpawnInterval = 2 },
	-- 		{ EnemyName = "Bat_2", Count = 1, SpawnInterval = 2 },
	-- 		{ EnemyName = "Shotgun", Count = 1, SpawnInterval = 2 },
	-- 		{ EnemyName = "Electric", Count = 1, SpawnInterval = 2 },
	-- 		{ EnemyName = "GreenGoblin", Count = 1, SpawnInterval = 2 },
	-- 	},
	-- },
	{
		Duration = 90,
		Groups = {
			{ EnemyName = "Bat_1", Count = 8, SpawnInterval = 0.9 },
		},
	},
	{
		Duration = 90,
		Groups = {
			{ EnemyName = "Bat_1", Count = 12, SpawnInterval = 0.8 },
		},
	},
	{
		Duration = 95,
		Groups = {
			{ EnemyName = "Bat_1", Count = 12, SpawnInterval = 0.75 },
			{ EnemyName = "Bat_2", Count = 4, SpawnInterval = 0.7 },
		},
	},
	{
		Duration = 100,
		Groups = {
			{ EnemyName = "Bat_1", Count = 16, SpawnInterval = 0.7 },
			{ EnemyName = "Bat_2", Count = 8, SpawnInterval = 0.6 },
		},
	},
	{
		Duration = 105,
		Groups = {
			{ EnemyName = "Bat_1", Count = 20, SpawnInterval = 0.65 },
			{ EnemyName = "Bat_2", Count = 10, SpawnInterval = 0.6 },
		},
	},
	{
		Duration = 110,
		Groups = {
			{ EnemyName = "Bat_1", Count = 18, SpawnInterval = 0.6 },
			{ EnemyName = "Bat_2", Count = 10, SpawnInterval = 0.55 },
			{ EnemyName = "Shotgun", Count = 2, SpawnInterval = 1.1 },
		},
	},
	{
		Duration = 115,
		Groups = {
			{ EnemyName = "Bat_1", Count = 20, SpawnInterval = 0.56 },
			{ EnemyName = "Bat_2", Count = 12, SpawnInterval = 0.5 },
			{ EnemyName = "Shotgun", Count = 4, SpawnInterval = 1 },
		},
	},
	{
		Duration = 120,
		Groups = {
			{ EnemyName = "Bat_1", Count = 18, SpawnInterval = 0.53 },
			{ EnemyName = "Bat_2", Count = 15, SpawnInterval = 0.47 },
			{ EnemyName = "Shotgun", Count = 5, SpawnInterval = 0.95 },
			{ EnemyName = "Electric", Count = 1, SpawnInterval = 0 },
		},
	},
	{
		Duration = 125,
		Groups = {
			{ EnemyName = "Bat_1", Count = 20, SpawnInterval = 0.5 },
			{ EnemyName = "Bat_2", Count = 18, SpawnInterval = 0.44 },
			{ EnemyName = "Shotgun", Count = 6, SpawnInterval = 0.9 },
			{ EnemyName = "Electric", Count = 2, SpawnInterval = 1.2 },
		},
	},
	{
		Duration = 145,
		Groups = {
			{ EnemyName = "Bat_1", Count = 20, SpawnInterval = 0.48 },
			{ EnemyName = "Bat_2", Count = 16, SpawnInterval = 0.42 },
			{ EnemyName = "Shotgun", Count = 6, SpawnInterval = 0.85 },
			{ EnemyName = "Electric", Count = 3, SpawnInterval = 1.1 },
			{ EnemyName = "GreenGoblin", Count = 1, SpawnInterval = 0 },
		},
	},
	{
		Duration = 140,
		Groups = {
			{ EnemyName = "Bat_1", Count = 24, SpawnInterval = 0.46 },
			{ EnemyName = "Bat_2", Count = 20, SpawnInterval = 0.4 },
			{ EnemyName = "Shotgun", Count = 8, SpawnInterval = 0.8 },
			{ EnemyName = "Electric", Count = 4, SpawnInterval = 1.05 },
		},
	},
	{
		Duration = 145,
		Groups = {
			{ EnemyName = "Bat_1", Count = 26, SpawnInterval = 0.44 },
			{ EnemyName = "Bat_2", Count = 22, SpawnInterval = 0.38 },
			{ EnemyName = "Shotgun", Count = 10, SpawnInterval = 0.76 },
			{ EnemyName = "Electric", Count = 5, SpawnInterval = 1 },
		},
	},
	{
		Duration = 150,
		Groups = {
			{ EnemyName = "Bat_1", Count = 28, SpawnInterval = 0.42 },
			{ EnemyName = "Bat_2", Count = 24, SpawnInterval = 0.36 },
			{ EnemyName = "Shotgun", Count = 12, SpawnInterval = 0.72 },
			{ EnemyName = "Electric", Count = 7, SpawnInterval = 0.95 },
		},
	},
	{
		Duration = 155,
		Groups = {
			{ EnemyName = "Bat_1", Count = 30, SpawnInterval = 0.4 },
			{ EnemyName = "Bat_2", Count = 28, SpawnInterval = 0.34 },
			{ EnemyName = "Shotgun", Count = 14, SpawnInterval = 0.68 },
			{ EnemyName = "Electric", Count = 9, SpawnInterval = 0.9 },
		},
	},
	{
		Duration = 170,
		Groups = {
			{ EnemyName = "Bat_1", Count = 30, SpawnInterval = 0.38 },
			{ EnemyName = "Bat_2", Count = 30, SpawnInterval = 0.32 },
			{ EnemyName = "Shotgun", Count = 15, SpawnInterval = 0.65 },
			{ EnemyName = "Electric", Count = 10, SpawnInterval = 0.85 },
			{ EnemyName = "GreenGoblin", Count = 1, SpawnInterval = 1.5 },
		},
	},
}

return WaveDefinitions
