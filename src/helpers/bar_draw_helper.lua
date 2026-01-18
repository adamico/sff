local lg = love.graphics

local BarDrawHelper = {}

function BarDrawHelper.draw(options)
   local position = options.position or Vector()
   local width = options.width
   local height = options.height
   local offsetY = options.offsetY
   local current = options.current
   local max = options.max
   local backgroundColor = options.backgroundColor
   local fillColor = options.fillColor
   local border = options.border

   -- Calculate bar position (centered above entity)
   local barX = math.ceil(position.x) - width / 2
   local barY = math.ceil(position.y) - height - offsetY

   -- Calculate fill width based on health ratio
   local healthRatio = math.max(0, math.min(1, current / max))
   local fillWidth = width * healthRatio

   -- Store previous graphics state
   local pr, pg, pb, pa = lg.getColor()
   local prevLineWidth = lg.getLineWidth()

   -- Draw background (empty health - red)
   lg.setColor(backgroundColor)
   lg.rectangle("fill", barX, barY, width, height)

   -- Draw fill (current health - green)
   if fillWidth > 0 then
      lg.setColor(fillColor)
      lg.rectangle("fill", barX, barY, fillWidth, height)
   end

   -- Draw border
   if border then
      lg.setColor(border.color)
      lg.setLineWidth(border.width)
      lg.rectangle(
         "line",
         barX - border.gap,
         barY - border.gap,
         width + border.gap * 2,
         height + border.gap * 2
      )
   end

   -- Restore previous graphics state
   lg.setLineWidth(prevLineWidth)
   lg.setColor(pr, pg, pb, pa)
end

return BarDrawHelper
