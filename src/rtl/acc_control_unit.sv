///////////////////////////////////////////////////////////////////////////////
// Accelerator Control Unit
//
// This module is the brain of the Accelerator. It orchestrates the hashing
// operation within the block.
//
// Parameters:
// - MEM_LISTEN_ADDR_SIZE: width of the CPU Data Memory address line
// - MEM_LISTEN_DATA_SIZE: width of the CPU Data Memory data line
// - MEM_ACC_READ_ADDR_SIZE: width of the Accelerator Data Memory address line
// - MEM_ACC_READ_DATA_SIZE: width of the Accelerator Data Memory data line
// - MEM_ACC_WRITE_ADDR_SIZE: width of the Accelerator Data Memory address line
//   for write operations
// - MEM_ACC_WRITE_DATA_SIZE: width of the Accelerator Data Memory data line
//   for write operations
// - HCB_START_ADDR: starting address of the Host Communication Block in Data Memory
// - HCB_MSG_OFFSET: offset of the message in the Host Communication Block
// - ACB_START_ADDR: starting address of the Accelerator Communication Block in Data Memory
// - ACB_H0_OFFSET: offset of h0 in the Accelerator Communication Block
// - IS_WRITE_BUSY_BIT: set to write the Busy bit in the Status register
// - IS_MEM_USE_ARBITER: set to indicate there is an Arbiter before we touch the Memory
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_control_unit
#(
    // Parameters
    parameter MEM_LISTEN_ADDR_SIZE      = 16,
    parameter MEM_LISTEN_DATA_SIZE      = 32,
    parameter MEM_ACC_READ_ADDR_SIZE    = 16,
    parameter MEM_ACC_READ_DATA_SIZE    = 512,
    parameter MEM_ACC_WRITE_ADDR_SIZE   = 16,
    parameter MEM_ACC_WRITE_DATA_SIZE   = 32,
    parameter HCB_START_ADDR            = 16'h1000,
    parameter HCB_MSG_OFFSET            = 16'h0008,
    parameter ACB_START_ADDR            = 16'h5000,
    parameter ACB_H0_OFFSET             = 16'h0008,
    parameter IS_WRITE_BUSY_BIT         = 1,
    parameter IS_MEM_USE_ARBITER        = 1,
    // Hash result width
    parameter HASH_RESULT_LENGTH        = 256
)
(
    clk, rst_n,

    // Inputs
    // CPU Data Memory monitoring
    mem_listen_addr, mem_listen_en, mem_listen_data,

    // Accelerator Data Memory lines
    mem_acc_read_data, mem_acc_read_data_valid,
    mem_acc_write_done,

    // Outputs
    // Accelerator memory read request to Data Memory
    mem_acc_read_addr, mem_acc_read_en,

    // Accelerator Data Memory write lines
    mem_acc_write_en, mem_acc_write_addr, mem_acc_write_data,

    // Message Scheduler and Compressor controls
    ms_init, ms_enable,
    cm_init, cm_enable
);

// Total cycles needed to complete one hash, counting from when we assert *_enable
localparam HASH_CYCLE_COUNT          = 64;

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

 input                                              mem_acc_read_data_valid;
 input              [MEM_ACC_READ_DATA_SIZE - 1:0]  mem_acc_read_data;

 input                                              mem_acc_write_done;

 // Message Scheduler and Compressor controls
 output      reg                                     ms_init, ms_enable;
 output      reg                                     cm_init, cm_enable;

 // Accelerator memory read request to Data Memory
 output      reg                                     mem_acc_read_en;
 output      reg    [MEM_ACC_READ_ADDR_SIZE - 1:0]  mem_acc_read_addr;

 // Accelerator Data Memory write lines
 output      reg                                     mem_acc_write_en;
 output      reg    [MEM_ACC_WRITE_ADDR_SIZE - 1:0]  mem_acc_write_addr;
 output      reg    [MEM_ACC_WRITE_
