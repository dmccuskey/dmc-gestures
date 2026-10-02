# API Reference

Everything dmc-gestures provides, for version 2.1.0. The [Quick Start](../README.md#quick-start) shows it in use.

## Quick Reference

| Call | Makes a gesture that recognizes | Events |
|---|---|---|
| [`Gesture.newTapGesture( obj [, params] )`](#tap) | quick taps, with one or more fingers | one, when recognized |
| [`Gesture.newLongPressGesture( obj [, params] )`](#long-press) | a press held still, optionally after taps | `began`, `changed`, `ended` |
| [`Gesture.newPanGesture( obj [, params] )`](#pan) | a drag, with one or more fingers | `began`, `changed`, `ended` |
| [`Gesture.newPinchGesture( obj [, params] )`](#pinch) | two fingers moving apart or together | `began`, `changed`, `ended`, with `scale` |

Each returns a gesture object:

| Member | |
|---|---|
| `gesture:addEventListener( gesture.EVENT, listener )` | get its events ([The Gesture Event](#the-gesture-event)) |
| `gesture:removeEventListener( gesture.EVENT, listener )` | stop getting them |
| `gesture:removeSelf()` | remove the gesture from its object |
| `gesture.id` | a string of your choice, copied into each event (read and write) |
| `gesture.delegate` | a table that decides how gestures on one object work together ([Delegates](#delegates)) (read and write) |
| `gesture.view` | the display object it watches (read only) |

The constructors use a dot (`.`); the methods use a colon (`:`).

## The Module

```lua
local Gesture = require 'dmc_corona.dmc_gestures'
```

It loads [dmc-touchmanager](https://github.com/dmccuskey/dmc-touchmanager), which calls `system.activate( 'multitouch' )`, so the app doesn't need to. The gesture classes load when first used. `Gesture.VERSION` is the version, a string.

## How Gestures Work

A gesture is attached to one display object, its view, when it's made. It watches every touch that begins on the view and decides, touch by touch, whether its gesture is happening. It has a state, as in iOS: it starts out *possible*, and either *fails* (the touches don't match) or is *recognized*. When every touch has ended, it starts again from possible.

- **Discrete gestures** (tap) send one event, when recognized.
- **Continuous gestures** (long press, pan, pinch) send `began` when recognized, `changed` as the touches move, and `ended` when they lift.

The first gesture object on a view makes a gesture manager for it and registers the view with dmc-touchmanager. The manager focuses each touch that begins on the view, so the touch stays with the view when it moves off it, and hands the touches to every gesture on the view.

Touches reach the gestures once per frame, one frame late: the manager collects them and passes them on at the next `enterFrame`. The first frame of a new touch is merged into one `began` at the touch's latest position, because the first positions of a touch are often unsteady.

## The Gestures

The parameters are the fields of the optional `params` table. Each (except `id`, `delegate` and `debug_on`) is also a property of the gesture, which can be changed later: `tap.taps = 3`. Distances are in content units (points); a value outside the allowed range fails an assertion.

Every constructor also takes:

| Parameter | Type | Default | |
|---|---|---|---|
| `id` | string | `nil` | copied into each event, to tell gestures apart in a shared listener |
| `delegate` | table | `nil` | see [Delegates](#delegates) |
| `debug_on` | boolean | the `debug_active` [setting](#configuration) | print the gesture's state changes and events |

### Tap

```lua
local tap = Gesture.newTapGesture( obj, { touches=2, taps=2 } )  -- two-finger double tap
```

| Parameter | Type | Default | Range | |
|---|---|---|---|---|
| `taps` | number | `1` | 1 to 5 | how many taps |
| `touches` | number | `1` | 1 to 4 | how many fingers in each tap |
| `accuracy` | number | `10` | above 0 | how far a finger can move from where it went down, across or up and down, before the tap fails |
| `timeout` | number | `300` | above 0 | the time allowed for each step, in milliseconds: once all the fingers are down they must all lift within it, and the next tap must start within it of the last one |

More fingers than `touches`, or more taps than `taps`, fail the gesture.

The event has `x` and `y`, the center of the fingers as they lifted on the last tap, and `time`, `system.getTimer()` when the tap was recognized.

### Long Press

```lua
local press = Gesture.newLongPressGesture( obj, { duration=800 } )
```

| Parameter | Type | Default | Range | |
|---|---|---|---|---|
| `duration` | number | `500` | above 50 | how long the press must be held still, in milliseconds |
| `taps` | number | `0` | 0 or more | how many taps before the press (a tap-and-hold is `taps=1`) |
| `touches` | number | `1` | 1 to 5 | how many fingers |
| `accuracy` | number | `10` | above 0 | how far a finger can move before `duration` is up |

`began` comes when the press has been held for `duration`; the fingers can then move freely, sending `changed`, and `ended` comes when they lift. Lifting early, moving too far, or a finger too many fails it. The taps before the press follow the default tap timing (300 ms).

### Pan

```lua
local pan = Gesture.newPanGesture( obj, { touches=2 } )  -- two-finger drag
```

| Parameter | Type | Default | Range | |
|---|---|---|---|---|
| `touches` | number | `1` | 1 to 255 | the fewest fingers |
| `max_touches` | number | `touches` | 1 to 255 | the most fingers |
| `threshold` | number | `10` | 0 to 255 | how far a finger must move, across or up and down, before the pan begins; `0` begins it as soon as the fingers are down |

`x` and `y` in the event are the center of the fingers. The pan ends when the fingers lift. More fingers than `max_touches` before the pan begins fail it, until they all lift. Once it has begun, if the number of fingers leaves the `touches` to `max_touches` range, the pan sends `ended`, and it sends `began` again if the count comes back into range and the fingers move.

The events have `velocity`, the speed of the center of the fingers in points per second, and its parts across and down, `xVelocity` and `yVelocity` (negative to the left and up). It's measured over the last 100 ms of movement, so it's `0` when the fingers were held still that long before they lifted. `pan.velocity` is the same, while the pan runs; it goes back to `0` once the fingers have lifted.

### Pinch

```lua
local pinch = Gesture.newPinchGesture( obj )
```

| Parameter | Type | Default | Range | |
|---|---|---|---|---|
| `threshold` | number | `5` | above 0, below 256 | how much the distance between the fingers must change before the pinch begins |
| `reset_scale` | boolean | `true` | | `true`: each pinch's `scale` starts from 1. `false`: it carries on from where the last pinch ended, so `scale` is the total since the gesture was made |

A pinch takes exactly two fingers: a third before the pinch begins fails it, until they all lift, and lifting one before it begins waits for a second finger again. The event's `scale` is the distance between them now divided by the distance when the pinch began: above 1 when they move apart, below 1 when they move together. To zoom an object, save its scale at `began` and multiply:

```lua
local xScale, yScale

pinch:addEventListener( pinch.EVENT, function( event )
	if event.type ~= pinch.GESTURE then return end
	if event.phase == 'began' then
		xScale, yScale = obj.xScale, obj.yScale
	end
	obj.xScale, obj.yScale = xScale*event.scale, yScale*event.scale
end )
```

The events have `velocity`, how fast `scale` changes, per second (negative when the fingers move together), measured like the pan's. `pinch.velocity` is the same, while the pinch runs.

## The Gesture Event

Add a listener for `gesture.EVENT` (the name `'gesture-event'`). A function listener is simplest; a table listener needs a method named `gesture-event`, so it's written `listener['gesture-event'] = function( self, event ) ... end`.

| Field | Value |
|---|---|
| `name` | `gesture.EVENT` |
| `type` | `gesture.GESTURE`: a gesture was seen. It's the only type sent to listeners, but checking it keeps a listener safe if more are added. |
| `target` | the gesture object (its view is `event.target.view`) |
| `id` | the gesture's `id` |
| `gesture` | `'tap'`, `'longpress'`, `'pan'` or `'pinch'` |

Continuous gestures (long press, pan, pinch) add:

| Field | Value |
|---|---|
| `phase` | `'began'`, `'changed'` or `'ended'` |
| `x`, `y` | the center of the fingers, in content coordinates |
| `xStart`, `yStart` | where `x`, `y` were when the gesture's touches began |
| `count` | how many fingers are down; at `ended`, after the lift |
| `time` | when the touch behind the event happened (its `time`), or `system.getTimer()` |
| `touches` | the touches themselves, keyed on `tostring( touch id )`: each a table with `id`, `x`, `y`, `xStart`, `yStart`, `phase` |
| `scale` | pinch only: see [Pinch](#pinch) |
| `velocity` | pan and pinch: see [Pan](#pan) and [Pinch](#pinch) |
| `xVelocity`, `yVelocity` | pan only |

A continuous gesture sends `ended` only after `began`. It reuses one table for its `changed` and `ended` events, and `touches` is the gesture's own table: copy what you need to keep rather than keeping the event.

To move an object with a pan, save its offset from the fingers at `began`, as the [Quick Start](../README.md#quick-start) does. Setting the object's position to `x`, `y` directly makes it jump so that its center is under the fingers (the `gesture-pan-move` example does this).

## Several Gestures on One Object

Any number of gestures can share a view; each sees all of its touches:

```lua
local pan1 = Gesture.newPanGesture( obj, { id='drag' } )
local pan2 = Gesture.newPanGesture( obj, { touches=2, id='scroll' } )
local tap2 = Gesture.newTapGesture( obj, { taps=2, id='zoom' } )
```

When one is recognized (a tap) or begins (a continuous gesture), the others fail and stop getting touches until every touch has ended, unless a delegate keeps them ([Delegates](#delegates)). So of the gestures above, whichever matches the touches first wins.

There is no way to make one gesture wait for another to fail (iOS's `requiresGestureRecognizerToFail`, [#2](https://github.com/dmccuskey/dmc-gestures/issues/2)): a single tap and a double tap on the same object don't work together, because the single tap is recognized at the first tap and fails the double tap.

## Delegates

A delegate is a table with any of these functions; set it with the `delegate` parameter or property. One delegate can serve several gestures.

| Function | Called | Return |
|---|---|---|
| `delegate:shouldRecognizeWith( recognized, other )` | when gesture `recognized` is recognized or begins, once for each `other` gesture on the view that is still possible or running, on `other`'s delegate | `true` to keep `other` running alongside, `false` (the default) to fail it |
| `delegate.gestureShouldBegin( gesture )` | when `gesture` is about to leave the possible state | `false` to fail it instead |
| `delegate.shouldReceiveTouch( gesture )` | when a new touch begins on the view | `false` to leave `gesture` out until the touches end; must be a boolean |

Note the colon and the dots: `shouldRecognizeWith` gets the delegate as its first argument, the other two get only the gesture ([#3](https://github.com/dmccuskey/dmc-gestures/issues/3)).

To let a pan and a pinch run at the same time (as a photo viewer does), give both a delegate that says yes:

```lua
local together = {
	shouldRecognizeWith = function( self, recognized, other ) return true end,
}
local pan = Gesture.newPanGesture( photo, { delegate=together } )
local pinch = Gesture.newPinchGesture( photo, { delegate=together } )
```

The `gesture-multigesture-simultaneous` example does this with a pan, a pinch and two double taps.

## Removing Gestures

`gesture:removeSelf()` removes a gesture from its view. When the last gesture on a view is removed, the view's gesture manager goes too, and the view is unregistered from dmc-touchmanager.

Removing the view (`view:removeSelf()`) removes its gestures too, so don't call `removeSelf()` on them afterwards. The `gesture-memtest` example makes and removes gestures in a loop to check for leaks.

## Configuration

dmc-gestures reads a `[DMC_GESTURE]` section of `dmc_corona.cfg`, with one setting:

| Key | Type | Default | |
|---|---|---|---|
| `DEBUG_ACTIVE` | boolean | `false` | the default for each gesture's `debug_on`: print its state changes and the events it sends |

```text
[DMC_GESTURE]
DEBUG_ACTIVE:BOOL = true
```

The file needs only the `[DMC_CORONA]` section, which tells the loader where the libraries are ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

## Background

dmc-gestures follows the design of UIKit's [UIGestureRecognizer](https://developer.apple.com/documentation/uikit/uigesturerecognizer): the states, the discrete and continuous kinds, and the delegate's `shouldRecognizeWith` (iOS's `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`), `gestureShouldBegin` and `shouldReceiveTouch`. Swipe and rotation gestures, iOS's `cancelsTouchesInView`, `delaysTouchesBegan`, `delaysTouchesEnded` and `requiresGestureRecognizerToFail` ([#2](https://github.com/dmccuskey/dmc-gestures/issues/2)) aren't written: the methods of those names on a gesture do nothing.

## Known Issues

- **A single tap wins over a double tap** on the same view ([Several Gestures](#several-gestures-on-one-object)); there's no `requiresGestureRecognizerToFail` ([#2](https://github.com/dmccuskey/dmc-gestures/issues/2)).
- **The delegate functions are called in two ways**: `shouldRecognizeWith` with the delegate first, `gestureShouldBegin` and `shouldReceiveTouch` without it ([Delegates](#delegates), [#3](https://github.com/dmccuskey/dmc-gestures/issues/3)).
- The long press's tap timing (300 ms) can't be changed.
