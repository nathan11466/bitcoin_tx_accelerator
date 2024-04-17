///////////////////////////////////////////////////////////////////////////////
// Accelerator SHA256 Message Scheduler
//
// This module is one of the workers of the Accelerator. It extends the
// original message according to the SHA256 algorithm.
//
// The internals of this unit are based around a group of Circular Buffers
// made up of 16 32-bit registers.
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_message_scheduler
#(
)
(
    input clk,
    input rst_n,

    input ms_init, ms_enable,
    input [511:0] message,

    output reg [31:0] ms_r0_out
);

// Circular Buffer
localparam CB_REG_COUNT = 16;
localparam CB_REG_SIZE = 32;

reg [CB_REG_SIZE-1:0] circular_buffer [CB_REG_COUNT-1:0];

// Math
wire [CB_REG_SIZE-1:0] sigma_0, sigma_1, w;

assign sigma_0 = (circular_buffer[2] >> 7) ^ (circular_buffer[2] >> 18) ^ (circular_buffer[2] >> 3);
assign sigma_1 = (circular_buffer[15] >> 17) ^ (circular_buffer[15] >> 19) ^ (circular_buffer[15] >> 10);
assign w = circular_buffer[1] + sigma_0 + circular_buffer[10] + sigma_1;

// Circular Buffer Process
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < CB_REG_COUNT; i = i + 1) begin
            circular_buffer[i] <= 0;
        end
    end else if (ms_init) begin
        for (int i = 0; i < CB_REG_COUNT; i = i + 1) begin
            circular_buffer[i] <= message[CB_REG_SIZE * i +: CB_REG_SIZE];
        end
    end else if (ms_enable) begin
        circular_buffer[0] <= w;
        for (int i = 1; i < CB_REG_COUNT; i = i + 1) begin
            circular_buffer[i] <= circular_buffer[i - 1];
        end
    end
end

// Output
assign ms_r0_out = circular_buffer[0];

endmodule
