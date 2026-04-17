// These three tests are written by AI based on fixed128_partitionm_ts'
// correctness test, and verified by Jonathan

`SVTEST(correctness_0)
  // Zero → sign=0, exp=1023, mantissa all zeros
  s_i_m = '0;

  wait_n_ticks(my_fixed64_partitionm_ts.MODULE_LATENCY);
  `FAIL_UNLESS_EQUAL(s_o_exp_m, {1'b0, 11'd1023, 33'b0, 19'b0})
  `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
`SVTEST_END

`SVTEST(correctness_edge_cases_0)

  // Create list of edge cases around truncation boundary (drop 1 LSB),
  // around 2^19, and near the max value for 20 bits.
  bit [19:0] edge_cases[$] = '{
    20'd0, 20'd1,
    20'd2, 20'd3,                           // around 2^1 boundary (since we drop bit[0])
    ((20'd1 << 19) - 1), (20'd1 << 19),
    ((20'd1 << 19) + 1),
    {1'b1, {19{1'b1}}}                      // 2^20 - 1 (all ones)
  };

  binary64_t exp;

  foreach (edge_cases[idx]) begin
    s_i_m = edge_cases[idx];

    exp = '{
      sign     : 1'b0,
      exp      : 11'd1023,
      mantissa : {33'b0, s_i_m[19:1]}
    };

    wait_n_ticks(my_fixed64_partitionm_ts.MODULE_LATENCY);
    `FAIL_UNLESS_EQUAL(s_o_exp_m, exp)
    `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  end
`SVTEST_END


`SVTEST(correctness_random_0)
  binary64_t exp_rand;
  bit  [19:0] val;
  int         k;

  // Random 100 samples (low 20 bits of $urandom are used)
  for (k = 0; k < 100; k++) begin
    val  = $urandom();
    s_i_m = val;

    exp_rand = '{
      sign     : 1'b0,
      exp      : 11'd1023,
      mantissa : {33'b0, val[19:1]}
    };

    wait_n_ticks(my_fixed64_partitionm_ts.MODULE_LATENCY);
    `FAIL_UNLESS_EQUAL(s_o_exp_m, exp_rand)
    `FAIL_UNLESS_EQUAL(s_o_valid, 1'b1)
  end
`SVTEST_END
