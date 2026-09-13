--!strict

local EnemyCountUI = {}

local label: TextLabel? = nil

function EnemyCountUI.Start(enemyCountLabel: TextLabel)
	label = enemyCountLabel
	label.Text = "..."
end

function EnemyCountUI.Set(count: number)
	if label then
		label.Text = tostring(math.max(0, math.floor(count)))
	end
end

function EnemyCountUI.Stop()
	label = nil
end

return EnemyCountUI
