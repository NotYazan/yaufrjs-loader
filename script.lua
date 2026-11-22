local Update = 217
local DiscordUrl = "https://discord.gg/yaufrjs"
local LicenseUrl = "http://127.0.0.1:3010/api/verify"

local function Clean(Value)
	if type(Value) ~= "string" then
		return nil
	end
	Value = string.gsub(Value, "%s+", "")
	if Value == "" then
		return nil
	end
	return Value
end

local function SavedDevice()
	if readfile and isfile and isfile("yaufrjs/device.txt") then
		local Ok, Text = pcall(readfile, "yaufrjs/device.txt")
		local Saved = Ok and Clean(Text)
		if Saved then
			return Saved
		end
	end
	local Id = string.gsub(game:GetService("HttpService"):GenerateGUID(false), "%W", "")
	pcall(function()
		if makefolder then
			makefolder("yaufrjs")
		end
	end)
	if writefile then
		pcall(writefile, "yaufrjs/device.txt", Id)
	end
	return Id
end

local function DeviceId()
	if type(gethwid) == "function" then
		local Ok, Value = pcall(gethwid)
		local Id = Ok and Clean(Value)
		if Id then
			return Id
		end
	end
	local Ok, Value = pcall(function()
		return game:GetService("RbxAnalyticsService"):GetClientId()
	end)
	return (Ok and Clean(Value)) or SavedDevice()
end

local function KeyText()
	local Value = getgenv and getgenv().YaufrjsKey
	local Typed = Clean(Value)
	if Typed then
		return string.upper(Typed)
	end
	if readfile and isfile and isfile("yaufrjs/key.txt") then
		local Ok, Text = pcall(readfile, "yaufrjs/key.txt")
		local Saved = Ok and Clean(Text)
		if Saved then
			return string.upper(Saved)
		end
	end
	return ""
end

local function ReasonText(Reason)
	if Reason == "invalid_key" then
		return "That key is not in the list"
	end
	if Reason == "disabled" then
		return "This key is turned off"
	end
	if Reason == "expired" then
		return "This key has expired"
	end
	if Reason == "hwid_mismatch" then
		return "This key is already used on another device"
	end
	if Reason == "missing_key" then
		return "Enter a key"
	end
	if Reason == "missing_hwid" then
		return "This executor did not give a device id"
	end
	if Reason == "rate" then
		return "Wait a moment and try again"
	end
	if Reason == "no_tool" then
		return "The tool is not on the activation server"
	end
	return "Activation server is not running"
end

local function SaveKey(Key)
	pcall(function()
		if makefolder then
			makefolder("yaufrjs")
		end
	end)
	if writefile then
		pcall(writefile, "yaufrjs/key.txt", Key)
	end
end

local function OpenDiscord()
	local function Try(Fn)
		if type(Fn) ~= "function" then
			return false
		end
		return pcall(Fn, DiscordUrl)
	end
	if type(setclipboard) == "function" then
		pcall(setclipboard, DiscordUrl)
	elseif type(toclipboard) == "function" then
		pcall(toclipboard, DiscordUrl)
	end
	if type(syn) == "table" and Try(syn.open_url) then
		return true
	end
	if Try(openurl) or Try(OpenUrl) then
		return true
	end
	if type(os) == "table" and type(os.execute) == "function" then
		local Ok, Result = pcall(os.execute, 'start "" "' .. DiscordUrl .. '"')
		if Ok and Result ~= false and Result ~= nil then
			return true
		end
	end
	pcall(function()
		game:GetService("GuiService"):OpenBrowserWindow(DiscordUrl)
	end)
	return false
end

local function AskServer(Key, Id)
	local Request = request or http_request or (syn and syn.request)
	if not Request then
		return false, "This executor cannot reach the activation server"
	end
	local Http = game:GetService("HttpService")
	local Ok, Res = pcall(Request, {
		Url = LicenseUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["User-Agent"] = "Mozilla/5.0",
		},
		Body = Http:JSONEncode({ key = Key, hwid = Id, issue = true }),
	})
	if not Ok or type(Res) ~= "table" then
		return false, ReasonText("down")
	end
	local Body = Res.Body or Res.body
	if type(Body) ~= "string" or Body == "" then
		return false, ReasonText("down")
	end
	local Parsed = {}
	pcall(function()
		Parsed = Http:JSONDecode(Body)
	end)
	local Code = tonumber(Res.StatusCode or Res.Status or Res.status_code)
	if Code == 200 and type(Parsed) == "table" and Parsed.ok == true and type(Parsed.tool) == "string" and string.find(Parsed.tool, "local Update", 1, true) then
		if getgenv then
			getgenv().YaufrjsKey = Key
			getgenv().YaufrjsGrant = true
		end
		local Fn = loadstring(Parsed.tool)
		if type(Fn) ~= "function" then
			if getgenv then
				getgenv().YaufrjsGrant = nil
			end
			return false, ReasonText("no_tool")
		end
		local Ran = pcall(Fn)
		if not Ran and getgenv then
			getgenv().YaufrjsGrant = nil
		end
		if not Ran then
			return false, ReasonText("down")
		end
		return true, "Checked"
	end
	return false, ReasonText(type(Parsed) == "table" and Parsed.reason or nil)
end

