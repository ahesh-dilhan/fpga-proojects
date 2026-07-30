// =========================================================================
// traffic_light_top.v
//
// Top-level: combines tick_gen (slows the system clock down to a human
// timescale) with traffic_light_fsm (the actual state machine).
//
// DIVISOR is left as a parameter here rather than hardcoded, since the
// "right" value depends on which board's clock frequency you target
// (e.g. 50MHz on DE2-115, 125MHz on Zybo Z7) - set it when instantiating
// this module for your specific board.
// =========================================================================
module traffic_light_top #(
    parameter DIVISOR      = 50_000_000,  // ticks once per second at 50MHz
    parameter GREEN_TICKS  = 5,           // 5 second green
    parameter YELLOW_TICKS = 2            // 2 second yellow
) (
    input  wire clk,
    input  wire rst,
    output wire ns_red, ns_yellow, ns_green,
    output wire ew_red, ew_yellow, ew_green
);

    wire tick;

    tick_gen #(.DIVISOR(DIVISOR)) u_tick_gen (
        .clk(clk), .rst(rst), .tick(tick)
    );

    traffic_light_fsm #(
        .GREEN_TICKS(GREEN_TICKS),
        .YELLOW_TICKS(YELLOW_TICKS)
    ) u_fsm (
        .clk(clk), .rst(rst), .tick(tick),
        .ns_red(ns_red), .ns_yellow(ns_yellow), .ns_green(ns_green),
        .ew_red(ew_red), .ew_yellow(ew_yellow), .ew_green(ew_green)
    );

endmodule
