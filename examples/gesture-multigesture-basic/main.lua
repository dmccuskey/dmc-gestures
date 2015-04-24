--====================================================================--
-- Gesture Multi Basic
--
-- Shows stacking different gestures
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
local circle



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

	local view, pan, tap


	local function gestureEvent_handler( event )
		-- print( "gestureEvent_handler", event.target.id, event.phase )
		if event.type == event.target.GESTURE then
			if event.phase=='began' then
				circle = display.newCircle( event.x, event.y, 10 )
			elseif event.phase=='changed' then
				circle.x, circle.y = event.x, event.y
			else
				if circle then circle:removeSelf() ; circle=nil end
			end
			displayFeedback( "Gesture: "..tostring(event.id) )
		end
	end

	-- create touch area for gestures

	view = display.newRect( H_CENTER, V_CENTER+40, V_CENTER, V_CENTER )
	view:setFillColor( 0.3,0.3,0.3 )

	-- create some gestures, link to touch area

	-- pan gestures

	pan = Gesture.newPanGesture( view, { touches=1, id="1 pan" } )
	pan:addEventListener( pan.EVENT, gestureEvent_handler  )

	pan = Gesture.newPanGesture( view, { touches=2, id="2 pan" } )
	pan:addEventListener( pan.EVENT, gestureEvent_handler )

	pan = Gesture.newPanGesture( view, { touches=3, id="3 pan" } )
	pan:addEventListener( pan.EVENT, gestureEvent_handler )

	-- tap gestures

	tap = Gesture.newTapGesture( view, { id="1 tch 1 tap" }  )
	tap:addEventListener( tap.EVENT, gestureEvent_handler )

	tap = Gesture.newTapGesture( view, { touches=2, taps=2, id="2 tch 2 tap" } )
	tap:addEventListener( tap.EVENT, gestureEvent_handler )

	tap = Gesture.newTapGesture( view, { touches=3, taps=1, id="3 tch 1 tap" } )
	tap:addEventListener( tap.EVENT, gestureEvent_handler )

end


-- start the action !

setupUI()
main()

