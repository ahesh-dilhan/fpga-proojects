# Project 03 - Traffic Light Controller (FSM)

A classic 4-state Moore FSM controlling a 2-way intersection (North-South
vs East-West traffic). This ties directly into whatever your DSD lectures
are covering on state machines - and traffic light controllers are one of
the most commonly used teaching examples for exactly that reason.

## Files
```
src/tick_gen.v              Reusable clock divider - turns a fast system
                             clock into a slow "tick" (e.g. once/second)
src/traffic_light_fsm.v     The actual 4-state FSM
src/traffic_light_top.v     Top-level: wires tick_gen + FSM together
sim/tb_traffic_light_top.v  Testbench: checks state sequence AND the
                             critical safety invariant continuously
```

## The FSM
```
NS_GREEN --(after GREEN_TICKS)--> NS_YELLOW --(after YELLOW_TICKS)-->
EW_GREEN --(after GREEN_TICKS)--> EW_YELLOW --(after YELLOW_TICKS)-->
NS_GREEN  (loops back)
```
Both directions default to RED unless explicitly in their GREEN or
YELLOW state - so "everything red" is never actually reachable here,
but if it somehow were, it's the safe failure mode, not a broken one.

## The safety invariant (the actual point of this project)
The testbench doesn't just check "does the sequence look right" - it
runs a check on **every single clock cycle** for the entire simulation:
NS and EW can never both show a non-red light at the same time. This is
the single property that actually matters in a real traffic light -
getting the timing slightly wrong is a minor inconvenience; two directions
going green together is a collision. Building the habit of identifying
and explicitly testing the ONE property that must never break, rather
than just checking "does it look right", is a good habit for any FSM
you design in the future.

## Already verified in simulation
```
PASS: starts in NS_GREEN
--- Cycle 0 ---
PASS: transitioned to NS_YELLOW
PASS: transitioned to EW_GREEN
PASS: transitioned to EW_YELLOW
PASS: transitioned back to NS_GREEN
--- Cycle 1 --- (repeats correctly)
ALL TESTS PASSED (including continuous safety check)
```

## Run it yourself
```bash
verilator --binary --trace sim/tb_traffic_light_top.v \
    src/traffic_light_top.v src/traffic_light_fsm.v src/tick_gen.v \
    --top-module tb_traffic_light_top -Wno-fatal
./obj_dir/Vtb_traffic_light_top
```

```bash
gtkwave dump.vcd
```
Useful signals: `ns_red/ns_yellow/ns_green`, `ew_red/ew_yellow/ew_green`,
and internally `dut.u_fsm.state`. Watch the two 3-bit "light" groups -
you should visually see them alternate, never overlapping in
yellow/green.

## Adapting for real hardware (once a board target is settled)
This design is intentionally hardware-agnostic - `DIVISOR` in
`traffic_light_top` should be set to your board's actual clock frequency
to get real 1-second timing (e.g. `50_000_000` for DE2-115's 50MHz clock,
or `125_000_000` for Zybo Z7's 125MHz clock). The 6 output wires
(`ns_red/yellow/green`, `ew_red/yellow/green`) map naturally to 6 LEDs -
exact pin numbers depend on which board ends up being the target, so
we'll add the constraints file once that's settled.

## What's next
This is your first "real" FSM with an explicit state register - the same
pattern (state register + tick/event counter + case statement + safety
invariant testing) scales up to much more complex controllers later:
vending machines, protocol state machines, even simple CPU control units.
