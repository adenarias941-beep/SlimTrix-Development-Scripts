local Leaderstats = {}

local STATS = {
	Coins = 0,
	AP = 0,
}

function Leaderstats.Create(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	for statName, defaultValue in pairs(STATS) do
		local value = Instance.new("IntValue")
		value.Name = statName
		value.Value = defaultValue
		value.Parent = leaderstats
	end

	return leaderstats
end

function Leaderstats.Get(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end
	return leaderstats:FindFirstChild(statName)
end

function Leaderstats.GetAll(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return {} end

	local data = {}
	for statName in pairs(STATS) do
		local stat = leaderstats:FindFirstChild(statName)
		data[statName] = stat and stat.Value or STATS[statName]
	end
	return data
end

function Leaderstats.GetDefaults()
	local copy = {}
	for k, v in pairs(STATS) do
		copy[k] = v
	end
	return copy
end

return Leaderstats
