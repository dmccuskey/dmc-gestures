# dmc-gestures


`dmc-gestures` is a module for creating Gesture Recognizers which will watch for gestures performed on an object. The module is modeled after iOS Gesture Recognizers.

This module is also included in the more comprehensive [DMC Corona Library repo](https://github.com/dmccuskey/DMC-Corona-Library).


## General Usage


The touch object can be used as either the controller which just accepts touch events or additionally as the object _being_ controlled. The difference really depends on your touch handler and _to which_ object it applies a gesture's values, either the original view or a separate object.

There are examples of both found in the repo directory `examples`.


### Simple gesture handling


This example just displays the gesture event:

```lua
-- setup some constants to make placement easier
local W, H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5

-- import the gesture library
local Gesture = require 'dmc_corona.dmc_gestures'

-- setup our touch area for the gesture
local view = display.newRect( H_CENTER, V_CENTER+40, V_CENTER, V_CENTER )

-- create our handler, looking for event GESTURE
local function gestureEvent_handler( event )
	-- print( "gestureEvent_handler" )
	if event.type == event.target.GESTURE then
		"Gesture: "..tostring( event.gesture )
	end
end

-- add a tap gesture, using the defaults (single tap, single touch)
local tap = Gesture.newTapGesture( view )
tap:addEventListener( tap.EVENT, gestureEvent_handler )
```


### Stacking gestures


Gestures can also be "stacked" on a view to watch for more than one gesture.

_Note: This snippet is from the example `gesture-multigesture-basic`_

```lua
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
```



