--====================================================================--
-- Gesture Multi Simultaneous
--
-- Shows allowing multiple gestures to work together
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

local txt_display, txt_display_t

io.output():setvbuf('no')


--====================================================================--
--== Support Functions


--======================================================--
--== UI for feedback, etc

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


--======================================================--
--== Delegate Methods

-- @param recog is the gesture recognizer which has just been Recognized
-- @param fail is the gesture recognizer which is about to be Failed
-- @return boolean, true to allow synchronous recognition
--
local function shouldRecognizeSimultaneously( self, recog, fail )
	-- print( "shouldRecognizeSimultaneously", recog._id, fail._id )
	return true
end



--====================================================================--
--== Main
--====================================================================--


local function main()

	local view, pan, pinch
	local delegate

	local function gestureEvent_handler( event )
		-- print( "gestureEvent_handler", event.type, event.phase )
		if event.type == event.target.GESTURE then

			if event.phase=='began' then

			elseif event.phase=='changed' then

			else

			end
			displayFeedback( "Gesture: "..tostring(event.id) )
		end
	end

	delegate = {
		shouldRecognizeWith=shouldRecognizeSimultaneously
	}

	-- create touch area for gestures

	view = display.newRect( H_CENTER, V_CENTER+40, V_CENTER, V_CENTER )
	view:setFillColor( 0.3,0.3,0.3 )

	-- create some gestures, link to touch area

	-- pan gesture, 1 touch

	pan = Gesture.newPanGesture( view, { touches=1, id='1 pan' } )
	pan.delegate=delegate
	pan:addEventListener( pan.EVENT, gestureEvent_handler )

	-- pan gesture, 2 touch

	pan = Gesture.newPanGesture( view, { touches=2, id='2 pan' } )
	pan.delegate=delegate
	pan:addEventListener( pan.EVENT, gestureEvent_handler )

	-- pinch gesture, 2 touch

	pinch = Gesture.newPinchGesture( view, { id='pinch', delegate=delegate } )
	pinch:addEventListener( pinch.EVENT, gestureEvent_handler )

end


-- start the action !

setupUI()
main()

