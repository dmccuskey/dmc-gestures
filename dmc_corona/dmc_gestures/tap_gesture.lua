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

local Gesture = require 'dmc_gestures.core.gesture'



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
	if params.offset==nil then params.offset=TapGesture.MAX_DISTANCE_OFFSET end
	if params.taps==nil then params.taps=1 end
	if params.time==nil then params.time=TapGesture.MAX_TIME_INTERVAL end
	if params.touches==nil then params.touches=1 end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._max_offset = params.offset
	self._req_taps = params.taps
	self._max_time = params.time
	self._req_touches = params.touches

	self._tap_count = 0 -- how many we've seen
	self._tap_timer = nil

	self._fail_timer = nil

end


function TapGesture:__initComplete__()
	-- print( "TapGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.offset = self._max_offset
	self.taps = self._req_taps
	self.time = self._max_time
	self.touches = self._req_touches
end

--[[
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


function TapGesture.__getters:offset()
	return self._max_offset
end
function TapGesture.__setters:offset( value )
	assert( type(value)=='number' and value>0 )
	--==--
	self._max_offset = value
end


function TapGesture.__getters:taps()
	return self._req_taps
end
function TapGesture.__setters:taps( value )
	assert( type(value)=='number' and ( value>0 and value<6 ) )
	--==--
	self._req_taps = value
end


function TapGesture.__getters:time()
	return self._max_time
end
function TapGesture.__setters:time( value )
	assert( type(value)=='number' and value>10 )
	--==--
	self._max_time = value
end


function TapGesture.__getters:touches()
	return self._req_touches
end
function TapGesture.__setters:touches( value )
	assert( type(value)=='number' and ( value>0 and value<5 ) )
	--==--
	self._req_touches = value
end



--====================================================================--
--== Private Methods


function TapGesture:_do_reset()
	-- print( "TapGesture:_do_reset" )
	Gesture._do_reset( self )
	self._tap_count=0
	self:_stopAllTimers()
end


function TapGesture:_stopFailTimer()
	-- print( "TapGesture:_stopFailTimer" )
	if not self._fail_timer then return end
	timer.cancel( self._fail_timer )
	self._fail_timer=nil
end

function TapGesture:_startFailTimer()
	-- print( "TapGesture:_startFailTimer", self )
	self:_stopFailTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( TapGesture.STATE_FAILED )
			self._fail_timer = nil
		end)
	end
	self._fail_timer = timer.performWithDelay( time, func )
end



function TapGesture:_stopTapTimer()
	-- print( "TapGesture:_stopTapTimer" )
	if not self._tap_timer then return end
	timer.cancel( self._tap_timer )
	self._tap_timer=nil
end

function TapGesture:_startTapTimer()
	-- print( "TapGesture:_startTapTimer", self )
	self:_stopFailTimer()
	self:_stopTapTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( TapGesture.STATE_FAILED )
			self._tap_timer = nil
		end)
	end
	self._tap_timer = timer.performWithDelay( time, func )
end


function TapGesture:_stopAllTimers()
	self:_stopFailTimer()
	self:_stopTapTimer()
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function TapGesture:touch( event )
	-- print("TapGesture:touch", event.phase, self )
	Gesture.touch( self, event )

	local phase = event.phase
	local touch_count = self._touch_count

	if phase=='began' then
		self:_startFailTimer()
		local r_touches = self._req_touches
		if touch_count==r_touches then
			self:_startTapTimer()
		elseif touch_count>r_touches then
			self:gotoState( TapGesture.STATE_FAILED )
		end

	elseif phase=='moved' then
		local _mabs = mabs
		local offset = self._max_offset
		if _mabs(event.xStart-event.x)>offset or _mabs(event.yStart-event.y)>offset then
			self:gotoState( TapGesture.STATE_FAILED )
		end

	elseif phase=='canceled' then
		self:gotoState( TapGesture.STATE_FAILED )

	else -- ended
		local r_taps = self._req_taps
		local taps = self._tap_count
		if self._tap_timer and touch_count==0 then
			taps = taps + 1
			self:_stopTapTimer()
		end
		if taps==r_taps then
			self:gotoState( TapGesture.STATE_RECOGNIZED )
		elseif taps>r_taps then
			self:gotoState( TapGesture.STATE_FAILED )
		else
			self:_startFailTimer()
		end
		self._tap_count = taps
	end

end



--====================================================================--
--== State Machine


--== State Recognized ==--

function TapGesture:do_state_recognized( params )
	-- print( "TapGesture:do_state_recognized" )
	self:_stopAllTimers()
	Gesture.do_state_recognized( self, params )
end


--== State Failed ==--

function TapGesture:do_state_failed( params )
	-- print( "TapGesture:do_state_failed" )
	self:_stopAllTimers()
	Gesture.do_state_failed( self, params )
end




return TapGesture

