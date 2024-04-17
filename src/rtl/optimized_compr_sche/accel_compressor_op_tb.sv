module accel_compressor_tb ();

// Input and output signals
logic clk, rst_n;
wire [255:0] cm_out;
logic hash_done;
logic cm_init, cm_enable;
logic [1023:0] temp;
logic [511:0] m0_packed, m1_packed, m2_packed;
logic [31:0] m0_unpacked [0:15];
logic [31:0] m1_unpacked [0:15];
logic [31:0] m2_unpacked [0:15];
logic [31:0] sigma0, sigma1;
logic [31:0] w [0:63];
logic [31:0] w_in;
integer f1, f2;

// Define the block header class
class blk_hdr_t;
    rand bit [639:0] blk_hdr; // unpadded block header
endclass

// Create an instance of the block header class
blk_hdr_t new_blk = new();

// DUT
accel_compressor_op DUT(.cm_out(cm_out), .hash_done(hash_done), // output
                        .cm_init(cm_init), .cm_enable(cm_enable), .w(w_in), // input
                        .clk(clk), .rst_n(rst_n));

// Clock
initial clk = 0;
always
  #5 clk = ~clk;

// Test compressor
initial begin

    f1 = $fopen("hash_in.txt", "w");
    f2 = $fopen("simu_out_accel.txt", "w");

    // Test for 1000 blocks
    for (int k = 0; k < 1000; k++) begin
        rst_n = 0;
        cm_enable = 0;
        cm_init = 0;

        // Generate random block header
        if (new_blk.randomize() == 0)
            $display("failed to generate random number\n");

        // Pack the block header and add padding and length
        temp = {new_blk.blk_hdr, 1'b1, 319'b0, 64'b10_1000_0000};

        // Unpack the block header
        {m0_packed, m1_packed} = temp;
        unpack_m(m0_packed, m1_packed);

        // Print the block header
        print_blk_hdr();

        // Stage 1 hashing
        stage_hashing(m0_unpacked);

        // Stage 2 hashing
        stage_hashing(m1_unpacked);

        // Stage 3 hashing
        stage_3_hashing();

    end // end for

    $fclose(f1);
    $fclose(f2);
    $stop;
end

// Function to compute sigma0 and sigma1
function automatic logic [31:0] sigma (input logic [31:0] x, input int offset1, input int offset2, input int offset3);
    return {x[offset1:0], x[31:offset1+1]} ^ {x[offset2:0], x[31:offset2+1]} ^ {offset3, x[31:offset3+1]};
endfunction

// Function to print the block header and hash value
task automatic print_blk_hdr;
    $fwrite(f1, "%h\n", new_blk.blk_hdr);
    $display("raw block header = %h\n", new_blk.blk_hdr);
    $display("padded block header = %h\n", temp);
endtask

// Task to compute the stage hashing
task automatic stage_hashing (input logic [31:0] m_unpacked [0:15]);

    // Compute w_i
    for (int i = 0; i < 64; i++) begin
        if (i < 16)
            w[i] = m_unpacked[i];
        else begin
            sigma0 = sigma(w[i-15], 6, 17, 3);
            sigma1 = sigma(w[i-2], 16, 18, 10);
            w[i] = sigma0 + w[i-7] + sigma1 + w[i-16];
        end
    end

    // Initialize the compressor
    cm_init = 1;
    @(posedge clk);
    cm_init = 0;

    // Enable the compressor
    cm_enable = 1;
    @(posedge clk);

    // Compute the hash
    for (int i = 0; i < 64; i++) begin
        w_in = w[i];
        @(posedge clk);
    end

    // Wait for the hash to be computed
    @(posedge clk);
    @(posedge clk);

    // Print the hash value
    $display("stage %d hash = %h\n", k+1, cm_out);

endtask

// Task to compute stage 3 hashing
task automatic stage_3_hashing;

    // Pack the stage 2 hash and add padding and length
    m2_packed = {cm_out, 1'b1, 191'b0, 64'b1_0000_0000};

    // Unpack the stage 2 hash
    m2_unpacked = {>> 32 {m2_packed}};

