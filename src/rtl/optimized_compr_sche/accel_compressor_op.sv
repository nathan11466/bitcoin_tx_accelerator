module accel_compressor_op (
    cm_out,
    update_A_H, update_H0_7,
    rst_hash_n, is_hashing,
    w, i, 
    clk, rst_n
);

input update_A_H, update_H0_7;
input rst_hash_n;
input is_hashing;
input [31:0] w;
input [6:0] i;
input clk, rst_n;

output [255:0] cm_out;

parameter CONSTANTS = {32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
                      32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
                      32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
                      32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
                      32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
                      32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
                      32'h983e5152, 3
