--====================================================================--
-- tests/dmc_gestures_spec.lua
--
-- unit tests for dmc_gestures, with a stand-in display, Runtime,
-- timer and clock; touches go through dmc_touchmanager and the
-- gesture manager, a frame at a time, as in Solar2D
-- run with tests/run_unit.sh
--====================================================================--


module( ..., package.seeall )


--====================================================================--
--== Setup

local FRAME = 16 -- ms

-- the clock and timers: time moves only in frame()

local now = 0
local timers = {}

system.getTimer = function() return now end
system.activate = function() end

_G.timer = {
	performWithDelay=function( delay, f )
		local t = { at=now+delay, f=f }
		timers[#timers+1] = t
		return t
	end,
	cancel=function( t ) t.cancelled = true end,
}

-- listeners: a function, or a table with a method named for the event

local function callListener( l, event )
	if type( l )=='function' then return l( event ) end
	return l[ event.name ]( l, event )
end

local function addListener( list, name, l )
	list[name] = list[name] or {}
	table.insert( list[name], l )
end

local function removeListener( list, name, l )
	for i, x in ipairs( list[name] or {} ) do
		if x==l then table.remove( list[name], i ) ; return end
	end
end

local function dispatch( list, event )
	local copy = {}
	for i, l in ipairs( list[event.name] or {} ) do copy[i] = l end
	local handled = false
	for _, l in ipairs( copy ) do
		if callListener( l, event ) then handled = true end
	end
	return handled
end

local runtime_listeners = {}
_G.Runtime = {
	addEventListener=function( self, name, l ) addListener( runtime_listeners, name, l ) end,
	removeEventListener=function( self, name, l ) removeListener( runtime_listeners, name, l ) end,
	dispatchEvent=function( self, event ) return dispatch( runtime_listeners, event ) end,
}

local function countRuntime( name ) return #( runtime_listeners[name] or {} ) end

-- display objects: listeners, and 'finalize' on removeSelf()

local methods = {}
local META = { __index=methods }

local function newObject( props )
	local o = setmetatable( { x=0, y=0, width=100, height=100, listeners={} }, META )
	for k, v in pairs( props or {} ) do o[k] = v end
	return o
end

function methods:addEventListener( name, l ) addListener( self.listeners, name, l ) end
function methods:removeEventListener( name, l ) removeListener( self.listeners, name, l ) end
function methods:dispatchEvent( event )
	event.target = event.target or self
	return dispatch( self.listeners, event )
end
function methods:removeSelf()
	self:dispatchEvent{ name='finalize', target=self }
	self.listeners = {}
	self.removed = true
end
function methods:contentToLocal( x, y ) return x-self.x, y-self.y end
function methods:insert() end
function methods:setFocus() end

_G.display = {
	getCurrentStage=function() return newObject() end,
	newGroup=function() return newObject() end,
	newRect=function( x, y, w, h ) return newObject{ x=x, y=y, width=w, height=h } end,
}

-- run n frames: due timers first, then 'enterFrame'
local function frame( n )
	for _ = 1, n or 1 do
		now = now + FRAME
		local due = {}
		for i = #timers, 1, -1 do
			local t = timers[i]
			if t.cancelled then table.remove( timers, i )
			elseif t.at<=now then table.remove( timers, i ) ; table.insert( due, 1, t ) end
		end
		for _, t in ipairs( due ) do t.f() end
		Runtime:dispatchEvent{ name='enterFrame', time=now }
	end
end

-- frames for ms milliseconds
local function wait( ms ) frame( math.ceil( ms/FRAME ) ) end

-- the boot and dmc_objects set their own globals; snapshot after them
pcall( function() require( 'dmc_corona_boot' ) end )
require 'dmc_objects'
require( 'dmc_patch' ).addPatch( 'print-output' ) -- pwarn, pnotice
require 'dmc_states_mix'
require 'dmc_touchmanager'
local globals = {}
for k in pairs( _G ) do globals[k] = true end

local Gesture = require 'dmc_gestures'
local TouchMgr = require 'dmc_touchmanager'

-- touches: 'began' goes to the view, the rest to Runtime,
-- which hands focused touches to their view (dmc_touchmanager)

local starts

local function touch( view, id, phase, x, y )
	if phase=='began' then starts[id] = { x=x, y=y } end
	local s = starts[id]
	local event = {
		name='touch', id=id, phase=phase, time=now,
		x=x, y=y, xStart=s.x, yStart=s.y,
	}
	if phase=='began' then
		event.target = view
		view:dispatchEvent( event )
	else
		Runtime:dispatchEvent( event )
	end
end

local views, events

local function newView()
	local v = newObject{ x=200, y=200 }
	views[#views+1] = v
	return v
end

-- record a gesture's events, as 'phase' (or the gesture type for a tap)
local function record( g, name )
	g:addEventListener( g.EVENT, function( e )
		if e.type~=g.GESTURE then return end
		events[#events+1] = { name=name or e.gesture, phase=e.phase, e=e,
			xStart=e.xStart, yStart=e.yStart, x=e.x, y=e.y, velocity=g.velocity }
	end )
end

local function phases()
	local list = {}
	for _, r in ipairs( events ) do list[#list+1] = r.name .. ':' .. tostring( r.phase ) end
	return table.concat( list, ' ' )
end

function setup()
	views, events, starts = {}, {}, {}
end

function teardown()
	for _, v in ipairs( views ) do
		if not v.removed then v:removeSelf() end
	end
	wait( 1000 )
	timers = {}
end


--====================================================================--
--== Tests

function test_loadSetsNoGlobals()
	for k in pairs( _G ) do
		assert_true( globals[k] or k=='dmc_gestures_spec', 'new global: ' .. tostring( k ) )
	end
	assert_equal( '2.1.0', Gesture.VERSION )
end

--== Continuous gestures: no 'ended' without 'began'

function test_pinchTwoFingerTapSendsNothing()
	local v = newView()
	record( Gesture.newPinchGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 200 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; frame()
	touch( v, 'B', 'ended', 200, 200 ) ; frame( 2 )
	assert_equal( '', phases() )
end

function test_pinchOneFingerLiftedBeforeBeginSendsNothing()
	local v = newView()
	record( Gesture.newPinchGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 200 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; frame()
	touch( v, 'B', 'moved', 220, 220 ) ; frame()
	touch( v, 'B', 'moved', 260, 260 ) ; frame()
	touch( v, 'B', 'ended', 260, 260 ) ; frame( 2 )
	assert_equal( '', phases() )
end

function test_pinch()
	local v = newView()
	local g = Gesture.newPinchGesture( v )
	record( g )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 200 ) ; frame()
	touch( v, 'B', 'moved', 210, 210 ) ; frame()
	touch( v, 'B', 'moved', 300, 300 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; touch( v, 'B', 'ended', 300, 300 ) ; frame( 2 )
	assert_equal( 'pinch:began pinch:changed pinch:changed pinch:ended', phases() )
	for _, r in ipairs( events ) do
		assert_equal( 150, r.xStart, r.phase ) ; assert_equal( 150, r.yStart, r.phase )
	end
	assert_equal( 200, events[4].x )
	assert_true( math.abs( events[4].e.scale-2 )<0.001, events[4].e.scale )
	assert_true( events[4].e.velocity>0, 'velocity' )
	assert_equal( events[4].e.velocity, events[4].velocity )
end

function test_pinchVelocityWithBothFingersMoving()
	local v = newView()
	record( Gesture.newPinchGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 100 ) ; frame()
	-- 20 px apart more each frame of 16 ms: the scale grows 0.2 a frame
	for k = 1, 5 do
		touch( v, 'A', 'moved', 100-10*k, 100 ) ; touch( v, 'B', 'moved', 200+10*k, 100 ) ; frame()
	end
	touch( v, 'A', 'ended', 50, 100 ) ; touch( v, 'B', 'ended', 250, 100 ) ; frame( 2 )
	assert_equal( 'pinch:ended', phases():sub( -11 ) )
	for i, r in ipairs( events ) do
		assert_true( r.e.velocity>=0 and r.e.velocity<=12.6, i .. ': ' .. r.e.velocity )
	end
	assert_true( math.abs( events[#events].e.velocity-12.5 )<0.1, events[#events].e.velocity )
end

function test_pinchThirdFingerFailsBeforeBegin()
	local v = newView()
	record( Gesture.newPinchGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 200 ) ; frame()
	touch( v, 'C', 'began', 300, 300 ) ; frame()
	touch( v, 'C', 'ended', 300, 300 ) ; frame()
	touch( v, 'B', 'moved', 400, 400 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; touch( v, 'B', 'ended', 400, 400 ) ; frame( 2 )
	assert_equal( '', phases() )
end

function test_panStartAndVelocity()
	local v = newView()
	local g = Gesture.newPanGesture( v )
	record( g )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	touch( v, 'A', 'moved', 105, 100 ) ; frame()
	touch( v, 'A', 'moved', 120, 100 ) ; frame()
	for i = 1, 6 do touch( v, 'A', 'moved', 120+i*16, 100 ) ; frame() end
	touch( v, 'A', 'ended', 216, 100 ) ; frame( 2 )
	local p = phases()
	assert_equal( 'pan:began', p:sub( 1, 9 ) )
	assert_equal( 'pan:ended', p:sub( -9 ) )
	for _, r in ipairs( events ) do
		assert_equal( 100, r.xStart, r.phase ) ; assert_equal( 100, r.yStart, r.phase )
	end
	-- 16 px a frame of 16 ms
	local e = events[#events].e
	assert_true( math.abs( e.xVelocity-1000 )<1, e.xVelocity )
	assert_equal( 0, e.yVelocity )
	assert_equal( e.velocity, events[#events].velocity )
	assert_equal( 0, g.velocity ) -- reset for the next pan
end

function test_panIgnoresLiftedPinchFinger()
	local v = newView()
	local pinch = Gesture.newPinchGesture( v )
	local pan = Gesture.newPanGesture( v )
	local both = { shouldRecognizeWith=function() return true end }
	pinch.delegate, pan.delegate = both, both
	record( pinch ) ; record( pan )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 200 ) ; frame()
	touch( v, 'B', 'moved', 300, 300 ) ; frame()
	touch( v, 'B', 'moved', 320, 320 ) ; frame()
	touch( v, 'B', 'ended', 320, 320 ) ; frame()
	touch( v, 'A', 'moved', 150, 150 ) ; frame()
	touch( v, 'A', 'moved', 200, 200 ) ; frame()
	touch( v, 'A', 'ended', 200, 200 ) ; frame( 2 )
	assert_equal( 'pinch:began pinch:changed pinch:changed pinch:ended', phases() )
end

function test_twoFingerPanSendsOneBegan()
	local v = newView()
	record( Gesture.newPanGesture( v, { max_touches=2 } ) )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	touch( v, 'B', 'began', 200, 100 ) ; frame()
	touch( v, 'A', 'moved', 150, 100 ) ; touch( v, 'B', 'moved', 250, 100 ) ; frame()
	touch( v, 'A', 'ended', 150, 100 ) ; touch( v, 'B', 'ended', 250, 100 ) ; frame( 2 )
	local p = phases()
	assert_equal( 'pan:began', p:sub( 1, 9 ) )
	assert_nil( p:find( 'began', 10 ), p )
	assert_equal( 'pan:ended', p:sub( -9 ) )
end

function test_panWithTapGetsEachTouchOnce()
	-- the order the manager holds them in isn't fixed: try both
	for _, tap_first in ipairs{ true, false } do
		events = {}
		local v = newView()
		local tap, pan
		if tap_first then tap = Gesture.newTapGesture( v ) end
		pan = Gesture.newPanGesture( v )
		if not tap_first then tap = Gesture.newTapGesture( v ) end
		record( pan )
		touch( v, 'A', 'began', 100, 100 ) ; frame()
		for k = 1, 4 do touch( v, 'A', 'moved', 100+15*k, 100 ) ; frame() end
		touch( v, 'A', 'ended', 160, 100 ) ; frame( 2 )
		assert_equal( 'pan:began pan:changed pan:changed pan:changed pan:changed pan:ended', phases() )
		v:removeSelf()
	end
end

function test_panCancelledBeforeBeginSendsNothing()
	local v = newView()
	local warned
	local pwarn = _G.pwarn
	_G.pwarn = function( m ) warned = m end
	record( Gesture.newPanGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	touch( v, 'A', 'cancelled', 100, 100 ) ; frame( 2 )
	_G.pwarn = pwarn
	assert_equal( '', phases() )
	assert_nil( warned )
end

function test_longPress()
	local v = newView()
	record( Gesture.newLongPressGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	wait( 600 )
	touch( v, 'A', 'moved', 150, 100 ) ; frame()
	touch( v, 'A', 'ended', 150, 100 ) ; frame( 2 )
	assert_equal( 'longpress:began longpress:changed longpress:ended', phases() )
	assert_equal( 100, events[3].xStart )
end

function test_longPressTooShortSendsNothing()
	local v = newView()
	record( Gesture.newLongPressGesture( v ) )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	wait( 200 )
	touch( v, 'A', 'ended', 100, 100 ) ; frame( 2 )
	wait( 600 )
	assert_equal( '', phases() )
end

--== Tap

function test_tapPositionAndTime()
	local v = newView()
	record( Gesture.newTapGesture( v ) )
	touch( v, 'A', 'began', 100, 120 ) ; frame()
	touch( v, 'A', 'ended', 102, 120 ) ; frame( 2 )
	assert_equal( 'tap:nil', phases() )
	local e = events[1].e
	assert_equal( 102, e.x ) ; assert_equal( 120, e.y )
	assert_equal( 'number', type( e.time ) )
end

function test_twoFingerTapPosition()
	local v = newView()
	record( Gesture.newTapGesture( v, { touches=2 } ) )
	touch( v, 'A', 'began', 100, 100 ) ; touch( v, 'B', 'began', 200, 100 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; touch( v, 'B', 'ended', 200, 100 ) ; frame( 2 )
	assert_equal( 'tap:nil', phases() )
	assert_equal( 150, events[1].e.x )
end

local function doubleTap( v, gap )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	touch( v, 'A', 'ended', 100, 100 ) ; frame()
	wait( gap )
	touch( v, 'B', 'began', 100, 100 ) ; frame()
	touch( v, 'B', 'ended', 100, 100 ) ; frame( 2 )
end

function test_doubleTapTimeout()
	local v = newView()
	record( Gesture.newTapGesture( v, { taps=2 } ) )
	doubleTap( v, 200 )
	assert_equal( 'tap:nil', phases() )
	events = {}
	wait( 1000 )
	doubleTap( v, 400 )
	assert_equal( '', phases() )
end

function test_doubleTapLongerTimeout()
	local v = newView()
	local g = Gesture.newTapGesture( v, { taps=2, timeout=600 } )
	assert_equal( 600, g.timeout )
	record( g )
	doubleTap( v, 400 )
	assert_equal( 'tap:nil', phases() )
end

--== Removal

function test_removedViewIsForgotten()
	local v = newView()
	local g = Gesture.newTapGesture( v )
	Gesture.newPanGesture( v )
	touch( v, 'A', 'began', 100, 100 ) ; frame()
	assert_not_nil( Gesture._GESTURE_MGR[v] )
	assert_not_nil( TouchMgr._OBJECT[v] )
	v:removeSelf()
	assert_nil( Gesture._GESTURE_MGR[v] )
	assert_nil( TouchMgr._OBJECT[v] )
	assert_nil( TouchMgr._FOCUS['A'] )
	frame( 2 )
	assert_equal( 0, countRuntime( 'enterFrame' ) )
	assert_equal( 0, #timers )
end

function test_removeGesturesThenView()
	local v = newView()
	local g1 = Gesture.newTapGesture( v )
	local g2 = Gesture.newPanGesture( v )
	g1:removeSelf() ; g2:removeSelf()
	assert_nil( Gesture._GESTURE_MGR[v] )
	assert_equal( 0, #( v.listeners.finalize or {} ) )
	v:removeSelf()
end

--== Settings

function test_debugOff()
	local g = Gesture.newTapGesture( newView() )
	assert_false( g.__debug_on )
	local g2 = Gesture.newTapGesture( newView(), { debug_on=true } )
	assert_true( g2.__debug_on )
end
