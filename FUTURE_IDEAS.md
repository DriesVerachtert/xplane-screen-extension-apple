# Future ideas

Captured ideas that are not part of the current build plan (`PLAN.md`) --
worth revisiting later, not scoped or committed to now.

## Flight-condition warnings panel

Idea: a screen (or a dedicated instrument within an existing screen) that
watches live dataref values and surfaces simple text warnings for unsafe or
unusual configurations, e.g.:

- Descending below some altitude with landing gear not down.
- Climbing above some altitude with landing gear still extended.
- Moving on the ground above some speed without taxi/landing lights on.

### Why this fits the existing architecture

No new networking or protocol work is needed. `DataRefStore` (see `PLAN.md`)
already supports subscribing to arbitrary datarefs and observing live updates;
a warnings panel would just be another consumer: subscribe to a handful of
relevant datarefs (altitude, gear position, ground speed, light switches,
on-ground flag, ...), evaluate a small set of conditions against the current
values each time they change, and render any active violations as a list of
warning strings. This is architecturally a sibling of the instrument pages
and the button screen, not a new subsystem.

### Why this is *not* ready to scope into a build step yet

Neither of us is a pilot, and X-Plane experience here is limited. The risk
isn't implementation difficulty, it's confidently encoding wrong thresholds
or wrong logic:

- Real GPWS/EGPWS "too low, gear" logic has nuances (approach phase, flap
  configuration, aircraft type) that a naive altitude+gear check would miss
  or get wrong.
- "Taxiing" isn't a single dataref; it's inferred from some combination of
  on-ground state and ground speed, and the right combination/thresholds
  aren't obvious without research.
- Which ExtPlane/X-Plane datarefs correspond to gear state, lights, and
  on-ground status, and what reasonable default thresholds are, needs a
  research pass against the X-Plane dataref list and real-world
  GPWS/aviation-warning conventions before it can be turned into concrete
  rules.

So before implementing: research actual aviation warning conventions
(simplified GPWS-style callouts are fine as a reference, not a certification
requirement) and the specific X-Plane datarefs needed, and write those up
as concrete rules first. Implement only after that research, not by
guessing thresholds.

### A caution for whenever this gets built

Frame this clearly in the app as a simplified sanity-check/learning aid, not
an accurate or certified GPWS/EICAS replica -- otherwise users could mistake
a hobby approximation for something authoritative.

### Rough shape, if/when it gets built

- A small `FlightConditionRule` type: a set of datarefs it needs, a pure
  function from current values to "active" / "not active" plus a message.
- A `FlightConditionMonitor` (or similar) that holds a list of rules,
  subscribes to the union of datarefs they need via `DataRefStore`, and
  re-evaluates on each update, exposing the currently active warnings.
- A simple SwiftUI list view rendering active warnings, reusing the same
  instrument-page/button-screen conventions already established.
