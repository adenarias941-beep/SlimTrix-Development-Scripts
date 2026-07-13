local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local redeemCodeRemote = remotes:WaitForChild("RedeemCode")

local MainGui = script.Parent

local LeftFrame = MainGui:WaitForChild("LeftFrame")

local Codes = MainGui:WaitForChild("Codes")
local CodesMain = Codes:WaitForChild("Main")
local enterCode = CodesMain:WaitForChild("EnterCode")
local enterCodeButton = CodesMain:WaitForChild("EnterCodeButton")

enterCodeButton.Activated:Connect(function()
	local codeText = enterCode.Text
	if codeText and codeText ~= "" then
		redeemCodeRemote:FireServer(codeText)
	end
end)

local panels = {
	{ buttonName = "CodesButton",   frameName = "Codes"   },
	{ buttonName = "ShopButton",    frameName = "Shop"    },
	{ buttonName = "ExploreButton", frameName = "Explore" },
	{ buttonName = "SettingsButton", frameName = "Settings" },
}

for _, entry in ipairs(panels) do
	local button = LeftFrame:WaitForChild(entry.buttonName)
	local frame = MainGui:WaitForChild(entry.frameName)
	local title = frame:WaitForChild("Title")
	local closeButton = title:WaitForChild("CloseButton")

	frame.Visible = false

	button.Activated:Connect(function()
		frame.Visible = not frame.Visible
	end)

	closeButton.Activated:Connect(function()
		frame.Visible = false
	end)
end
