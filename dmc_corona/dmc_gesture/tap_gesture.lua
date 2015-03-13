--====================================================================--
-- dmc_corona/dmc_gesture/tap_gesture.lua
--
-- Documentation:
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : Tap Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Tap Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local Gesture = require 'dmc_gesture.core.gesture'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local mabs = math.abs



--====================================================================--
--== Tap Gesture Class
--====================================================================--


local TapGesture = newClass( Gesture, { name="Tap Gesture" } )

--== Class Constants

TapGesture.TYPE = 'tap'

TapGesture.MAX_TIME_INTERVAL = 300
TapGesture.MAX_DISTANCE_OFFSET = 10


--======================================================--
-- Start: Setup DMC Objects

function TapGesture:__init__( params )
	-- print( "TapGesture:__init__", params )
	params = params or {}
	if params.taps==nil then params.taps=1 end
	if params.touches==nil then params.touches=1 end
	if params.time==nil then params.time=TapGesture.MAX_TIME_INTERVAL end
	if params.offset==nil then params.offset=TapGesture.MAX_DISTANCE_OFFSET end

	self:superCall( '__init__', params )
	--==--

	--== Sanity Check ==--

	assert( type(params.time)=='number' and params.time>10 )
	assert( type(params.offset)=='number' and params.time>=0 )

	assert( type(params.taps)=='number' )
	assert( params.taps>0 and params.taps<5 )

	assert( type(params.touches)=='number' )
	assert( params.touches>0 and params.touches<5 )

	--== Create Properties ==--

	self._max_time = params.time
	self._max_offset = params.offset

	self._req_taps = params.taps
	self._req_touches = params.touches

	self._taps = 0 -- how many we've seen
	self._tap_timer = nil
	self._touches = 0 -- active touches
	self._touch_timer = nil

end


--[[
function TapGesture:__initComplete__()
	-- print( "TapGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
end

function TapGesture:__undoInitComplete__()
	-- print( "TapGesture:__undoInitComplete__" )
	--==--
	self:superCall( '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- none



--====================================================================--
--== Private Methods


function TapGesture:_do_reset()
	-- print( "TapGesture:_do_reset" )
	self._tap_count=0
	self._touch_count=0
	self:_stopAllTimers()
end


function TapGesture:_stopTapTimer()
	-- print( "TapGesture:_stopTapTimer" )
	if not self._tap_timer then return end
	timer.cancel( self._tap_timer )
	self._tap_timer=nil
end

function TapGesture:_startTapTimer()
	-- print( "TapGesture:_startTapTimer" )
	self:_stopTapTimer()
	local TIME = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( TapGesture.STATE_FAILED )
			self._tap_timer = nil
		end)
	end
	self._tap_timer = timer.performWithDelay( TIME, func )
end


function TapGesture:_stopTouchTimer()
	-- print( "TapGesture:_stopTouchTimer" )
	self._touch_timer=0
end

function TapGesture:_startTouchTimer()
	-- print( "TapGesture:_startTouchTimer" )
	self:_stopTouchTimer()
	self._touch_timer=0
end


function TapGesture:_stopAllTimers()
	self:_stopTapTimer()
	self:_stopTouchTimer()
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function TapGesture:touch( event )
	-- print("TapGesture:touch", event.phase )
	local _mabs = mabs
	local phase = event.phase
	local offset = self._max_offset
	local r_taps = self._req_taps
	local r_taps = self._req_taps
	local taps = self._tap_count
	local r_touches = self._req_touches
	local touches = self._touch_count

	if phase=='began' then
		touches = touches + 1
		self:_startTapTimer()

	elseif phase=='moved' then
		if _mabs(event.xStart-event.x)>offset or _mabs(event.yStart-event.y)>offset then
			self:gotoState( TapGesture.STATE_FAILED )
		end

	elseif phase=='canceled' then
		self:gotoState( TapGesture.STATE_FAILED )

	else -- ended
		taps = taps + 1
		self._tap_count = taps

		if taps==r_taps and touches==r_touches then
			self:gotoState( TapGesture.STATE_RECOGNIZED )
		elseif taps>r_taps or touches>r_touches then
			self:gotoState( TapGesture.STATE_FAILED )
		end

		touches = touches - 1
	end

	self._touch_count = touches
end



--====================================================================--
--== State Machine


--== State Recognized ==--

function TapGesture:do_state_recognized( params )
	-- print( "TapGesture:do_state_recognized" )
	self:_stopAllTimers()
	Gesture.do_state_recognized( self, params )
	self:_dispatchRecognizedEvent()
end


--== State Failed ==--

function TapGesture:do_state_failed( params )
	-- print( "TapGesture:do_state_failed" )
	self:_stopAllTimers()
	Gesture.do_state_failed( self, params )
end




return TapGesture

