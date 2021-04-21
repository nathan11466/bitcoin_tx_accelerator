/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_instrmem
//
// Author: Logan Sisel
//
// Detail: Instruction memory for the CPU.
//         Read only, byte Addressable, 64k Bytes (2^16 addresses).
//         Reads access 2 bytes at...
//           data_mem[addr], data_mem[addr+1]
//         Initialized by loader on reset, first instruction at 0x0000.
//         
// Mem Map: 
// Instruction Memory
// 0x0000-0xFFFF
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_instrmem (clk, rst_n, addr, instr, err);

    input             clk, rst_n;
    input      [15:0] addr; 
    output reg [31:0] instr;
    output reg        err;

    localparam MEM_SIZE = 65536;

    logic [31:0] instr_mem [0:MEM_SIZE-1];

    // Error if instruction addr not at valid location
    // Should be a multiple of 4 (0x0000, 0x0004, etc)
    assign err = (addr % 4 != 0);

    // Read logic
    // Set instr to 0 if invalid address
    //assign instr = (addr % 4 == 0) ? instr_mem[addr+3:addr] : 32'h0; //TODO: does this work? no
    always_comb begin
        if (addr % 4 == 0) begin
            instr[7:0] = instr_mem[addr];
            instr[15:8] = instr_mem[addr+1];
            instr[23:16] = instr_mem[addr+2];
            instr[31:24] = instr_mem[addr+3];
            /*
            for (integer i = 0; i < 3; i = i + 1) begin
                instr[i] = instr_mem[addr+i]; //TODO: Pretty sure this is wrong
            end
            */
        end 
        else instr = 32'h0;
    end

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // TODO: Load from loader
        end
    end

endmodule