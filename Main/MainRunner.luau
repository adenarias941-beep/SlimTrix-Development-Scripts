local Players = game:GetService("Players")

local Main = script.Parent
local Leaderstats = require(Main.Leaderstats)
local DataSave = require(Main.DataSave)

local activePlayers = {}

local function onPlayerAdded(player)
	activePlayers[player] = true
	Leaderstats.Create(player)

	local data = DataSave.Load(player)

	if not activePlayers[player] then
		warn("[MainRunner] " .. player.Name .. " left while data was loading - skipping apply")
		return
	end

	if data == nil then
		warn("[MainRunner] Retrying data load for " .. player.Name .. "...")
		task.wait(3)

		if not activePlayers[player] then return end

		data = DataSave.Load(player)

		if not activePlayers[player] then return end

		if data == nil then
			warn("[MainRunner] CRITICAL: Failed to load data for " .. player.Name .. " - kicking to prevent data loss")
			player:Kick("Your data failed to load. Please rejoin the game.")
			return
		end
	end

	DataSave.ApplyData(player, data)
	print("[MainRunner] Loaded data for " .. player.Name .. ": Coins=" .. (data.Coins or 0) .. " AP=" .. (data.AP or 0))
end

local function onPlayerRemoving(player)
	activePlayers[player] = nil

	if DataSave.IsLoaded(player) then
		DataSave.Save(player)
	end

	DataSave.Unload(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

DataSave.StartAutoSave()

game:BindToClose(function()
	print("[MainRunner] Server closing - saving all player data...")
	DataSave.SaveAll()
	print("[MainRunner] All data saved successfully. Server can safely close.")
	task.wait(1)
