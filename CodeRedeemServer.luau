local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Main = game.ServerScriptService.Main
local DataSave = require(Main.DataSave)

local remotes = ReplicatedStorage.Remotes
local redeemCodeRemote = remotes.RedeemCode
local notifAdd = remotes.NotifAdd
local notifUnadd = remotes.NotifUnadd

local codeStore = DataStoreService:GetDataStore("CodeRedemption_V1")
local NOTIF_DURATION = 5

local CODES = {
	["very_early"] = { rewards = { Coins = 100000, AP = 1 }, maxUses = 1 },
	["super"] = { rewards = { Coins = 5000, AP = 1 }, maxUses = 1 },
	["starter"] = { rewards ={ Coins = 2500}, maxuses = 2}
}

local playerCodeData = {}

local function loadPlayerCodes(player)
	local key = "player_" .. player.UserId
	local data = nil
	local success, err = pcall(function()
		data = codeStore:GetAsync(key)
	end)
	if success and type(data) == "table" then
		playerCodeData[player] = data
	else
		playerCodeData[player] = {}
	end
end

local function savePlayerCodes(player)
	local key = "player_" .. player.UserId
	local data = playerCodeData[player]
	if not data then return end
	local success, err = pcall(function()
		codeStore:SetAsync(key, data)
	end)
	if not success then
		warn("[CodeRedeem] Failed to save code data for " .. player.Name .. ": " .. tostring(err))
	end
end

local function getStat(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end
	return leaderstats:FindFirstChild(statName)
end

local function sendNotif(player, text, isAdd)
	if isAdd then
		notifAdd:FireClient(player, text, NOTIF_DURATION)
	else
		notifUnadd:FireClient(player, text, NOTIF_DURATION)
	end
end

redeemCodeRemote.OnServerEvent:Connect(function(player, codeText)
	
	if type(codeText) ~= "string" then return end
	codeText = string.lower(string.match(codeText, "^%s*(.-)%s*$"))
	if codeText == "" then
		sendNotif(player, "Please enter a code.", false)
		return
	end

	local codeInfo = CODES[codeText]
	if not codeInfo then
		sendNotif(player, "Invalid code: " .. codeText, false)
		return
	end

	if not DataSave.IsLoaded(player) then
		sendNotif(player, "Your data is still loading. Try again in a moment.", false)
		return
	end

	if not playerCodeData[player] then
		loadPlayerCodes(player)
	end

	local usage = playerCodeData[player]
	local currentUses = usage[codeText] or 0

	if currentUses >= codeInfo.maxUses then
		sendNotif(player, "You have already used this code the maximum number of times.", false)
		return
	end

	local rewardTexts = {}
	for statName, amount in pairs(codeInfo.rewards) do
		local stat = getStat(player, statName)
		if stat then
			stat.Value = stat.Value + amount
			table.insert(rewardTexts, "+ " .. amount .. " " .. statName)
		end
	end

	usage[codeText] = currentUses + 1
	savePlayerCodes(player)

	task.spawn(function()
		DataSave.Save(player)
	end)

	local rewardStr = table.concat(rewardTexts, ", ")
	sendNotif(player, "Code redeemed! " .. rewardStr, true)
end)

local function onPlayerAdded(player)
	loadPlayerCodes(player)
end

local function onPlayerRemoving(player)
	savePlayerCodes(player)
	playerCodeData[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
