-- yaufrjs
local Payload = "https://raw.githubusercontent.com/NotYazan/yaufrjs-loader/main/script.lua"

local function Read(Url)
	local Req = request or http_request
	if type(Req) ~= "function" and type(syn) == "table" then
		Req = syn.request
	end
	if type(Req) == "function" then
		local Ok, Res = pcall(Req, {
			Url = Url,
			Method = "GET",
			Headers = { ["User-Agent"] = "Mozilla/5.0" },
		})
		if Ok and type(Res) == "table" then
			local Body = Res.Body or Res.body
			if type(Body) == "string" and string.find(Body, "local Update", 1, true) then
				return Body
			end
		end
	end
	local Ok, Body = pcall(function()
		return game:HttpGet(Url, true)
	end)
	if Ok and type(Body) == "string" and string.find(Body, "local Update", 1, true) then
		return Body
	end
	Ok, Body = pcall(function()
		return game:HttpGet(Url)
	end)
	if Ok and type(Body) == "string" and string.find(Body, "local Update", 1, true) then
		return Body
	end
	return nil
end

local Body = Read(Payload .. "?t=" .. tostring(os.time()))
if Body then
	loadstring(Body)()
end
