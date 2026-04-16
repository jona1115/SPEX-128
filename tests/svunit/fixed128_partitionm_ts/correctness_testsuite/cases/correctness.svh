`SVTEST(correctness_0)
  s_i_m = '0;

  wait_n_ticks(my_fixed128_partitionm_ts.MODULE_LATENCY);
  `FAIL_UNLESS_EQUAL(s_o_exp_m, {1'b0, 15'd16383, 57'b0, 55'b0})
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
`SVTEST_END

`SVTEST(correctness_edge_cases_0)

  // Create List of edge cases
  bit [59:0] edge_cases[$] = '{
    60'd0, 60'd1,
    60'd31, 60'd32, 60'd33,
    ((60'd1 << 59) - 1), (60'd1 << 59), ((60'd1 << 59) + 1),
    {1'b1, {59{1'b1}}}
  };

  binary128_t exp;

  // ---- Body ----
  // s_i_valid = 1'b1;

  // Check all boundaries
  foreach (edge_cases[idx]) begin
    s_i_m = edge_cases[idx];
    exp = '{
      sign    : 1'b0,
      exp     : 15'd16383,
      mantissa: {57'b0, s_i_m[59:5]}
    };

    wait_n_ticks(my_fixed128_partitionm_ts.MODULE_LATENCY);
    `FAIL_UNLESS_EQUAL(s_o_exp_m, exp)
    `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  end
`SVTEST_END

`SVTEST(correctness_random_0)
  binary128_t exp_rand;
  bit [59:0]  val;
  int         k;

  // ---- Body ----
  // s_i_valid = 1'b1;

  // Random 100 samples
  for (k = 0; k < 100; k++) begin
    val  = { $urandom(), $urandom() };
    s_i_m = val;
    exp_rand = '{
      sign    : 1'b0,
      exp     : 15'd16383,
      mantissa: {57'b0, val[59:5]}
    };

    wait_n_ticks(my_fixed128_partitionm_ts.MODULE_LATENCY);
    `FAIL_UNLESS_EQUAL(s_o_exp_m, exp_rand)
    `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  end

`SVTEST_END
