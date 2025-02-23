package.loaded["modules/chatter"] = nil
package.loaded["config"] = nil

local twitch = include("modules/twitch")
local chatter = require("modules/chatter")
local helpers = include("modules/helpers")
local config = include("config")

---@type ModReference
local mod = RegisterMod("TwIsaac", 1)

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

local game = Game()

-- coroutine that will receive incoming messages
local recv_co = nil
-- twitch's modules client
local client = nil

local callbacks = {}

function callbacks:post_update()
  if client == nil then return end
  if recv_co ~= nil and coroutine.status(recv_co) ~= "dead" then coroutine.resume(recv_co) end

  recv_co = coroutine.create(function() twitch:receive() end)

  if recv_co == nil then return end
  if coroutine.status(recv_co) == "dead" then return end

  --
  coroutine.resume(recv_co)

  --
  chatter:update()
end

function callbacks:post_render()
  local room = game:GetRoom()
  if room:GetFrameCount() < 1 then return end
  if client == nil then return end

  for username, data in pairs(chatter.entities) do
    local entity_pointer = data.entity
    if entity_pointer == nil then goto ocontinue end
    if entity_pointer.Ref == nil then goto ocontinue end

    ---@type Entity
    local entity = entity_pointer.Ref
    local position = Isaac.WorldToScreen(entity.Position)

    --
    local username_x = position.X - font:GetStringWidthUTF8(username) / (2 / 0.5)

    do -- draw username
      local color = data.messages[#data.messages].color
      local r, g, b = color.R, color.G, color.B

      font:DrawStringScaledUTF8(username, username_x, position.Y, 0.5, 0.5, KColor(r, g, b, 1))
    end

    do -- draw message
      if data.last_message then
        font:DrawStringScaledUTF8(data.last_message, position.X - font:GetStringWidthUTF8(data.last_message) / (2 / 0.5), position.Y - 7, 0.5, 0.5, KColor(1, 1, 1, data.alpha))
      end
    end

    do -- draw badges
      for name, _ in pairs(data.messages[#data.messages].badges) do
        ---@type Sprite
        local badge = client.badges[name]
        if badge == nil then goto icontinue end

        username_x = username_x - 10

        badge.Scale = Vector(0.5, 0.5)
        badge:Render(Vector(username_x, position.Y), Vector.Zero, Vector.Zero)

        ::icontinue::
      end
    end

    ::ocontinue::
  end
end

---@param cmd string
---@param params string
function callbacks:execute_cmd(cmd, params)
  if client == nil then return end

  local arguments = helpers.extract_arguments(params)

  if cmd == "twisaac_say" then -- message
    client:say(params)
  end

  if cmd == "twisaac_reply" then -- id, ...message
    local id = table.remove(arguments, 1)
    local message = ""

    for _, v in ipairs(arguments) do message = message .. " " .. v end

    client:reply(id, message)
  end
end

function callbacks:post_game_started(is_continued)
  if is_continued then return end
  chatter:reset()
end

function callbacks:post_game_end()
  chatter:reset()
end

-- otherwise it will save position from previous room, and spawn at the same place
-- instead we'll set their position to player's position after room entered (same as familiars logic)
function callbacks:post_new_room()
  for _, data in pairs(chatter.entities) do
    ---@type Entity|nil
    local entity = data.entity.Ref
    if entity == nil then goto icontinue end

    entity.Position = Isaac.GetPlayer().Position

    ::icontinue::
  end
end

--
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, callbacks.post_update)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, callbacks.post_render)
mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, callbacks.execute_cmd)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, callbacks.post_game_started)
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, callbacks.post_game_end)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, callbacks.post_new_room)

--
client = twitch:connect(config.channel, config.username, config.token)