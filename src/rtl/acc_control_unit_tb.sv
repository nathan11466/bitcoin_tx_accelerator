module acc_control_unit_tb();

// CPU address line redirected from Data Memory for monitoring MMIO
localparam MEM_LISTEN_ADDR_SIZE      = 16;
// CPU data line redirected from Data Memory for monitoring MMIO
localparam MEM_LISTEN_DATA_SIZE      = 32;

// Address line going back to the Data Memory
localparam MEM_ACC_READ_ADDR_SIZE    = 16;
// Data line coming from the Data Memory
localparam MEM_ACC_READ_DATA_SIZE    = 512;

// Address line going out from the Accelerator to the Data Memory
localparam MEM_ACC_WRITE_ADDR_SIZE   = 16;
// Data line going out from the Accelerator to the Data Memory
localparam MEM_ACC_WRITE_DATA_SIZE   = 32;

// Starting address of the Host Communication Block in Data Memory
localparam HCB_START_ADDR            = 16'h1000;
// Offset of the Message from HCB starting address
localparam HCB_MSG_OFFSET            = 16'h0008;
// Starting address of the Accelerator Communication Block in Data Memory
localparam ACB_START_ADDR            = 16'h5000;
// Offset of h0 from ACB starting address
localparam ACB_H0_OFFSET             = 16'h0008;

// Width of the resulting hash
localparam HASH_RESULT_LENGTH        = 256;

// Address of h0 in ACB
localparam ACB_H0_ADDR               = ACB_START_ADDR + ACB_H0_OFFSET;

// @review: is this still 65?
localparam HASH_CYCLE_COUNT          = 65;

/// Signals
reg                                              clk, rst_n;
reg                [MEM_LISTEN_ADDR_SIZE - 1:0]  mem_listen_addr;
reg                                              mem_listen_en;
reg                [MEM_LISTEN_DATA_SIZE - 1:0]  mem_listen_data;

reg                                              mem_acc_read_data_valid;
reg              [MEM_ACC_READ_DATA_SIZE - 1:0]  mem_acc_read_data;

reg                                              mem_acc_write_done;

reg                  [HASH_RESULT_LENGTH - 1:0]  cm_out;

wire                                              mem_acc_read_en;
wire              [MEM_ACC_READ_ADDR_SIZE - 1:0]  mem_acc_read_addr;

wire                                              mem_acc_write_en;
wire             [MEM_ACC_WRITE_ADDR_SIZE - 1:0]  mem_acc_write_addr;
wire             [MEM_ACC_WRITE_DATA_SIZE - 1:0]  mem_acc_write_data;

wire                                              ms_init, ms_enable;
wire                                              cm_init, cm_enable;

int test_number = 0;

/// Copy of the internal states
typedef enum {
    IDLE,             // Reset/Idle

    READ_MESSAGE,     // Read message from Data Memory

    WRITE_BUSY_BIT,   // Writing the busy bit to Data Memory

    INIT,             // Initialize both MS and CM

    HASH,             // Processing hash

    WRITE_H0,         // Write h0 back to Data Memory
    WRITE_H1,         // Write h1 back to Data Memory
    WRITE_H2,         // Write h2 back to Data Memory
    WRITE_H3,         // Write h3 back to Data Memory
    WRITE_H4,         // Write h4 back to Data Memory
    WRITE_H5,         // Write h5 back to Data Memory
    WRITE_H6,         // Write h6 back to Data Memory
    WRITE_H7,         // Write h7 back to Data Memory

    WRITE_DONE_BIT    // Write the done bit to Data Memory
} state_t;

/// DUT
acc_control_unit
#(

)
DUT
(
    .clk(clk),
    .rst_n(rst_n),

    .mem_listen_en(mem_listen_en),
    .mem_listen_addr(mem_listen_addr),
    .mem_listen_data(mem_listen_data),

    .mem_acc_read_data(mem_acc_read_data),
    .mem_acc_read_data_valid(mem_acc_read_data_valid),

    .mem_acc_write_done(mem_acc_write_done),

    .cm_out(cm_out)
);

initial begin
    clk                     = 0;
    rst_n                   = 0;

    mem_listen_en           = 0;
    mem_listen_addr         = '0;
    mem_listen_data         = '0;

    mem_acc_read_data       = '0;
    mem_acc_read_data_valid = 0;

    mem_acc_write_done      = 0;
    cm_out                  =
