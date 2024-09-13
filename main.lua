local love = love
local lg = love.graphics

local flux = require "lib.flux"

local invertShader = lg.newShader [[
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
  vec4 p = Texel(texture, tc);
  return vec4(1 - p.r, 1 - p.g, 1 - p.b, p.a) * color;
}
]]

local itemsCanvas = lg.newCanvas()

local font = lg.newFont("fonts/Staatliches-Regular.ttf", 56)

local options = {
  "CONTINUE",
  "NEW GAME",
  "OPTIONS",
  "EXIT",
}

local selectedIndex = 1

---@type number[]
local polygonTargetPoints = {}

---@type number[]
local selectionPolygon = {}

---@param index number
local function getItemExtents(index)
  local x1, y1 = 0, (index - 1) * font:getHeight()
  local x2, y2 = font:getWidth(options[index]), y1 + font:getHeight()
  y1 = y1 + 5
  y2 = y2 - 5
  if index % 2 == 0 then
    x1 = x1 + font:getWidth("A")
    x2 = x2 + font:getWidth("A")
  end
  return x1, y1, x2, y2
end

---@param index number
local function selectItem(index)
  selectedIndex = index
  local x1, y1, x2, y2 = getItemExtents(index)
  polygonTargetPoints[1], polygonTargetPoints[2] = x1, y1
  polygonTargetPoints[3], polygonTargetPoints[4] = x2, y1
  polygonTargetPoints[5], polygonTargetPoints[6] = x2, y2
  polygonTargetPoints[7], polygonTargetPoints[8] = x1, y2
end

local function drawSelectionPolygon()
  lg.polygon("fill", selectionPolygon)
end

local noiseVertexAmount = 5

---@param x number
---@param y number
---@param t number
local function noisePoint(x, y, t)
  return
      x + (love.math.noise(t) - 0.5) * 2 * noiseVertexAmount,
      y + (love.math.noise(t + 100) - 0.5) * 2 * noiseVertexAmount
end

local offsetX, offsetY = 50, 50

local currentTween

selectItem(1)

function love.keypressed(key)
  local newIndex = selectedIndex
  if key == "down" then
    newIndex = selectedIndex + 1
    if newIndex > #options then
      newIndex = 1
    end
  elseif key == "up" then
    newIndex = selectedIndex - 1
    if newIndex < 1 then
      newIndex = #options
    end
  end
  if newIndex > selectedIndex then
    if currentTween then
      currentTween:stop()
    end
    local x1, y1, x2, y2 = getItemExtents(newIndex)
    polygonTargetPoints[5], polygonTargetPoints[6] = x2, y2
    polygonTargetPoints[7], polygonTargetPoints[8] = x1, y2
    currentTween = flux.to(polygonTargetPoints, 0.2, {
      [1] = x1,
      [2] = y1,
      [3] = x2,
      [4] = y1
    }):ease("quadout")
  elseif newIndex < selectedIndex then
    if currentTween then
      currentTween:stop()
    end
    local x1, y1, x2, y2 = getItemExtents(newIndex)
    polygonTargetPoints[1], polygonTargetPoints[2] = x1, y1
    polygonTargetPoints[3], polygonTargetPoints[4] = x2, y1
    currentTween = flux.to(polygonTargetPoints, 0.2, {
      [5] = x2,
      [6] = y2,
      [7] = x1,
      [8] = y2
    }):ease("quadout")
  end
  selectedIndex = newIndex
end

function love.update(dt)
  flux.update(dt)

  for i = 1, #polygonTargetPoints, 2 do
    selectionPolygon[i], selectionPolygon[i + 1] = noisePoint(
      polygonTargetPoints[i],
      polygonTargetPoints[i + 1],
      love.timer.getTime() * 0.4 + i * 5)
  end
end

function love.draw()
  lg.setCanvas(itemsCanvas)
  lg.clear(0, 0, 0, 1)
  lg.push()
  lg.translate(offsetX, offsetY)
  for i, text in ipairs(options) do
    local x, y = getItemExtents(i)
    lg.setFont(font)
    lg.print(text, x, y)
  end
  lg.pop()
  lg.setCanvas()

  lg.setColor(1, 1, 1)
  lg.draw(itemsCanvas)

  lg.push()
  lg.translate(offsetX, offsetY)
  lg.stencil(drawSelectionPolygon)
  lg.pop()
  lg.setStencilTest("equal", 1)
  lg.setShader(invertShader)
  lg.draw(itemsCanvas)
  lg.setStencilTest()
  lg.setShader()

  lg.push()
  lg.translate(offsetX, offsetY)
  lg.setColor(1, 1, 1)
  lg.setLineWidth(1)
  lg.polygon("line", selectionPolygon)
  lg.pop()
end
