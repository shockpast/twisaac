local helpers = {}

---@param hex string
---@return number[]
function helpers.hex_to_rgb(hex)
  local r, g, b = hex:match("#?(%x%x)(%x%x)(%x%x)")
  if not r or not g or not b then return { 1, 1, 1 } end

  return { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255 }
end

---@param params string
---@return string[]
function helpers.extract_arguments(params)
  local arguments = {}
  for word in string.gmatch(params, "[^%s]+") do arguments[#arguments + 1] = word end

  return arguments
end

return helpers