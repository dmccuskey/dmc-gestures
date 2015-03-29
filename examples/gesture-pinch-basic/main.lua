--====================================================================--
-- Gesture Pinch Basic
--
-- Shows simple use of Pinch Gesture
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2015 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local Gesture = require 'dmc_corona.dmc_gestures'


--====================================================================--
--== Setup, Constants


local W, H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5


local txt_display, txt_display_t, timer_t
local circle, showCircle = nil, true
local view, xScale, yScale



--====================================================================--
--== Support Functions


local function doDisplayEffect()
	if timer_t ~= nil then timer.cancel( timer_t ) end
	if txt_display_t ~= nil then transition.cancel( txt_display_t ) end

	timer_t = timer.performWithDelay( 250, function()
		timer_t = nil
		txt_display_t = transition.to( txt_display, {
			time=1000, alpha=0,
			onComplete=function() txt_display_t = nil end
		})
	end)
end

local function displayFeedback( str )
	txt_display.alpha=1
	txt_display.alpha=1
	txt_display:setTextColor( 0.8,0,0 )
	txt_display.text = str
	doDisplayEffect()
end

local function setupUI()
	local o = display.newText( "", 0, 0, native.systemFont, 30 )
	o.anchorX, o.anchorY = 0.5, 0
	o.x, o.y = H_CENTER, 50
	txt_display = o
end



--====================================================================--
--== Main
--====================================================================--


local function main()

	local pinch


	local function gestureEvent_handler( event )
		-- print( "gestureEvent_handler", event.phase )
		if event.type == event.target.GESTURE then
			local eS = event.scale

			if event.phase=='began' then
				-- store current scale for this gesture event
				xScale, yScale = view.xScale, view.yScale
				view.xScale, view.yScale = xScale*eS, yScale*eS

				if showCircle then
					circle = display.newCircle( event.x, event.y, 10 )
				end

			elseif event.phase=='changed' then
				view.xScale, view.yScale = xScale*eS, yScale*eS

				if showCircle then
					circle.x, circle.y = event.x, event.y
				end

			else
				view.xScale, view.yScale = xScale*eS, yScale*eS

				if showCircle then
					if circle then circle:removeSelf() ; circle=nil end
				end

			end
			displayFeedback( "Gesture: "..tostring(event.id)..tostring(event.scale) )
		end
	end


	-- create touch area for gestures

	view = display.newRect( H_CENTER, V_CENTER+40, V_CENTER, V_CENTER )
	view:setFillColor( 0.3,0.3,0.3 )

	-- create a pinch gestures, link to touch area

	pinch = Gesture.newPinchGesture( view, { id="pinch" } )
	pinch:addEventListener( pinch.EVENT, gestureEvent_handler )

end


-- start the action !

setupUI()
main()

