// These three tests are written by AI based on fixed128_partitionf_ts'
// correctness test, and verified by Jonathan

`SVTEST(correctness_0)
  // Zero → sign=0, exp=1023, mantissa all zeros
  s_i_f = '0;

  wait_n_ticks(1);
  `FAIL_UNLESS_EQUAL(s_o_exp_f, {1'b0, 11'd1023, 26'b0, 26'b0})
`SVTEST_END

`SVTEST(correctness_edge_cases_0)

  // Create list of edge cases around truncation boundary (drop 1 LSB),
  // around 2^26, and near the max value for 27 bits.
  bit [26:0] edge_cases[$] = '{
    27'd0, 27'd1,
    27'd2, 27'd3,                           // around 2^1 boundary (since we drop bit[0])
    ((27'd1 << 26) - 1), (27'd1 << 26), ((27'd1 << 26) + 1),
    {1'b1, {26{1'b1}}}                      // 2^27 - 1 (all ones)
  };

  binary64_t exp;

  foreach (edge_cases[idx]) begin
    s_i_f = edge_cases[idx];

    exp = '{
      sign     : 1'b0,
      exp      : 11'd1023,
      mantissa : {26'b0, s_i_f[26:1]}
    };

    wait_n_ticks(1);
    `FAIL_UNLESS_EQUAL(s_o_exp_f, exp)
  end
`SVTEST_END


`SVTEST(correctness_random_0)
  binary64_t exp_rand;
  bit  [26:0] val;
  int         k;

  // Random 100 samples (low 27 bits of $urandom are used)
  for (k = 0; k < 100; k++) begin
    val  = $urandom();
    s_i_f = val;

    exp_rand = '{
      sign     : 1'b0,
      exp      : 11'd1023,
      mantissa : {26'b0, val[26:1]}
    };

    wait_n_ticks(1);
    `FAIL_UNLESS_EQUAL(s_o_exp_f, exp_rand)
  end
`SVTEST_END
