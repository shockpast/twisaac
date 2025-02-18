local twitch = include("modules/twitch")
local helpers = include("modules/helpers")
local data = include("data")

---@type ModReference
local mod = RegisterMod("TwIsaac", 1)

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

-- corountine that will receive incoming messages
local recv_co = nil
-- twitch's modules client
local client = nil

local callbacks = {}

function callbacks:post_update()
  if client == nil then return end

  recv_co = coroutine.create(function() twitch:receive() end)

  if recv_co == nil then return end
  if coroutine.status(recv_co) == "dead" then return end

  coroutine.resume(recv_co)
end

function callbacks:post_render()
  if client == nil then return end

  local screen_height = Isaac.GetScreenHeight()

  font:DrawStringScaledUTF8(string.format("#%s", client.channel), 50, screen_height - 15, 0.5, 0.5, KColor(1, 1, 1, 1))

  for index, message in ipairs(client.messages) do
    local username = string.format("%s", message.tags["display-name"])
    local text = string.format(": %s", message.text)
    local timestamp = string.format("@ %s", message.timestamp)

    local username_width = font:GetStringWidthUTF8(username)
    local total_width = font:GetStringWidthUTF8(username .. text)

    local r, g, b = table.unpack(message.color or { 1, 1, 1 })

    local base_x = 53
    local base_y = screen_height - 17 - (index * 10)

    for name, _ in pairs(message.badges) do
      ---@type Sprite
      local badge = client.badges[name]
      if badge == nil then goto icontinue end

      base_x = base_x + 16 - 5 -- move username

      badge.Scale = Vector(0.5, 0.5)
      badge:Render(Vector(base_x - (16 - 5), base_y), Vector.Zero, Vector.Zero) -- render badge at old username position

      ::icontinue::
    end

    font:DrawStringScaledUTF8(username, base_x, base_y, 0.5, 0.5, KColor(r, g, b, 1))
    font:DrawStringScaledUTF8(text, base_x + username_width / 2, base_y, 0.5, 0.5, KColor.White)
    font:DrawStringScaledUTF8(timestamp, base_x + (total_width / 2) + 2, base_y, 0.5, 0.5, KColor(1, 1, 1, 0.4))
  end
end

---@param cmd string
---@param params string
function callbacks:execute_cmd(cmd, params)
  if client == nil then return end

  local arguments = helpers.extract_arguments(params)

  if cmd == "twisaac_say" then
    client:say(params)
  end

  if cmd == "twisaac_reply" then -- id, ...message
    local id = table.remove(arguments, 1)
    local message = ""

    for _, v in ipairs(arguments) do message = message .. " " .. v end

    client:reply(id, message)
  end
end

--
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, callbacks.post_update)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, callbacks.post_render)
mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, callbacks.execute_cmd)

--
client = twitch:connect(data.channel, data.username, data.token)