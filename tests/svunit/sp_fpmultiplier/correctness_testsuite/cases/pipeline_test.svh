`SVTEST(pipeline_test_consec)
  logic [127:0] expected_0 = 128'h4000c000000000000000000000000000; // 3.5
  logic [127:0] expected_1 = {64'h410465776e87a276/*167086.928970*/,
                              64'hc0500719616462c5/*-64.110924*/};
  logic [127:0] expected_2 = {32'hc91c8554/*-641109.250000*/,
                              32'h80000000/*-0.000000*/,
                              32'h40d27ef9/*6.578000*/,
                              32'h410894e1/*8.536347*/};

  @(negedge s_i_clk);

  $display(">>>>> [%0t] Injecting first input", $time);
  s_i_in_anikin = 128'h3ffe0000000000000000000000000000; // 0.5
  s_i_in_force  = 128'h4001c000000000000000000000000000; // 7.0
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_valid128_anikin = '1;
  s_i_valid128_force  = '1;
  s_i_valid64a_anikin = '0;
  s_i_valid64a_force  = '0;
  s_i_valid64b_anikin = '0;
  s_i_valid64b_force  = '0;
  s_i_valid32a_anikin = '0;
  s_i_valid32a_force  = '0;
  s_i_valid32b_anikin = '0;
  s_i_valid32b_force  = '0;
  s_i_valid32c_anikin = '0;
  s_i_valid32c_force  = '0;
  s_i_valid32d_anikin = '0;
  s_i_valid32d_force  = '0;

  wait_n_ticks(1);

  $display(">>>>> [%0t] Injecting second input", $time);
  s_i_in_anikin = {64'h402b1182a9930be1/*13.534200*/,
                   64'hbed5c7f0f883bd6d/*-0.000005*/};
  s_i_in_force  = {64'h40c81cc460aa64c3/*12345.534200*/,
                   64'h41678c2560000000/*12345643.000000*/};
  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);
  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;
  s_i_valid64a_anikin = '1;
  s_i_valid64a_force  = '1;
  s_i_valid64b_anikin = '1;
  s_i_valid64b_force  = '1;
  s_i_valid32a_anikin = '0;
  s_i_valid32a_force  = '0;
  s_i_valid32b_anikin = '0;
  s_i_valid32b_force  = '0;
  s_i_valid32c_anikin = '0;
  s_i_valid32c_force  = '0;
  s_i_valid32d_anikin = '0;
  s_i_valid32d_force  = '0;

  wait_n_ticks(1);

  $display(">>>>> [%0t] Injecting third input", $time);
  s_i_in_anikin = {32'hbd54b48d/*-0.051930*/,
                   32'h4b3c612b/*12345643.000000*/,
                   32'h4121eb85/*10.120000*/,
                   32'h40490e56/*3.141500*/};
  s_i_in_force  = {32'h4b3c612b/*12345643.000000*/,
                   32'h80000000/*-0.000000*/,
                   32'h3f266666/*0.650000*/,
                   32'h402de7fb/*2.717284*/};
  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;
  s_i_valid64a_anikin = '0;
  s_i_valid64a_force  = '0;
  s_i_valid64b_anikin = '0;
  s_i_valid64b_force  = '0;
  s_i_valid32a_anikin = '1;
  s_i_valid32a_force  = '1;
  s_i_valid32b_anikin = '1;
  s_i_valid32b_force  = '1;
  s_i_valid32c_anikin = '1;
  s_i_valid32c_force  = '1;
  s_i_valid32d_anikin = '1;
  s_i_valid32d_force  = '1;

  @(negedge s_i_clk);

  // Turn off s_fire
  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;
  s_i_valid64a_anikin = '0;
  s_i_valid64a_force  = '0;
  s_i_valid64b_anikin = '0;
  s_i_valid64b_force  = '0;
  s_i_valid32a_anikin = '0;
  s_i_valid32a_force  = '0;
  s_i_valid32b_anikin = '0;
  s_i_valid32b_force  = '0;
  s_i_valid32c_anikin = '0;
  s_i_valid32c_force  = '0;
  s_i_valid32d_anikin = '0;
  s_i_valid32d_force  = '0;

  wait_n_ticks(`LATENCY - 3);

  $display(">>>>> [%0t] Reading first input result: s_o_out_jedi=%x", $time, s_o_out_jedi);
  `FAIL_UNLESS(s_o_out_jedi === expected_0)
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid64a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32c_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32d_jedi === 1'b0)

  wait_n_ticks(1);

  $display(">>>>> [%0t] Reading second input result: s_o_out_jedi=%x", $time, s_o_out_jedi);
  `FAIL_UNLESS(s_o_out_jedi === expected_1)
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64a_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid64b_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid32a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32c_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32d_jedi === 1'b0)

  wait_n_ticks(1);

  $display(">>>>> [%0t] Reading third input result", $time);
  `FAIL_UNLESS(s_o_out_jedi === expected_2)
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32a_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid32b_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid32c_jedi === 1'b1)
  `FAIL_UNLESS(s_o_valid32d_jedi === 1'b1)

  wait_n_ticks(1);
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid64b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32a_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32b_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32c_jedi === 1'b0)
  `FAIL_UNLESS(s_o_valid32d_jedi === 1'b0)
`SVTEST_END


`SVTEST(pipeline_test_bubbling)
  logic [127:0] expected_0 = 128'h4000c000000000000000000000000000; // 3.5
  logic [127:0] expected_1 = 128'hc0076ee894ea7ad6392654fa263a57be; // -366.90852227686830087000000000000000737

  @(negedge s_i_clk);

  $display(">>>>> [%0t] Injecting first input", $time);
  s_i_in_anikin = 128'h3ffe0000000000000000000000000000; // 0.5
  s_i_in_force  = 128'h4001c000000000000000000000000000; // 7.0
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_valid128_anikin = '1;
  s_i_valid128_force  = '1;

  wait_n_ticks(1);

  $display(">>>>> [%0t] Injecting bubble", $time);
  s_i_in_anikin = 128'hbff7316088898481372ac2290d730dc7; // -0.0046596844999999999999999999999999997928
  s_i_in_force  = 128'h400f339510c28a7e9e96838f970c4b93; // 78741.065468460000000000000000000002343
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;

  wait_n_ticks(1);

  $display(">>>>> [%0t] Injecting second input", $time);
  s_i_in_anikin = 128'hbff7316088898481372ac2290d730dc7; // -0.0046596844999999999999999999999999997928
  s_i_in_force  = 128'h400f339510c28a7e9e96838f970c4b93; // 78741.065468460000000000000000000002343
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_valid128_anikin = '1;
  s_i_valid128_force  = '1;

  @(negedge s_i_clk);

  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;

  wait_n_ticks(`LATENCY - 3);

  $display(">>>>> [%0t] Reading first input result", $time);
  `FAIL_UNLESS(s_o_out_jedi === expected_0)
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b1)

  wait_n_ticks(1);

  $display(">>>>> [%0t] Reading bubble input result", $time);
  // `FAIL_UNLESS(s_o_out_jedi === expected_1) // doesnt matter
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b0)

  wait_n_ticks(1);

  $display(">>>>> [%0t] Reading second input result", $time);
  `FAIL_UNLESS(s_o_out_jedi === expected_1)
  `FAIL_UNLESS(s_o_valid128_jedi === 1'b1)
`SVTEST_END