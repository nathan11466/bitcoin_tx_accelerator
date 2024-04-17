module acc_message_scheduler_op_tb ();

  logic clk, rst_n;
  logic ms_init, ms_enable;
  logic [511:0] message;
  logic [31:0] ms_r0_out;
  logic [31:0] w [0:63];
  logic [31:0] sigma0, sigma1;
  logic [31:0] msg_unpacked [0:15];

  class msg_t;
    rand logic [511:0] msg;
  endclass

  msg_t new_msg;

  // DUT
  acc_message_scheduler_op DUT(.clk(clk), .rst_n(rst_n),
                               .ms_init(ms_init), .ms_enable(ms_enable), .message(message),
                               .ms_r0_out(ms_r0_out));

  // clock
  always #5 clk = ~clk;

  // test message scheduler
  initial begin
    clk = 0;
    new_msg = new();

    for (int k = 0; k < 100; k++) begin

      rst_n = 0;
      ms_enable = 0;
      ms_init = 0;

      if (new_msg.randomize() == 0)
        $display("failed to generate random number\n");

      message = new_msg.msg;
      msg_unpacked = { >> 32 {new_msg.msg} }; // unpack msg

      // compute w
      for (int i = 0; i < 64; i++) begin
        if (i < 16)
          w[i] = msg_unpacked[i];
        else begin
          // sigma0 = ROTR7(x) XOR ROTR18(x) XOR [Logic]SHR3(x)
          sigma0 = {w[i-15][6:0], w[i-15][31:7]} ^ {w[i-15][17:0], w[i-15][31:18]} ^ {3'b0, w[i-15][31:3]};
          // sigma1 = ROTR17(x) XOR ROTR19(x) XOR [Logic]SHR10(x)
          sigma1 = {w[i-2][16:0], w[i-2][31:17]} ^ {w[i-2][18:0], w[i-2][31:19]} ^ {10'b0, w[i-2][31:10]};
          w[i] = sigma0 + w[i-7] + sigma1 + w[i-16];
        end
      end

      // reset and initialize
      rst_n = 1;
      @(posedge clk);
      ms_init = 1;
      @(posedge clk); // initialize
      ms_init = 0;

      // check output
      for (int j = 0; j < 64; j++) begin
        if (ms_r0_out != w[j])
          $display("[F
