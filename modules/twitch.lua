--[[
  https://github.com/shockpast/twisaac
      Twitch, but inside of Isaac.

  If you will use this module inside of other mod, please credit me :)
]]

--
local socket = require("socket")

local helpers = include("modules/helpers")

---@class Twitch
local twitch = {}
twitch.messages = {}
twitch.badges = {}

local sfx = SFXManager()

---@param message string
local function parse_message(message)
  local message_entity = {}

  -- parse tags
  do
    local tags = {}

    local tag_part, rest = message:match("^@(.-) (.+)")
    if tag_part then
      for k, v in tag_part:gmatch("([^=;]+)=([^;]*)") do
        tags[k] = v
      end
    end

    message_entity.tags = tags
    message = rest or message
  end

  -- parse badges
  do
    local badges = {}

    for badge, version in message_entity.tags.badges:gmatch("([^/,]+)/([^/,]+)") do
      badges[badge] = tonumber(version) or version
    end

    message_entity.badges = badges
  end

  -- parse id
  do
    message_entity.id = message_entity.tags.id or "unknown"
  end

  -- parse timestamp
  do
    local timestamp = tonumber(message_entity.tags["tmi-sent-ts"]) or 0
    message_entity.timestamp = os.date("%H:%M:%S", math.floor(timestamp / 1000))
  end

  -- parse color
  do
    local color = message_entity.tags.color
    message_entity.color = color and helpers.hex_to_rgb(color) or nil
  end

  -- parse default data
  do
    local prefix, command, channel, text = message:match(":(%S+) (%S+) (%S+) :(.*)")
    message_entity.prefix = prefix
    message_entity.command = command
    message_entity.channel = channel
    message_entity.username = prefix:match("^(.-)!")
    message_entity.text = text
  end

  return message_entity
end

---@param channel string
---@param username string
---@param token string
function twitch:connect(channel, username, token)
  self.socket = socket.tcp()
  self.socket:settimeout(5)

  local ok, err = self.socket:connect("irc.chat.twitch.tv", 6667)
  if not ok then
    print(string.format("[twisaac] connection failed: %s", tostring(err)))
    return nil
  end

  self.channel = channel
  self.username = username

  self.socket:send(string.format("PASS oauth:%s\r\n", token))
  self.socket:send(string.format("NICK %s\r\n", username))
  self.socket:send(string.format("JOIN #%s\r\n", channel))
  self.socket:send("CAP REQ :twitch.tv/membership twitch.tv/tags\r\n") -- chat metadata

  self.messages[channel] = {}

  print(string.format("[twisaac] connected to #%s", channel))

  return twitch
end

function twitch:receive()
  while self.socket do
    self.socket:settimeout(0)
    local message, err = self.socket:receive("*l")

    if message ~= nil then
      if string.sub(message, 0, #"PING") == "PING" then
        print(message)
        print("[twisaac] ping-pong!")

        self.socket:send("PONG :tmi.twitch.tv\r\n")
      end

      if string.sub(message, 0, #"@badge-info") ~= "@badge-info" then return end
      if #self.messages > 5 then table.remove(self.messages, 1) end

      sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES)

      self.messages[#self.messages + 1] = parse_message(message)
    end

    if err and err ~= "timeout" then
      print("[twisaac] error: " .. tostring(err))

      self.socket:close()
      self.socket = nil
    end

    coroutine.yield()
  end
end

function twitch:reply(id, message)
  if id == nil or tonumber(id) == nil then return end
  if #message <= 0 then return end

  local message_entity = self.messages[tonumber(id)]
  if message_entity == nil then return end

  self.socket:send(string.format("@reply-parent-msg-id=%s PRIVMSG #%s :%s\r\n", message_entity.id, self.channel, message))

  print("[twisaac] > " .. message)
end

function twitch:say(message)
  if #message <= 0 then return end

  self.socket:send(string.format("PRIVMSG #%s :%s\r\n", self.channel, message))

  print("[twisaac] > " .. message)
end

--
do
  local badge_names = { "broadcaster", "moderator", "turbo", "verified", "vip" }

  for i = 16, 5 * 16, 16 do
    local sprite = Sprite()
    sprite:Load("gfx/ui/twisaac/badges.anm2", true)
    sprite:Play("Root", true)
    sprite:SetFrame((i / 16) - 1)

    twitch.badges[badge_names[i / 16]] = sprite
  end
end
--

return twitch