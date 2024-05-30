if not file.Exists("player-hats.json", "DATA") then
	file.Write("player-hats.json", util.TableToJSON({
		["example-hat"] = {
			["model"] = "models/player/items/humans/top_hat.mdl",
			["attachment"] = "eyes",
			["offset"] = {
				["x"] = 0,
				["y"] = 0,
				["z"] = 0
			},
			["angles"] = {
				["p"] = 0,
				["y"] = 0,
				["r"] = 0
			},
			["conditions"] = {
				["activeweapon"] = "weapon_crowbar"
			}
		}
	}, true))
end
local isstring, isnumber, istable, Vector, Color, Angle, pairs, type = _G.isstring, _G.isnumber, _G.istable, _G.Vector, _G.Color, _G.Angle, _G.pairs, _G.type
local Clamp, floor = math.Clamp, math.floor
local hats, length = { }, 0
local loadHats
loadHats = function()
	local content = file.Read("player-hats.json", "DATA")
	if not content then
		error("Failed to load player-hats.json")
	end
	local json = util.JSONToTable(content)
	if not json then
		error("Failed to parse player-hats.json")
	end
	table.Empty(hats)
	length = 0
	for _, data in pairs(json) do
		local hatData = { }
		if not isstring(data.model) then
			print("[PlayerHats] Invalid hat model: " .. tostring(data.model))
			goto _continue_0
		end
		hatData.model = data.model
		local offset = data.offset
		if offset then
			hatData.offset = Vector(offset.x or 0, offset.y or 0, offset.z or 0)
		end
		local angles = data.angles
		if angles then
			hatData.angles = Angle(angles.p or 0, angles.y or 0, angles.r or 0)
		end
		local color = data.color
		if color then
			hatData.color = Color(color.red or color.r or 255, color.green or color.g or 255, color.blue or color.b or 255)
		end
		local skin = data.skin
		if isnumber(skin) then
			if skin < 0 then
				skin = 0
			end
			hatData.skin = skin
		end
		local bodygroups = data.bodygroups
		if isstring(bodygroups) then
			hatData.bodygroups = bodygroups
		end
		local alpha = data.alpha
		if isnumber(alpha) then
			hatData.alpha = Clamp(alpha, 0, 1)
		end
		local scale = data.scale
		if isnumber(scale) then
			hatData.scale = Clamp(scale, 0, 128)
		end
		local effects = data.effects
		if isnumber(effects) then
			hatData.effects = floor(effects)
		end
		local conditions = data.conditions
		if istable(conditions) then
			local result = { }
			for name, value in pairs(conditions) do
				if not isstring(name) then
					goto _continue_1
				end
				local _exp_0 = type(value)
				if "table" == _exp_0 then
					local lst = result[name]
					if not istable(lst) then
						lst = {
							lst
						}
						result[name] = lst
					end
					for _index_0 = 1, #value do
						local val = value[_index_0]
						if isstring(val) then
							lst[#lst + 1] = val
						end
					end
				elseif "string" == _exp_0 then
					local lst = result[name]
					if lst and not istable(lst) then
						lst = {
							lst
						}
						result[name] = lst
					end
					if name == "playercolor" or name == "weaponcolor" then
						if lst then
							lst[#lst + 1] = Vector(value)
						else
							result[name] = Vector(value)
						end
					elseif lst then
						lst[#lst + 1] = value
					else
						result[name] = value
					end
				end
				::_continue_1::
			end
			local lst, len = { }, 0
			for name, value in pairs(result) do
				len = len + 1
				lst[len] = {
					name,
					value
				}
			end
			hatData.conditions = lst
		end
		local material = data.material
		if isstring(material) then
			hatData.material = material
		end
		local attachment = data.attachment
		if isstring(attachment) then
			hatData.attachment = attachment
		end
		local bone = data.bone
		if isstring(bone) then
			hatData.bone = bone
		end
		local allow_player_color = data.allow_player_color
		if allow_player_color ~= nil then
			hatData.allow_player_color = allow_player_color ~= false
		end
		local allow_shadow = data.allow_shadow
		if allow_shadow ~= nil then
			hatData.allow_shadow = allow_shadow ~= false
		end
		length = length + 1
		hats[length] = hatData
		::_continue_0::
	end
	print("[PlayerHats] Loaded " .. length .. " hats.")
	return
end
util.AddNetworkString("Player Hats - Sync")
local players = { }
hook.Add("PlayerDisconnected", "PlayerHats - PlayerDisconnected", function(ply)
	players[ply] = nil
end)
local sendHats
sendHats = function(ply)
	net.Start("Player Hats - Sync")
	net.WriteTable(hats, true)
	net.Send(ply)
	return
end
hook.Add("SetupMove", "PlayerHats - SetupMove", function(ply, _, cmd)
	if players[ply] or not (cmd:IsForced() or ply:IsBot()) then
		return
	end
	players[ply] = true
	sendHats(ply)
	return
end)
local broadcastHats
broadcastHats = function()
	for _, ply in player.Iterator() do
		if not ply:IsBot() then
			sendHats(ply)
		end
	end
end
concommand.Add("player_hats_reload", function(ply)
	if ply and ply:IsValid() and not (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
		ply:ChatPrint("You do not have permission to use this command.")
		return
	end
	loadHats()
	broadcastHats()
	ply:ChatPrint("Hats reloaded.")
	return
end)
return timer.Simple(0.5, function()
	loadHats()
	broadcastHats()
	return
end)
