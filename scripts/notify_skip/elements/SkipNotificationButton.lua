local Element = require('elements/Element')

---@class SkipNotificationButton : Element
local SkipNotificationButton = class(Element)

function SkipNotificationButton:new() return Class.new(self) --[[@as SkipNotificationButton]] end

function SkipNotificationButton:init()
	Element.init(self, 'skip_notification_button', {render_order = 7})
	self.ignores_curtain = true
	self.message = ""
	self.is_prompt = false
	self.min_visibility = 0 -- Start hidden
	self:update_dimensions()
end

function SkipNotificationButton:update_dimensions()
	if not display.initialized then return end

	-- Calculate scale factor based on display height relative to 1080p
	local base_height = 1080
	local scale = display.height / base_height

	-- Netflix-style positioning: bottom right area, moved higher
	local margin = 80 * scale
	local button_width = 200 * scale
	local button_height = 60 * scale

	-- Position higher up (reduce bottom margin)
	self:set_coordinates(
		display.width - button_width - margin,  -- Right side
		display.height - button_height - margin - (80 * scale), -- Higher up
		display.width - margin,
		display.height - margin - (80 * scale)
	)

	-- Store scale for use in render
	self.scale = scale
end

function SkipNotificationButton:set_message(message, is_prompt)
	self.message = message or ""
	self.is_prompt = is_prompt or false
	self.min_visibility = 1 -- Make visible immediately
	self:update_dimensions()
	request_render()
end

function SkipNotificationButton:render()
	local visibility = self:get_visibility()
	if visibility <= 0 or self.message == "" then return end

	local ass = assdraw.ass_new()

	-- Netflix-style button: white background with black text (no hover effects)
	local bg_color = 'FFFFFF'  -- White background
	local text_color = '000000'  -- Black text

	-- Background with rounded corners (Netflix style)
	ass:rect(self.ax, self.ay, self.bx, self.by, {
		color = bg_color,
		opacity = visibility * 0.65,
		border = 2 * self.scale,
		border_color = 'FFFFFF',
		radius = 13 * self.scale,
	})

	-- Text using original ASS font settings (fs24, b900)
	local font_size = 24 * self.scale
	local x = round((self.ax + self.bx) / 2)
	local y = round((self.ay + self.by) / 2)

	-- Main text (centered)
	ass:txt(x, y, 5, self.message, {
		size = font_size,
		color = text_color,
		opacity = visibility,
		bold = true,
		shadow_x = 1 * self.scale,
		shadow_y = 1 * self.scale,
		shadow_color = '000000',
	})

	-- "(Tab)" text below (smaller, dimmer, centered)
	if self.is_prompt then
		local tab_font_size = font_size * 0.6  -- 60% of main font size
		local tab_y = y + (font_size * 0.8)     -- Position below main text
		local tab_opacity = visibility * 0.3   -- 30% opacity (dimmer)
		
		ass:txt(x, tab_y, 5, "(Press Tab)", {
			size = tab_font_size,
			color = text_color,
			opacity = tab_opacity,
			bold = false,
			shadow_x = 1 * self.scale,
			shadow_y = 1 * self.scale,
			shadow_color = '000000',
		})
	end

	return ass
end

function SkipNotificationButton:on_display()
	self:update_dimensions()
end

function SkipNotificationButton:hide()
	self.message = ""
	self.min_visibility = 0 -- Hide the button
	request_render()
end

return SkipNotificationButton