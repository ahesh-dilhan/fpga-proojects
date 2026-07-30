// =========================================================================
// traffic_light_fsm.v
//
// Classic 4-state traffic light FSM for a 2-way intersection (North-South
// vs East-West). Advances one state on every `tick` input (decoupled from
// the actual clock frequency via a separate tick_gen module).
//
// States and their (parameterized) durations in ticks:
//   NS_GREEN  -> NS traffic goes,  EW is red
//   NS_YELLOW -> NS transitioning, EW is red
//   EW_GREEN  -> EW traffic goes,  NS is red
//   EW_YELLOW -> EW transitioning, NS is red
//
// Safety invariant this design guarantees: NS and EW can never both show
// green (or both show anything-but-red) at the same time. This is checked
// explicitly in the testbench, since it's the single most important
// property of any real traffic light controller.
// =========================================================================
module traffic_light_fsm #(
    parameter GREEN_TICKS  = 5,
    parameter YELLOW_TICKS = 2
) (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    output reg  ns_red, ns_yellow, ns_green,
    output reg  ew_red, ew_yellow, ew_green
);

    localparam NS_GREEN  = 2'b00;
    localparam NS_YELLOW = 2'b01;
    localparam EW_GREEN  = 2'b10;
    localparam EW_YELLOW = 2'b11;

    reg [1:0]  state;
    reg [7:0]  tick_count;  // counts ticks spent in the current state

    // ---- State register + tick counter ----
    always @(posedge clk) begin
        if (rst) begin
            state      <= NS_GREEN;
            tick_count <= 0;
        end else if (tick) begin
            case (state)
                NS_GREEN: begin
                    if (tick_count >= GREEN_TICKS - 1) begin
                        state      <= NS_YELLOW;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                NS_YELLOW: begin
                    if (tick_count >= YELLOW_TICKS - 1) begin
                        state      <= EW_GREEN;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                EW_GREEN: begin
                    if (tick_count >= GREEN_TICKS - 1) begin
                        state      <= EW_YELLOW;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                EW_YELLOW: begin
                    if (tick_count >= YELLOW_TICKS - 1) begin
                        state      <= NS_GREEN;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
                default: state <= NS_GREEN;
            endcase
        end
    end

    // ---- Output logic: purely a function of current state (Moore FSM) ----
    always @(*) begin
        {ns_red, ns_yellow, ns_green} = 3'b100;  // default: NS red
        {ew_red, ew_yellow, ew_green} = 3'b100;  // default: EW red

        case (state)
            NS_GREEN:  {ns_red, ns_yellow, ns_green} = 3'b001;
            NS_YELLOW: {ns_red, ns_yellow, ns_green} = 3'b010;
            EW_GREEN:  {ew_red, ew_yellow, ew_green} = 3'b001;
            EW_YELLOW: {ew_red, ew_yellow, ew_green} = 3'b010;
            default: ;  // both stay red (safe default)
        endcase
    end

endmodule
