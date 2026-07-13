local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("PlayerData_V1")

local AUTO_SAVE_INTERVAL = 60
local MAX_RETRIES = 6

local DataSave = {}

local loadedPlayers = {}

local function with_retry(callback)
	local attempts = 0
	while attempts < MAX_RETRIES do
		attempts += 1
		local success, result = pcall(callback)
		if success then
			return true, result
		end
		warn("[DataSave] Retry " .. attempts .. "/" .. MAX_RETRIES .. " error: " .. tostring(result))
		if attempts < MAX_RETRIES then
			task.wait(math.min(2 ^ attempts * 0.5, 10))
		end
	end
	return false, nil
end

function DataSave.Load(player)
	local key = "player_" .. player.UserId
	local data = nil

	local success = with_retry(function()
		data = DataStore:GetAsync(key)
	end)

	if not success then
		warn("[DataSave] CRITICAL: Failed to load data for " .. player.Name .. " (UserId: " .. player.UserId .. ")")
		return nil
	end

	if type(data) == "table" then
		loadedPlayers[player] = true
		return data
	end

	loadedPlayers[player] = true
	return { Coins = 0, AP = 0 }
end

function DataSave.IsLoaded(player)
	return loadedPlayers[player] == true
end

function DataSave.Save(player)
	if not loadedPlayers[player] then
		warn("[DataSave] Skipping save for " .. player.Name .. " - data not loaded yet")
		return false
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("[DataSave] No leaderstats found for " .. player.Name)
		return false
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local ap = leaderstats:FindFirstChild("AP")

	local data = {
		Coins = coins and coins.Value or 0,
		AP = ap and ap.Value or 0,
	}

	local key = "player_" .. player.UserId

	local success = with_retry(function()
		DataStore:UpdateAsync(key, function()
			return data
		end)
	end)

	if not success then
		warn("[DataSave] CRITICAL: Failed to save data for " .. player.Name .. " (UserId: " .. player.UserId .. ")")
	else
		print("[DataSave] Saved " .. player.Name .. ": Coins=" .. data.Coins .. " AP=" .. data.AP)
	end

	return success
end

function DataSave.ApplyData(player, data)
	if not data then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = data.Coins or 0 end

	local ap = leaderstats:FindFirstChild("AP")
	if ap then ap.Value = data.AP or 0 end
end

function DataSave.Unload(player)
	loadedPlayers[player] = nil
end

function DataSave.StartAutoSave()
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				if loadedPlayers[player] then
					task.spawn(function()
						DataSave.Save(player)
					end)
				end
			end
		end
	end)
end

function DataSave.SaveAll()
	local playersToSave = {}
	for _, player in Players:GetPlayers() do
		if loadedPlayers[player] then
			table.insert(playersToSave, player)
		end
	end

	local count = #playersToSave
	if count == 0 then return end

	local done = Instance.new("BindableEvent")

	for _, player in ipairs(playersToSave) do
		task.spawn(function()
			DataSave.Save(player)
			count -= 1
			if count == 0 then
				done:Fire()
			end
		end)
	end

	done.Event:Wait()
	done:Destroy()
end

return DataSave
