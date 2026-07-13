local messaging_service = game:GetService("MessagingService")
local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local Main = game.ServerScriptService.Main
local DataSave = require(Main.DataSave)

local remotes = replicated_storage.Remotes
local notif_add_remote = remotes.NotifAdd
local notif_unadd_remote = remotes.NotifUnadd

local ALLOWED_IDS = {4158494426}
local TOPIC = "GlobalReward"
local NOTIF_DURATION = 5

local function get_stat(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end
	return leaderstats:FindFirstChild(statName)
end

local function apply_to_all_players(statName, amount)
	for _, player in players:GetPlayers() do
		if DataSave.IsLoaded(player) then
			local stat = get_stat(player, statName)
			if stat then
				stat.Value = stat.Value + amount
				task.spawn(function()
					DataSave.Save(player)
				end)
			end
		end
	end
end

local function format_notification(statName, amount, isAdd)
	if isAdd then
		return "<font color=\"rgb(70, 215, 95)\">+ " .. tostring(amount) .. " " .. statName .. "</font>"
	else
		return "<font color=\"rgb(250, 50, 60)\">- " .. tostring(math.abs(amount)) .. " " .. statName .. "</font>"
	end
end

local function setup_player(player)
	if not table.find(ALLOWED_IDS, player.UserId) then
		return
	end
	
	player.Chatted:Connect(function(chat_message)
		local args = string.split(chat_message, " ")
		local command = string.lower(args[1])
		
		local statName
		local isAdd
		
		if command == "/globalcoins" then
			statName = "Coins"
			isAdd = true
		elseif command == "/globalap" then
			statName = "AP"
			isAdd = true
		elseif command == "/globalunaddcoins" then
			statName = "Coins"
			isAdd = false
		elseif command == "/globalunaddap" then
			statName = "AP"
			isAdd = false
		else
			return
		end
		
		local amount = tonumber(args[2])
		if not amount then
			return
		end
		
		amount = math.floor(math.abs(amount))
		if not isAdd then
			amount = -amount
		end
		
		pcall(function()
			messaging_service:PublishAsync(TOPIC, { statName = statName, amount = amount, isAdd = isAdd })
		end)
	end)
end

for _, player in players:GetPlayers() do
	setup_player(player)
end

players.PlayerAdded:Connect(setup_player)

messaging_service:SubscribeAsync(TOPIC, function(message)
	local data = message.Data
	local statName = data.statName
	local amount = data.amount
	local isAdd = data.isAdd
	
	apply_to_all_players(statName, amount)
	
	local notif_text = format_notification(statName, amount, isAdd)
	if isAdd then
		notif_add_remote:FireAllClients(notif_text, NOTIF_DURATION)
	else
		notif_unadd_remote:FireAllClients(notif_text, NOTIF_DURATION)
	end
end)
