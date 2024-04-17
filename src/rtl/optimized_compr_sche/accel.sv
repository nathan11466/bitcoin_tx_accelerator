module accel(
    input wire clk, rst_n,
    input wire [15:0] mem_listen_addr, mem_listen_en,
    input wire [31:0] mem_listen_data,
    input wire [511:0] mem_acc_read_data, mem_acc_read_data_valid, mem_acc_write_done,
    output wire [15:0] mem_acc_read_addr, mem_acc_read_en, mem_acc_write_en,
    output wire [31:0] mem_acc_write_data, mem_acc_write_addr,
    output wire hash_done,
    output wire [255:0] hash
);

// ... (other code here)

acc_control_unit #() ctrl0 (
    .clk(clk), .rst_n(rst_n),
    .mem_listen_addr(mem_listen_addr), .mem_listen_en(mem_listen_en),
    .mem_listen_data(mem_listen_data),
    .mem_acc_read_data(mem_acc_read_data),
    .mem_acc_read_data_valid(mem_acc_read_data_valid),
    .mem_acc_write_done(mem_acc_write_done),
    .cm_out(hash),
    .mem_acc_read_addr(mem_acc_read_addr),
    .mem_acc_read_en(mem_acc_read_en),
    .mem_acc_write_en(mem_acc_write_en),
    .mem_acc_write_data(mem_acc_write_data),
    .mem_acc_write_addr(mem_acc_write_addr),
    .ms_init(ms_init),
    .ms_enable(ms_enable),
    .cm_is_hashing(cm_is_hashing),
    .cm_update_A_H(cm_update_A_H),
    .cm_update_H0_7(cm_update_H0_7),
    .cm_rst_hash_n(cm_rst_hash_n),
    .cm_cycle_count(cm_cycle_count),
    .should_save_hash(should_save_hash),
    .msg_sel(msg_sel),
    .hash_done(hash_done)
);

accel_compressor_op compr0 (
    .cm_out(hash),
    .update_A_H(cm_update_A_H), .update_H0_7(cm_update_H0_7),
    .rst_hash_n(cm_rst_hash_n), .is_hashing(cm_is_hashing), .i(cm_cycle_count),
    .w(w), .clk(clk), .rst_n(rst_n)
);

acc_message_scheduler_op sche0 (
    .message(message), .ms_r0_out(w),
    .ms_init(ms_init), .ms_enable(ms_enable),
    .clk(clk), .rst_n(rst_n)
);

// intermediate hash register
always_ff @(posedge clk) begin
    if (!rst_n)
        intermediate_hash <= 0;
    else if (should_save_hash)
        intermediate_hash <= hash;
end

// next message to be expanded
// 2'b0x: message from data memory
// 2'b1x: saved hash
assign message = (msg_sel[1] == 0) ? mem_acc_read_data : {intermediate_hash, 1'b1, 191'b0, 64'b1_0000_0000};

endmodule
