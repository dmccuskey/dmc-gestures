# Changelog

## 2.1.0 (2026-10-01)

### Fixed

- A continuous gesture (long press, pan, pinch) sends `ended` only after `began`. Before, a two-finger tap on a pinch, or two fingers down and one lifted before the pinch began, sent an `ended` with no `began`.
- `xStart` and `yStart` are where the touches began in every event of a pan, pinch or long press. Before, in `changed` and `ended` they were where the first move was seen.
- More fingers than a pan's `max_touches`, or than a pinch's two, fail it before it begins, until they all lift; lifting one finger before it begins waits for enough fingers again. Before, lifting one finger of a pinch could start a one-finger pan on the same view, and a two-finger pan sent `began` twice.
- A touch that has ended no longer counts in the center of the fingers once another touch begins or moves.
- Removing a view (`view:removeSelf()`) removes its gestures and its gesture manager. Before, a view removed while it had gestures was never freed.
- A gesture that begins while others are being handed the same touch no longer makes the gesture manager hand it to one of them twice (a pan alongside a tap sent its first `changed` twice).
- A cancelled touch on a pan or pinch that hasn't begun fails it without a warning.
- The `[DMC_GESTURE]` `DEBUG_ACTIVE` setting in `dmc_corona.cfg` is read: it turns on each gesture's debug output.
- The module no longer sets the global `_extend`; it uses lua_utils from DMC-Lua-Library instead of its own copy of `Utils.extend()`.

### Added

- `velocity` in pan and pinch events and on the gestures: the pan's speed in points per second (with `xVelocity` and `yVelocity`), the pinch's change in scale per second, over the last 100 ms of movement.
- Tap events have `x`, `y` (the center of the fingers) and `time`.
- The tap's `timeout` setting (default 300 ms), the time allowed for each step of a tap.
- A `debug_on` parameter for each gesture.
- `Gesture.VERSION`.
- Unit tests (stand-in display, Runtime, timer and clock), and `tests/run_unit.sh` to run them with plain Lua 5.1.

### Changed

- Removed pinch's `test_mode`, which did nothing.
- The `gesture-pinch-basic` example no longer guards against `ended` without `began`.
- Rebuilt against the current dmc-corona-boot, DMC-Lua-Library, dmc-objects, dmc-patch, dmc-utils, dmc-states-mixin and dmc-touchmanager.
