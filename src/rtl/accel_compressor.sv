module accel_compressor (
    input cm_init,
    input cm_enable,
    input [31:0] w,
    input clk, rst_n,
    output reg hash_done,
    output [255:0] cm_out
);

parameter NUM_ROUNDS = 64;

typedef struct {
    logic [31:0] A, B, C, D, E, F, G, H;
    logic [31:0] A_next, B_next, C_next, D_next, E_next, F_next, G_next, H_next;
    logic [31:0] T1, T2, Maj_ABC, Ch_EFG, Sigma0_A, Sigma1_E;
} sha256_signals;

logic [31:0] k [0:NUM_ROUNDS-1]; // constants
logic [31:0] hash_init [0:7]; // initial hash values
logic [31:0] hash [0:7]; // hash values
logic [6:0] i; // counter

sha256_signals sig;

// SHA-256 signals
always_comb begin
    sig.Maj_ABC = (sig.A & sig.B) ^ (sig.B & sig.C) ^ (sig.C & sig.A);
    sig.Ch_EFG = (sig.E & sig.F) ^ ((~sig.E) & sig.G);
    sig.Sigma0_A = rotr(sig.A, 2) ^ rotr(sig.A, 13) ^ rotr(sig.A, 22);
    sig.Sigma1_E = rotr(sig.E, 6) ^ rotr(sig.E, 11) ^ rotr(sig.E, 25);
end

// state machine
typedef enum logic [2:0] {IDLE, INIT, UPD1, HASH, UPD2, DONE} state_t;
state_t state, next_state;
logic update_A_H, update_H0_7;
logic rst_i_n, rst_hash_n;
logic is_hashing;
logic done;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        i <= 0;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin
    rst_i_n = 1;
    rst_hash_n = 1;
    is_hashing = 0;
    hash_done = 0;
    update_A_H = 0;
    update_H0_7 = 0;

    case (state)
        IDLE: begin
            rst_i_n = 0;
            if (cm_init)
                next_state = INIT;
            else if (cm_enable)
                next_state = UPD1;
        end

        INIT: begin
            rst_hash_n = 0;
            if (cm_enable)
                next_state = UPD1;
            else
                next_state = INIT;
        end

        UPD1: begin
            update_A_H = 1;
            next_state = HASH;
        end

        HASH: begin
            if (i == NUM_ROUNDS)
                next_state = UPD2;
            else
                next_state = HASH;
        end

        UPD2: begin
            update_H0_7 = 1;
            next_state = DONE;
        end

        DONE: begin
            hash_done = 1;
            next_state = IDLE;
        end
    endcase
end

// SHA-256 registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        sig.A <= 0;
        sig.B <= 0;
        sig.C <= 0;
        sig.D <= 0;
        sig.E <= 0;
        sig.F <= 0;
        sig.G <= 0;
        sig.H <= 0;
    end
    else begin
        sig.A <= sig.A_next;
        sig.B <= sig.B_next;
        sig.C <= sig.C_next;
        sig.D <= sig.D_next;
        sig.E <= sig.E_next;
        sig.F <= sig.F_next;
        sig.G <= sig.G_next;
        sig.H <= sig.H_next;
    end
end

// hash values
always_ff @(posedge clk) begin
    if (!rst_n)
        hash <= { >> {0}};
    else if (!rst_hash_n)
        hash <= hash_init;
    else if (update_H0_7)
        hash <= hash + sig.A + sig.B + sig.C + sig.D + sig.E + sig.F + sig.G + sig.H;
end

// hashing counter
always_ff @(posedge clk) begin
    if (!rst_n)
        i <= 0;
    else if (!rst_i_n)
        i <= 0;
    else if(is_hashing)
        i <= i + 1;
end

//
