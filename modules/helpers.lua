local helpers = {}

---@param hex string
---@return number[]
function helpers.hex_to_rgb(hex)
  local r, g, b = hex:match("#?(.[%x]+)(.[%x]+)(.[%x]+)")
  if not r or not g or not b then return Color(1, 1, 1, 1) end

  return Color(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255)
end

return helpers