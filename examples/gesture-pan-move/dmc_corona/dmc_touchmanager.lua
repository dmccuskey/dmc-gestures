--===================================================================--
-- dmc_corona/dmc_touchmanager.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/
--===================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2013-2015 David McCuskey

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
--== DMC Corona Library : Touch Manager
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Touch Manager
--====================================================================--


--[[
Overview of Data Objects

Touch Object (t_obj)
a Corona object which can get touch events

Gesture Manager (g_mgr)
An object which coordinates one or many Gesture Receivers

--]]



--====================================================================--
--== Configuration


dmc_lib_data.dmc_touchmanager = dmc_lib_data.dmc_touchmanager or {}

local DMC_TOUCHMANAGER_DEFAULTS = {
	default_color_format='dRGBA',
	-- named_color_file, no default,
}

local dmc_touchmanager_data = Utils.extend( dmc_lib_data.dmc_touchmanager, DMC_TOUCHMANAGER_DEFAULTS )



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


system.activate( 'multitouch' )

local tinsert = table.insert
local tremove = table.remove



--====================================================================--
--== Support Functions


local function sendEventToListeners( event, listeners )
	for _, reg in pairs( listeners ) do
		-- print( "listener registration", _, reg )
		if reg.func then
			reg.func( event )
		else
			reg.obj:touch( event )
		end
	end
end


-- createMasterTouchHandler()
-- creates touch handler for objects
-- @param master_data reference to the Touch Manager data object
--
local function createMasterTouchHandler( master_data )

	return function( event )
		-- print( "in touch handler", event.target )
		local target = event.target
		local phase = event.phase
		local response = false

		--== Get data structure for Touch Object

		local t_obj = master_data.focus[ event.id ]
		if t_obj then
			event.target = t_obj
			event.isFocused = true
		else
			t_obj = target
			event.isFocused = false
		end

		if not t_obj then return false end

		local struct = master_data[ t_obj ]

		if not struct then return false end

		--== Data refs from Touch Structure

		local g_mgr = struct.g_mgr
		local listeners = struct.listener

		--== Gesture Manager processes Event first

		if g_mgr then
			g_mgr:touch( event )
			response = true -- for Corona
		end

		--== Send event to other listeners

		if phase=='began' then

			if g_mgr.shouldDelayBeganTouches then
				-- pass, TODO
			else
				sendEventToListeners( event, listeners )
			end

		elseif phase=='moved' then

			if g_mgr.shouldDelayBeganTouches then
				-- pass, TODO
			else
				sendEventToListeners( event, listeners )
			end


		elseif phase=='ended' or phase=='cancelled' then

			if g_mgr.shouldDelayEndedTouches then
				-- pass, TODO
			else
				sendEventToListeners( event, listeners )
			end
		end

		return response
	end -- handler func

end


local function initialize( manager )
	-- print( "TouchMgr.initialize", manager )

	local DATA = manager._DATA
	DATA.object = manager._OBJECT
	DATA.focus = manager._FOCUS

	local handler = createMasterTouchHandler( manager._DATA )
	manager._HANDLER = handler

	-- Touch Manager listens to Global (Runtime) touch events
	--
	Runtime:addEventListener( 'touch', handler )

end


local function createTouchStructure()
	return {
		--[[
		Gesture Manager assigned to this Touch Object
		--]]
		g_mgr = nil,

		--[[
		Listener
		an object interested in Touch Events
		keyed on obj (t_obj)
		stores has with handler, either obj or func (not both)
		<t_obj> = {
			obj=<listener or nil>,
			handler=<func or nil>
		}
		--]]
		listener = {},

		--[[
		these store delayed Touch Events, if g_mgr says to delay
		--]]
		t_began = {},
		t_moved = {},
		t_ended = {}
	}

end



--====================================================================--
--== Touch Manager Object
--====================================================================--


local TouchMgr = {}

--== Constants ==--

-- value is Master Touch Event handler
TouchMgr._HANDLER = nil

--[[
Objects
Focus
--]]
TouchMgr._OBJECT = {}
TouchMgr._FOCUS = {}
TouchMgr._DATA = {}



