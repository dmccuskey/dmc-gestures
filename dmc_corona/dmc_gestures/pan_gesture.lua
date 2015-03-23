--====================================================================--
-- dmc_corona/dmc_gesture/pan_gesture.lua
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
--== DMC Corona Library : Pan Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Pan Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local Continuous = require 'dmc_gestures.core.continuous_gesture'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local mabs = math.abs



--====================================================================--
--== Pan Gesture Class
--====================================================================--


local PanGesture = newClass( Continuous, { name="Pan Gesture" } )

--== Class Constants

PanGesture.TYPE = 'pan'

PanGesture.MAX_DISTANCE_OFFSET = 10


--======================================================--
-- Start: Setup DMC Objects

function PanGesture:__init__( params )
	-- print( "PanGesture:__init__", params )
	params = params or {}
	if params.touches==nil then params.touches=1 end
	if params.max_touches==nil then params.max_touches=params.touches end
	if params.offset==nil then params.offset=PanGesture.MAX_DISTANCE_OFFSET end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._offset = params.offset

	self._max_touches = params.max_touches
	self._min_touches = params.touches
	self._max_time = 500

	self._velocity = 0
	self._touch_count = 0

end

function PanGesture:__initComplete__()
	-- print( "PanGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.max_touches = self._max_touches
	self.min_touches = self._min_touches
	self.offset = self._offset
end

--[[
function PanGesture:__undoInitComplete__()
	-- print( "PanGesture:__undoInitComplete__" )
	--==--
	self:superCall( '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function PanGesture.__getters:velocity()
	return self._velocity
end

function PanGesture.__getters:offset()
	return self._offset
end
function PanGesture.__setters:offset( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._offset = value
end

function PanGesture.__getters:max_touches()
	return self._max_touches
end
function PanGesture.__setters:max_touches( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._max_touches = value
end

function PanGesture.__getters:touches()
	return self._min_touches
end
function PanGesture.__setters:touches( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._min_touches = value
end




--====================================================================--
--== Private Methods


function PanGesture:_do_reset()
	-- print( "PanGesture:_do_reset" )
	Continuous._do_reset( self )
	self._velocity=0
	self._touch_count=0
end


-- create data structure for Gesture which has been recognized
-- code will put in began/changed/ended
function PanGesture:_createGestureEvent( event )
	local evt = {
		x=x
	}
	return {
		x=event.x,
		y=event.y,
		xStart=event.xStart,
		yStart=event.yStart,
	}
end



function PanGesture:_stopFailTimer()
	-- print( "PanGesture:_stopFailTimer" )
	if not self._fail_timer then return end
	timer.cancel( self._fail_timer )
	self._fail_timer=nil
end

function PanGesture:_startFailTimer()
	-- print( "PanGesture:_startFailTimer", self )
	self:_stopFailTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( PanGesture.STATE_FAILED )
			self._fail_timer = nil
		end)
	end
	self._fail_timer = timer.performWithDelay( time, func )
end




function PanGesture:_stopPanTimer()
	-- print( "PanGesture:_stopPanTimer" )
	if not self._pan_timer then return end
	timer.cancel( self._pan_timer )
	self._pan_timer=nil
end

function PanGesture:_startPanTimer()
	-- print( "PanGesture:_startPanTimer", self )
	self:_stopFailTimer()
	self:_stopPanTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( PanGesture.STATE_FAILED )
			self._pan_timer = nil
		end)
	end
	self._pan_timer = timer.performWithDelay( time, func )
end


--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function PanGesture:touch( event )
	-- print("PanGesture:touch", event.phase, event.id, self )
	Continuous.touch( self, event )

	local _mabs = mabs
	local phase = event.phase
	local offset = self._offset
	local state = self:getState()
	local t_max = self._max_touches
	local t_min = self._min_touches
	local touch_count = self._touch_count
	local data

	local is_touch_ok = ( touch_count>=t_min and touch_count<=t_max )

	if phase=='began' then
		self:_startFailTimer()
		if is_touch_ok then
			self:_startPanTimer()
		elseif touch_count>t_max then
			self:gotoState( PanGesture.STATE_FAILED )
		end

	elseif phase=='moved' then
		self:_stopPanTimer()

		if state==Continuous.STATE_POSSIBLE then
			if is_touch_ok and (_mabs(event.xStart-event.x)>offset or _mabs(event.yStart-event.y)>offset) then
				self:gotoState( Continuous.STATE_BEGAN, event )
			end
		elseif state==Continuous.STATE_BEGAN then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end
		elseif state==Continuous.STATE_CHANGED then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end
		end

	elseif phase=='canceled' then
		self:gotoState( PanGesture.STATE_FAILED  )

	else -- ended
		if is_touch_ok then
			self:gotoState( Continuous.STATE_CHANGED, event )
		else
			if state==Continuous.STATE_BEGAN or state==Continuous.STATE_CHANGED then
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			else
				self:gotoState( Continuous.STATE_FAILED )
			end
		end

	end

end



--====================================================================--
--== State Machine

-- none



return PanGesture
