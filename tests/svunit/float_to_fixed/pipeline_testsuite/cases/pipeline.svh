// Pipeline behavior tests
// Goal:
// 1) Back-to-back valid inputs must produce back-to-back valid outputs.
// 2) A bubble in i_valid must propagate as a bubble in o_valid.

`SVTEST(pipeline_back_to_back_valid_outputs_no_bubbles_0)
  logic seen_first_valid;
  logic [127:0] expected_0;
  logic [127:0] expected_1;
  logic [127:0] expected_2;

  expected_0 = 128'h578F1DCC630B745164F272B433528000; // 128'b0_1010111100_011110001110111001100011000110000101101110100010100010110010011110010011100101011010000110011010100101000000000000000;
  expected_1 = {64'h6487EE0B0AF5FC, 64'h56FC2656ABDE40}; // {64'b0_0000000011_00100100001111110111000001011000010101111010111111100, 64'b0_0000000010_10110111111000010011001010110101010111101111001000000};
  expected_2 = {32'h6487EC, 32'h8056FC26, 32'h3E915C00, 32'h5F}; // {32'b0_0000000011_001001000011111101100, 32'b1_0000000010_101101111110000100110, 32'b0_0111110100_100010101110000000000, 32'b0_0000000000_000000000000001011111};

  // Baseline
  s_i_valid = 1'b0;
  s_i_ctrl  = '0;
  s_i_float = '0;
  wait_n_ticks(1);
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b0)

  // Launch 3 transactions on 3 consecutive cycles.
  @(negedge s_i_clk);
  s_i_valid = 1'b1;
  s_i_ctrl  = 4'b0000;
  s_i_float = 128'b0_100000000001000_0101111000111100011101110011000110001100001011011101000101000101100100111100100111001010110100001100110101001010;

  @(posedge s_i_clk); @(negedge s_i_clk);

  s_i_valid = 1'b1;
  s_i_ctrl  = 4'b0001;
  s_i_float = {64'b0_10000000000_1001001000011111101110000010110000101011110101111111, 64'b0_10000000000_0101101111110000100110010101101010101111011110010000};

  @(posedge s_i_clk); @(negedge s_i_clk);

  s_i_valid = 1'b1;
  s_i_ctrl  = 4'b0010;
  s_i_float = {32'b0_10000000_10010010000111111011011, 32'b1_10000000_01011011111100001001101, 32'b0_10000111_11110100100010101110010, 32'b0_01110000_01111110100001010100001};

  `FAIL_UNLESS_EQUAL(s_o_fixed, expected_0)

  @(posedge s_i_clk); @(negedge s_i_clk);

  s_i_valid = 1'b0;
  s_i_ctrl  = '0;
  s_i_float = '0;

  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  `FAIL_UNLESS_EQUAL(s_o_fixed, expected_1)

  @(posedge s_i_clk); @(negedge s_i_clk);
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  `FAIL_UNLESS_EQUAL(s_o_fixed, expected_2)

  @(posedge s_i_clk); @(negedge s_i_clk);
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b0)
`SVTEST_END

`SVTEST(pipeline_bubble_in_valid_propagates_to_output_0)
  logic seen_first_valid;
  logic [127:0] expected_0;
  logic [127:0] expected_1;

  expected_0 = 128'b1_0000000101_111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
  expected_1 = {64'b0_0000000011_00100100001111110111000001011000010101111010111111100, 64'b0_0000000010_10110111111000010011001010110101010111101111001000000};

  // Baseline
  s_i_valid = 1'b0;
  s_i_ctrl  = '0;
  s_i_float = '0;
  wait_n_ticks(1);

  // Send: VALID, BUBBLE, VALID
  @(negedge s_i_clk);
  s_i_valid = 1'b1;
  s_i_ctrl  = 4'b0000;
  s_i_float = 128'b1_100000000000001_0111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

  @(posedge s_i_clk); @(negedge s_i_clk);
  s_i_valid = 1'b0; // bubble
  s_i_ctrl  = '0;
  s_i_float = '0;

  @(posedge s_i_clk); @(negedge s_i_clk);
  s_i_valid = 1'b1;
  s_i_ctrl  = 4'b0001;
  s_i_float = {64'b0_10000000000_1001001000011111101110000010110000101011110101111111, 64'b0_10000000000_0101101111110000100110010101101010101111011110010000};

  `FAIL_UNLESS_EQUAL(s_o_fixed, expected_0)

  @(posedge s_i_clk); @(negedge s_i_clk);
  s_i_valid = 1'b0;
  s_i_ctrl  = '0;
  s_i_float = '0;

  // Bubble must appear between outputs.
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b0)

  @(posedge s_i_clk); @(negedge s_i_clk);
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  `FAIL_UNLESS_EQUAL(s_o_fixed, expected_1)

  @(posedge s_i_clk); @(negedge s_i_clk);
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b0)
`SVTEST_END
