`SVTEST(correctness_0)
  s_i_f = '0;

  #1;
  `FAIL_UNLESS_EQUAL(s_o_exp_f, {1'b0, 15'd16383, 52'b0, 60'b0})
`SVTEST_END

`SVTEST(correctness_edge_cases_0)

  // Create List of edge cases
  bit [64:0] edge_cases[$] = '{
    65'd0, 65'd1,
    65'd31, 65'd32, 65'd33,
    ((65'd1 << 60) - 1), (65'd1 << 60), ((65'd1 << 60) + 1),
    ((65'd1 << 64) - 1), (65'd1 << 64), ((65'd1 << 64) + 1),
    {1'b1, {64{1'b1}}}
  };

  binary128_t exp;

  // ---- Body ----
  s_i_valid = 1'b1;

  // Check all boundaries
  foreach (edge_cases[idx]) begin
    s_i_f = edge_cases[idx];
    exp = '{
      sign    : 1'b0,
      exp     : 15'd16383,
      mantissa: {52'b0, s_i_f[64:5]}
    };

    #1;
    `FAIL_UNLESS_EQUAL(s_o_exp_f, exp)
  end
`SVTEST_END

`SVTEST(correctness_random_0)
  binary128_t exp_rand;
  bit [64:0]  val;
  int         k;

  // ---- Body ----
  s_i_valid = 1'b1;

  // Random 100 samples
  for (k = 0; k < 100; k++) begin
    val  = { $urandom(), $urandom(), bit'($urandom()) }; // 65 bits
    s_i_f = val;
    exp_rand = '{
      sign    : 1'b0,
      exp     : 15'd16383,
      mantissa: {52'b0, val[64:5]}
    };

    #1;
    `FAIL_UNLESS_EQUAL(s_o_exp_f, exp_rand)
  end

`SVTEST_END

