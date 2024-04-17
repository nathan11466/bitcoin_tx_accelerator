module accel_compressor_tb ();

  // Inputs
  logic clk, rst_n;
  output wire [255:0] cm_out;
  output wire hash_done;
  input wire cm_init, cm_enable;
  input wire [1023:0] temp;
  input wire [511:0] m0_packed, m1_packed, m2_packed;
  input wire [31:0] m0_unpacked [0:15];
  input wire [31:0] m1_unpacked [0:15];
  input wire [31:0] m2_unpacked [0:15];
  input wire [31:0] sigma0, sigma1;
  input wire [31:0] w [0:63];
  input wire [31:0] w_in;

  // Class for block header
  class blk_hdr_t;
    rand bit [639:0] blk_hdr; // unpadded block header
  endclass

  // Instantiate DUT
  accel_compressor DUT (
    .cm_out(cm_out),
    .hash_done(hash_done),
    .cm_init(cm_init),
    .cm_enable(cm_enable),
    .w(w_in),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test function
  function automatic void run_test (input wire [31:0] input_data);
    // Generate block header
    blk_hdr_t new_blk = new();
    if (new_blk.randomize() == 0) begin
      $display("failed to generate random number\n");
    end
    // 1024 = 640(msg.) + 320(padding) + 64(length)
    // msg. length = 640; randomly generated
    temp = generate_block_header(new_blk.blk_hdr);
    // Display raw and padded block header
    $display("raw block header = %h\n", new_blk.blk_hdr);
    $display("padded block header = %h\n", temp);

    // Initialize variables
    m0_packed = temp[1023:512];
    m1_packed = temp[511:0];
    m0_unpacked = {>> 32 {m0_packed}};
    m1_unpacked = {>> 32 {m1_packed}};

    // Compute w values
    compute_w(m0_unpacked, m1_unpacked, w);

    // Perform hashing
    hash(w, cm_out, hash_done);

    // Display hash value
    $display("hash = %h\n", cm_out);
  endfunction

  // Generate block header
  function automatic [1023:0] generate_block_header (input [639:0] blk_hdr);
    // Add padding and length
    return {blk_hdr, 1'b1, 319'b0, 64'b10_1000_0000};
  endfunction

  // Compute sigma0 and sigma1 values
  function automatic [31:0] compute_sigma0_sigma1 (input [31:0] w_i_minus_15,
