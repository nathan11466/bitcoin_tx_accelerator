/////////////////////////////////////////////////////////////////////////////// Accelerator Control Unit
//
// This module is the brain of the Accelerator. It orchestrates the hashing
// operation and communication with the host within the block.
//
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_control_unit
#(
    // CPU address line redirected from Data Memory for monitoring MMIO
    parameter MEM_LISTEN_ADDR_SIZE      = 16,
    // CPU data line redirected from Data Memory for monitoring MMIO
    parameter MEM_LISTEN_DATA_SIZE      = 32,

    // Address line going back to the Data Memory
    parameter MEM_ACC_READ_ADDR_SIZE    = 16,
    // Data line coming from the Data Memory
    parameter MEM_ACC_READ_DATA_SIZE    = 512,

    // Address line going out from the Accelerator to the Data Memory
    parameter MEM_ACC_WRITE_ADDR_SIZE   = 16,
    // Data line going out from the Accelerator to the Data Memory
    parameter MEM_ACC_WRITE_DATA_SIZE   = 32,

    // Starting address of the Host Communication Block in Data Memory
    parameter HCB_START_ADDR            = 16'h1000,
    // Offset of the Message from HCB starting address
    parameter HCB_MSG_OFFSET            = 16'h0008,
    // Starting address of the Accelerator Communication Block in Data Memory
    parameter ACB_START_ADDR            = 16'h5000,
    // Offset of h0 from ACB starting address
    parameter ACB_H0_OFFSET             = 16'h0008,

    // Set to write the Busy bit in the Status register
    parameter IS_WRITE_BUSY_BIT         = 1,

    // Set to indicate there is an Arbiter before we touch the Memory
    parameter IS_MEM_USE_ARBITER        = 1
)
(
    clk, rst_n,

    /// Input
    // CPU Data Memory monitoring
    mem_listen_addr, mem_listen_en, mem_listen_data,

    // Accelerator Data Memory line
    mem_acc_read_data,
    // Asserted by Arbiter when the Arbiter grants us our read access
    mem_acc_read_data_valid,

    // Asserted by Arbiter has written our data to the Memory
    mem_acc_write_done,

    // Output from the Compressor
    cm_out,

    /// Output
    // Accelerator memory read request to Data Memory
    mem_acc_read_addr, mem_acc_read_en,

    // Accelerator Data Memory write lines
    mem_acc_write_en, mem_acc_write_addr, mem_acc_write_data,

    // Message Scheduler initialization and enable signal
    ms_init, ms_enable,

    // Compressor signals
    cm_is_hashing, cm_update_A_H, cm_update_H0_7,
    cm_rst_hash_n, cm_cycle_count,

    // Save intermediate hashes
    hash_done,

    // Message select
    msg_sel,

    // Signals all three stages of hashing is done
    hash_completed
);

// Total cycles needed to complete one hash, counting from when we assert *_enable
localparam HASH_CYCLE_COUNT          = 64;

// Width of the resulting hash
localparam HASH_RESULT_LENGTH        = 256;

// Cycles needed to write the entire hash result
localparam HASH_WRITE_CYCLE          = HASH_RESULT_LENGTH / MEM_ACC_WRITE_DATA_SIZE;

// Address of h0 in ACB
localparam ACB_H0_ADDR               = ACB_START_ADDR + ACB_H0_OFFSET;

// Address of the message in HCB
localparam HCB_MSG_ADDR              = HCB_START_ADDR + HCB_MSG_OFFSET;

// ===============
/// I/O
// ===============
 input                                              clk, rst_n;

 input                [MEM_LISTEN_ADDR_SIZE - 1:0]  mem_listen_addr;
 input                                              mem_listen_en;
 input                [MEM_LISTEN_DATA_SIZE - 1:0]  mem_listen_data;

 input                                
