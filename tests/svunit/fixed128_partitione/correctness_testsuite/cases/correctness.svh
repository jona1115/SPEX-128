// Below code is either partially written by, or written with the aid of ChatGPT
`SVTEST(correctness_reset_state)
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid not 0 after reset")
  `FAIL_IF_LOG(s_o_exp_e !== '0,   ">>>>> o_exp_e not 0 after reset")
  `FAIL_IF_LOG(s_o_sanity_identifier !== 4'b0000, ">>>>> sanity id not 0 after reset")
  `FAIL_IF_LOG(s_o_error !== '0,   ">>>>> o_error not 0 after reset")
  `FAIL_IF_LOG(s_o_debug !== '0,   ">>>>> o_debug not 0 after reset")
`SVTEST_END

`SVTEST(correctness_single_pulse)
  logic [12:0] e = 13'h0123;
  drive(e, 1'b1);
  tick(); // registered BRAM + valid
  expect_now_valid_and_value(e, "single_pulse");

  drive('0, 1'b0);
  tick();
  expect_hold(gt_mem[e], "single_pulse_hold");
`SVTEST_END

`SVTEST(correctness_back_to_back)
  logic [12:0] vec[$] = '{13'd0, 13'd1, 13'd2, 13'd4095, 13'd4096, 13'd8191};
  foreach (vec[i]) begin
    drive(vec[i], 1'b1);
    tick();
    expect_now_valid_and_value(vec[i], $sformatf("bb[%0d]", i));
  end
  drive('0, 1'b0);
  tick();
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid should drop after burst")
`SVTEST_END

`SVTEST(correctness_bubble_and_hold)
  logic [12:0] d0 = 13'h0005;
  logic [12:0] d1 = 13'h03AA;
  drive(d0, 1'b1); tick(); expect_now_valid_and_value(d0, "bubble_d0");
  drive(d1, 1'b0); tick(); expect_hold(gt_mem[d0], "bubble_hold");
  drive(d1, 1'b1); tick(); expect_now_valid_and_value(d1, "bubble_d1");
  drive('0, 1'b0); tick();
`SVTEST_END

`SVTEST(correctness_random_20)
  int N = 20;
  for (int i = 0; i < N; i++) begin
    logic [12:0] e = $urandom_range(0, 8191);
    drive(e, 1'b1); tick(); expect_now_valid_and_value(e, $sformatf("rand[%0d]", i));
    drive('0, 1'b0); tick(); expect_hold(gt_mem[e], $sformatf("rand_hold[%0d]", i));
  end
`SVTEST_END

`SVTEST(correctness_sync_reset_midstream)
  logic [12:0] e  = 13'h07FF;
  logic [12:0] d2 = 13'h1A2B;

  drive(e, 1'b1); tick(); expect_now_valid_and_value(e, "pre_reset");

  s_i_reset = 1'b0;  drive('0, 1'b0); tick(); // sync reset tick
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid not 0 on sync reset")
  `FAIL_IF_LOG(s_o_exp_e !== '0,   ">>>>> o_exp_e not 0 on sync reset")

  s_i_reset = 1'b1;  tick(); // recover like setup()

  drive(d2, 1'b1); tick(); expect_now_valid_and_value(d2, "post_reset");
  drive('0, 1'b0); tick();
`SVTEST_END
