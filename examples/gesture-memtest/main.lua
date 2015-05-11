--====================================================================--
-- Gesture Tap Basic
--
-- Shows simple use of Tap Gesture
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2015 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local Gesture = require 'dmc_corona.dmc_gestures'

local Perf = require 'dmc_corona.dmc_performance'



--====================================================================--
--== Setup, Constants

math.randomseed( os.time() )

local W, H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5

local tdelay = timer.performWithDelay
local mrandom = math.random

local txt_display, txt_display_t
local timer_t
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



local function createRandomGesture( view )
	local gestures = {
		Gesture.newLongPressGesture,
		Gesture.newPanGesture,
		Gesture.newPinchGesture,
		Gesture.newTapGesture,
	}
	local g = gestures[ mrandom( #gestures ) ]
	return g( view )
end


local function gestureEvent_handler( event ) end



--====================================================================--
--== Main
--====================================================================--


setupUI()



--======================================================--
--== stress test ScrollView Style

function run_example1()

	local createItem, destroyItem
	local DELAY = 50
	local count = 0
	local view, o

	createItem = function()
		count=count+1

		view = display.newRect( H_CENTER, V_CENTER+40, V_CENTER, V_CENTER )
		view:setFillColor( 0.3,0.3,0.3 )

		-- o = Gesture.newTapGesture( view, { id="1 tch 1 tap" }  )
		o = createRandomGesture( view )
		o:addEventListener( o.EVENT, gestureEvent_handler )

		tdelay( DELAY, function()
			destroyItem()
		end)
	end

	destroyItem = function()
		o:removeEventListener( o.EVENT, gestureEvent_handler )
		o:removeSelf()
		o=nil

		view:removeSelf()
		view=nil
		if count%10==0 then
			print( "cycles completed: ", count )
		end
		tdelay( DELAY, function()
			createItem()
		end)
	end

	print( "Main: Starting" )
	createItem()
	Perf.watchMemory( 2500 )

end

-- run_example1()

