--[[
  https://github.com/shockpast/twisaac
      Twitch, but inside of Isaac.

  If you will use this module inside of other mod, please credit me :)
]]

--
local chatter = {}
chatter.entities = {}

-- game's tickrate seems to run 30 frames per seconds, so 90/30 = 3 seconds
local MESSAGE_DURATION = 90
-- when should text start to fade out, 30/30 = 1 second
local MESSAGE_FADE_OUT_TIME = 30

---@param username string
---@param message_entity table
function chatter:create(username, message_entity)
  if self.entities[username] ~= nil and self.entities[username].entity.Ref ~= nil then return end

  local game = Game()
  local player = game:GetPlayer(0)

  local entity = game:Spawn(EntityType.ENTITY_FLY, 0, player.Position, Vector.Zero, player, 0, game:GetSeeds():GetNextSeed())
  if entity == nil then return end

  entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_PERSISTENT | EntityFlag.FLAG_NO_QUERY)
  entity:SetColor(message_entity.color, 0, 1, false, true)
  entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
  entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

  self.entities[username] =  { entity = EntityPtr(entity), messages = {}, last_message = message_entity.text, message_timer = 0, alpha = 1 }
  self:add_message(username, message_entity)
end

---@param username string
---@param message_entity table parsed message from twitch#receive
function chatter:add_message(username, message_entity)
  local entity = self.entities[username]
  if entity == nil then return end

  if entity.entity.Ref == nil then
    self:create(username, message_entity)
    return
  end

  entity.last_message = message_entity.text
  entity.message_timer = MESSAGE_DURATION
  entity.alpha = 1
  entity.messages[#entity.messages + 1] = message_entity
end

function chatter:update()
  for _, data in pairs(self.entities) do
    if data.message_timer <= 0 then
      data.last_message = nil
      data.alpha = 1
    end

    if data.message_timer > 0 then
      data.message_timer = data.message_timer - 1

      if data.message_timer < MESSAGE_FADE_OUT_TIME then
        data.alpha = data.message_timer / MESSAGE_FADE_OUT_TIME
      end
    end
  end
end

function chatter:reset()
  self.entities = {}
  self.messages = {}
end

function chatter:remove(username)
  self.entities[username] = nil
end

return chatter