--====================================================================--
--== Public Functions


--======================================================--
-- Gesture Manager

-- registerGestureMgr()
--
-- stores Gesture Manager which handles Touch Events
-- for a particular Touch Object
--
-- @param g_mgr a Gesture Manager
--
function TouchMgr.registerGestureMgr( g_mgr )
	TouchMgr._setRegisteredManager( g_mgr )
end

-- unregisterGestureMgr()
--
-- removes Gesture Manager which handles Touch Events
-- for a particular Touch Object
--
-- @param g_mgr a Gesture Manager
--
function TouchMgr.unregisterGestureMgr( g_mgr )
	local r = TouchMgr._getRegisteredObject( g_mgr )
		if r then
			TouchMgr._setRegisteredObject( obj, nil )
			obj:removeEventListener( 'touch', r.callback )
		end
end



--======================================================--
-- Client Handler

-- register()
--
-- puts touch manager in control of touch events for this object
--
-- @param obj a Corona-type object
-- @param handler the function handler for the touch event (optional)
--
function TouchMgr.register( t_obj, handler )
	if not TouchMgr._getRegisteredObject( t_obj ) then
		local reg = {}
		if type(handler)=='function' then
			reg.func = handler
		else
			reg.obj = handler
		end
		TouchMgr._setRegisteredObject( t_obj, reg )
	end
end

-- unregister()
--
-- removes touch manager control for touch events for this object
--
-- @param obj a Corona-type object
-- @param handler the function handler for the touch event (optional)
--
function TouchMgr.unregister( obj, handler )
	local r = self:_getRegisteredObject( obj )
		if r then
			TouchMgr._setRegisteredObject( obj, nil )
			obj:removeEventListener( 'touch', r.callback )
		end
end


-- setFocus()
--
-- sets focus on an object for a single touch event
--
-- @param t_obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchMgr.setFocus( t_obj, event_id )
	-- print( "TouchMgr.setFocus", t_obj )
	TouchMgr._setRegisteredTouch( event_id, t_obj )
end

-- unsetFocus()
--
-- removes focus on an object for a single touch event
--
-- @param obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchMgr.unsetFocus( t_obj, event_id )
	TouchMgr._setRegisteredTouch( event_id, nil )
end



--====================================================================--
--== Private Functions


function TouchMgr._getTouchStructure( t_obj )
	return TouchMgr._DATA[ t_obj ]
end

function TouchMgr._addTouchStructure( t_obj )
	local struct = TouchMgr._getTouchStructure( t_obj )
	if not struct then
		struct = createTouchStructure()
		TouchMgr._DATA[ t_obj ] = struct
		t_obj:addEventListener( 'touch', TouchMgr._HANDLER )
	end
	return struct
end


function TouchMgr._getRegisteredManager( t_obj )
	assert( t_obj )
	local struct = TouchMgr._getTouchStructure( t_obj )
	return struct.g_mgr
end

function TouchMgr._setRegisteredManager( g_mgr )
	assert( g_mgr and g_mgr.view )
	local struct = TouchMgr._addTouchStructure( g_mgr.view )
	assert( struct.g_mgr==nil )
	g_mgr.touch_manager = TouchMgr
	struct.g_mgr = g_mgr
end


function TouchMgr._getRegisteredObject( t_obj )
	assert( t_obj )
	return TouchMgr._OBJECT[ t_obj ]
end

function TouchMgr._setRegisteredObject( t_obj, registration )
	assert( t_obj )
	local struct = TouchMgr._addTouchStructure( t_obj )
	local listeners = struct.listener
	listeners[ t_obj ] = registration
end


function TouchMgr._getRegisteredTouch( event_id )
	assert( event_id )
	return TouchMgr._FOCUS[ event_id ]
end

function TouchMgr._setRegisteredTouch( event_id, t_obj )
	assert( event_id )
	TouchMgr._FOCUS[ event_id ] = t_obj
end




--====================================================================--
--== Event Handlers


-- none



initialize( TouchMgr )



return TouchMgr
