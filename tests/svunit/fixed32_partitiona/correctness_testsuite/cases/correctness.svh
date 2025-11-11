// Below code is either partially written by, or written with the aid of ChatGPT
`SVTEST(correctness_reset_state)
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid not 0 after reset")
  `FAIL_IF_LOG(s_o_exp_a !== '0,   ">>>>> o_exp_a not 0 after reset")
  `FAIL_IF_LOG(s_o_sanity_identifier !== 4'b0000, ">>>>> sanity id not 0 after reset")
  `FAIL_IF_LOG(s_o_error !== '0,   ">>>>> o_error not 0 after reset")
  `FAIL_IF_LOG(s_o_debug !== '0,   ">>>>> o_debug not 0 after reset")
`SVTEST_END

`SVTEST(correctness_single_pulse)
  logic [10:0] a = 13'h0123;
  drive(a, 1'b1);
  tick(); // registered BRAM + valid
  expect_now_valid_and_value(a, "single_pulse");

  drive('0, 1'b0);
  tick();
  expect_hold(gt_mempos[a], "single_pulse_hold");
`SVTEST_END

`SVTEST(correctness_back_to_back)
  logic [10:0] vec[$] = '{11'd0, 11'd1, 11'd2, 11'h345, 11'h028, 11'h1F8};
  foreach (vec[i]) begin
    drive(vec[i], 1'b1);
    tick();
    expect_now_valid_and_value(vec[i], $sformatf("bb[%0d]", i));
  end
  drive('0, 1'b0);
  tick();
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid should drop after burst")
`SVTEST_END

/**
 * expect_hold(exp, tag) checks the “bubble” behavior: when i_valid=0, the DUT must not 
 * produce a new sample. So it asserts two things in that cycle:
 * 1. o_valid==0 (we are not claiming the output is fresh)
 * 2. o_exp_d is unchanged (still equals the last good value exp)
 * 
 * This guards against accidental free-running reads or unintended updates when upstream 
 * isn’t presenting a valid request.
 * 
 * correctness_bubble_and_hold forces exactly that scenario. It sends a good request (d0) 
 * to create a known last value, inserts a bubble (i_valid=0) while deliberately changing 
 * the address to a different value (d1), and confirms the output stays put and o_valid 
 * drops to 0. Then it re-asserts i_valid=1 with d1 and checks the new value appears.
 */
`SVTEST(correctness_bubble_and_hold_positive)
  logic [10:0] d0 = 11'h005;
  logic [10:0] d1 = 11'b111_1010_1010;
  drive(d0, 1'b1); tick(); expect_now_valid_and_value(d0, "bubble_d0 pos");
  // $display("+++++ s_o_exp_a=0x%x", s_o_exp_a);
  drive(d1, 1'b0); tick(); expect_hold(gt_mempos[d0[9:0]], "bubble_hold positive");
  drive(d1, 1'b1); tick(); expect_now_valid_and_value(d1, "bubble_d1 pos");
  // drive(d1, 1'b1); tick();
  // $display("+++++ s_o_exp_a=0x%x", s_o_exp_a);
  // expect_now_valid_and_value(d1, "bubble_d1 pos");
  drive('0, 1'b0); tick();
`SVTEST_END
`SVTEST(correctness_bubble_and_hold_negative)
  logic [10:0] d0 = 11'b111_1010_1010;
  logic [10:0] d1 = 11'h005;
  drive(d0, 1'b1); tick(); expect_now_valid_and_value(d0, "bubble_d0 neg");
  drive(d1, 1'b0); tick(); expect_hold(gt_memneg[d0[9:0]], "bubble_hold negative");
  drive(d1, 1'b1); tick(); expect_now_valid_and_value(d1, "bubble_d1 neg");
  drive('0, 1'b0); tick();
`SVTEST_END

`SVTEST(correctness_random_20)
  int N = 20;
  for (int i = 0; i < N; i++) begin
    logic [10:0] a = $urandom_range(0, 2047);
    drive(a, 1'b1); tick(); expect_now_valid_and_value(a, $sformatf("rand[%0d]", i));
    drive('0, 1'b0); tick(); expect_hold((a[10]==1'b0)?gt_mempos[a[9:0]]:gt_memneg[a[9:0]], 
                                          $sformatf("rand_hold[%0d]", i));
  end
`SVTEST_END

`SVTEST(correctness_sync_reset_midstream)
  logic [10:0] a  = 11'h7FF;
  logic [10:0] d2 = 11'hA2B;

  drive(a, 1'b1); tick(); expect_now_valid_and_value(a, "pre_reset");

  s_i_rst_n = 1'b0;  drive('0, 1'b0); tick(); // sync reset tick
  `FAIL_IF_LOG(s_o_valid !== 1'b0, ">>>>> o_valid not 0 on sync reset")
  `FAIL_IF_LOG(s_o_exp_a !== '0,   ">>>>> o_exp_a not 0 on sync reset")

  s_i_rst_n = 1'b1;  tick(); // recover like setup()

  drive(d2, 1'b1); tick(); expect_now_valid_and_value(d2, "post_reset");
  drive('0, 1'b0); tick();
`SVTEST_END