local function PromptKey(Id)
	local Core = game:GetService("CoreGui")
	if type(gethui) == "function" then
		local HostOk, Host = pcall(gethui)
		if HostOk and Host then
			Core = Host
		end
	end
	local Old = Core:FindFirstChild("yaufrjs-activate")
	if Old then
		Old:Destroy()
	end
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "yaufrjs-activate"
	Gui.ResetOnSpawn = false
	Gui.DisplayOrder = 2000
	local Placed = pcall(function()
		Gui.Parent = Core
	end)
	if not Placed then
		Gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end
	local Dim = Instance.new("Frame")
	Dim.Size = UDim2.fromScale(1, 1)
	Dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Dim.BackgroundTransparency = 0.45
	Dim.BorderSizePixel = 0
	Dim.Parent = Gui
	local Card = Instance.new("Frame")
	Card.AnchorPoint = Vector2.new(0.5, 0.5)
	Card.Position = UDim2.fromScale(0.5, 0.5)
	Card.Size = UDim2.fromOffset(340, 196)
	Card.BackgroundColor3 = Color3.fromRGB(22, 20, 24)
	Card.BorderSizePixel = 0
	Card.Parent = Dim
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Card
	local Title = Instance.new("TextLabel")
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.fromOffset(16, 14)
	Title.Size = UDim2.new(1, -32, 0, 22)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 18
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Text = "Key"
	Title.Parent = Card
	local Box = Instance.new("TextBox")
	Box.Position = UDim2.fromOffset(16, 44)
	Box.Size = UDim2.new(1, -32, 0, 34)
	Box.BackgroundColor3 = Color3.fromRGB(14, 13, 14)
	Box.BorderSizePixel = 0
	Box.ClearTextOnFocus = false
	Box.Font = Enum.Font.Gotham
	Box.TextSize = 15
	Box.PlaceholderText = "XXXX-XXXX-XXXX"
	Box.PlaceholderColor3 = Color3.fromRGB(165, 164, 165)
	Box.TextColor3 = Color3.fromRGB(255, 255, 255)
	Box.Text = KeyText()
	Box.Parent = Card
	local BoxCorner = Instance.new("UICorner")
	BoxCorner.CornerRadius = UDim.new(0, 8)
	BoxCorner.Parent = Box
	local Status = Instance.new("TextLabel")
	Status.BackgroundTransparency = 1
	Status.Position = UDim2.fromOffset(16, 82)
	Status.Size = UDim2.new(1, -32, 0, 16)
	Status.Font = Enum.Font.Gotham
	Status.TextSize = 12
	Status.TextWrapped = true
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.TextColor3 = Color3.fromRGB(255, 140, 40)
	Status.Text = Id == "" and ReasonText("missing_hwid") or ""
	Status.Parent = Card
	local Button = Instance.new("TextButton")
	Button.Position = UDim2.fromOffset(16, 106)
	Button.Size = UDim2.new(1, -32, 0, 34)
	Button.BackgroundColor3 = Color3.fromRGB(209, 37, 109)
	Button.BorderSizePixel = 0
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 14
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.Text = "Check"
	Button.AutoButtonColor = false
	Button.Parent = Card
	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 8)
	ButtonCorner.Parent = Button
	local Free = Instance.new("TextButton")
	Free.Position = UDim2.fromOffset(16, 148)
	Free.Size = UDim2.fromOffset(150, 34)
	Free.BackgroundColor3 = Color3.fromRGB(32, 29, 36)
	Free.BorderSizePixel = 0
	Free.Font = Enum.Font.GothamBold
	Free.TextSize = 13
	Free.TextColor3 = Color3.new(1, 1, 1)
	Free.Text = "Free key"
	Free.AutoButtonColor = false
	Free.Parent = Card
	local FreeCorner = Instance.new("UICorner")
	FreeCorner.CornerRadius = UDim.new(0, 8)
	FreeCorner.Parent = Free
	local Discord = Instance.new("TextButton")
	Discord.Position = UDim2.fromOffset(174, 148)
	Discord.Size = UDim2.fromOffset(150, 34)
	Discord.BackgroundColor3 = Color3.fromRGB(32, 29, 36)
	Discord.BorderSizePixel = 0
	Discord.Font = Enum.Font.GothamBold
	Discord.TextSize = 13
	Discord.TextColor3 = Color3.new(1, 1, 1)
	Discord.Text = "Discord"
	Discord.AutoButtonColor = false
	Discord.Parent = Card
	local DiscordCorner = Instance.new("UICorner")
	DiscordCorner.CornerRadius = UDim.new(0, 8)
	DiscordCorner.Parent = Discord
	Free.MouseButton1Click:Connect(function()
		if type(setclipboard) == "function" then
			pcall(setclipboard, DiscordUrl)
		elseif type(toclipboard) == "function" then
			pcall(toclipboard, DiscordUrl)
		end
		Status.TextColor3 = Color3.fromRGB(255, 255, 255)
		Status.Text = DiscordUrl
	end)
	Discord.MouseButton1Click:Connect(function()
		OpenDiscord()
		Status.TextColor3 = Color3.fromRGB(255, 255, 255)
		Status.Text = DiscordUrl
	end)
	local Finished, Accepted, Checking = false, false, false
	local AutoTried = false
	local function TryCheck()
		if Checking or Finished then
			return
		end
		local Key = string.upper(Clean(Box.Text) or "")
		if Key == "" then
			Status.Text = ReasonText("missing_key")
			return
		end
		Checking = true
		Button.Text = "Checking"
		local Passed, Message = AskServer(Key, Id)
		if Passed then
			SaveKey(Key)
			Accepted = true
			Finished = true
		else
			Checking = false
			if Button.Parent then
				Button.Text = "Check"
			end
			if Status.Parent then
				Status.TextColor3 = Color3.fromRGB(255, 140, 40)
				Status.Text = Message
			end
		end
	end
	Button.MouseButton1Click:Connect(TryCheck)
	task.delay(3, function()
		if AutoTried or Finished or not Gui.Parent then
			return
		end
		AutoTried = true
		TryCheck()
	end)
	while not Finished and Gui.Parent do
		task.wait(0.1)
	end
	if Gui.Parent then
		Gui:Destroy()
	end
	return Accepted
end

PromptKey(DeviceId())
