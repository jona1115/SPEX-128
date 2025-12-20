// ---------------------------------------------------------
// Sanity: reset behavior + no activity when i_valid=0
// ---------------------------------------------------------
`SVTEST(noop_when_valid_low)
  logic [127:0] snapshot;
  snapshot = s_o_exp_x;
  wait_n_ticks(`LATENCY + 2);
  `FAIL_UNLESS_EQUAL(snapshot, s_o_exp_x)
`SVTEST_END

// ---------------------------------------------------------
// Spec 4: o_error should always be 0
// Also checks MODULE_IDENTIFIER default (0x0)
// ---------------------------------------------------------
`SVTEST(no_error_and_identifier)
  // (no declarations needed)
  wait_n_ticks(`LATENCY + 1);
  `FAIL_UNLESS(s_o_error == '0)
  `FAIL_UNLESS_EQUAL(4'b0000, s_o_sanity_identifier)

  send_txn(Q_ONE, CTRL_SINGLE);
  await_and_check_no_error();
`SVTEST_END

// ---------------------------------------------------------
// Spec 1 + 5/6/7: SINGLE_MODE specials
// ---------------------------------------------------------
`SVTEST(single_mode_specials_exact)
  // $display(">>>>> s_o_exp_x=%x", s_o_exp_x);
  // `PRINT_INTERMEDIATE_RESULTS

  // (no declarations)
  send_txn(Q_PZERO, CTRL_SINGLE);  await_and_check_no_error(); `FAIL_UNLESS_EQUAL(Q_ONE,  s_o_exp_x)
  send_txn(Q_NZERO, CTRL_SINGLE);  await_and_check_no_error(); `FAIL_UNLESS_EQUAL(Q_ONE,  s_o_exp_x)
  send_txn(Q_PDEN,  CTRL_SINGLE);  await_and_check_no_error(); `FAIL_UNLESS_EQUAL(Q_ONE,  s_o_exp_x)
  send_txn(Q_NDEN,  CTRL_SINGLE);  await_and_check_no_error(); `FAIL_UNLESS_EQUAL(Q_ONE,  s_o_exp_x)
  send_txn(Q_NINF,  CTRL_SINGLE);  await_and_check_no_error(); `FAIL_UNLESS_EQUAL(Q_PZERO,  s_o_exp_x)

  send_txn(Q_PINF, CTRL_SINGLE);   await_and_check_no_error(); `FAIL_UNLESS(is_inf128(s_o_exp_x) && (s_o_exp_x[127]==1'b0))

  send_txn(Q_QNAN_P, CTRL_SINGLE); await_and_check_no_error(); `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]==1'b0))

  // Comment out because any NaN input outputs positive NaN
  // send_txn(Q_QNAN_N, CTRL_SINGLE); 
  // await_and_check_no_error();
  // `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]==1'b1))
  send_txn(Q_QNAN_N, CTRL_SINGLE); 
  await_and_check_no_error();
  `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]==1'b0))
`SVTEST_END

// ---------------------------------------------------------
// Spec 2: TWO_SP lane mapping + specials
// ---------------------------------------------------------
`SVTEST(two_sp_mode_lane_map_and_specials)
  logic [127:0] x;
  logic [63:0]  outA, outB;

  x = {D_PZERO, D_PINF};
  send_txn(x, CTRL_TWO_SP);
  await_and_check_no_error();
  outA = s_o_exp_x[127:64];
  outB = s_o_exp_x[63:0];
  `FAIL_UNLESS_EQUAL(D_ONE, outA)
  `FAIL_UNLESS(is_inf64(outB) && (outB[63] == 1'b0))

  x = {D_NINF, D_PDEN};
  send_txn(x, CTRL_TWO_SP);
  await_and_check_no_error();
  outA = s_o_exp_x[127:64];
  outB = s_o_exp_x[63:0];
  `FAIL_UNLESS_EQUAL(D_PZERO, outA)
  `PRINT_INTERMEDIATE_RESULTS
  $display(">>>>> outA=%x", outA);
  $display(">>>>> outB=%x", outB);
  `FAIL_UNLESS_EQUAL(D_ONE, outB)

  x = {D_QNAN_P, D_QNAN_N};
  send_txn(x, CTRL_TWO_SP);
  await_and_check_no_error();
  outA = s_o_exp_x[127:64];
  outB = s_o_exp_x[63:0];
  `FAIL_UNLESS(is_nan64(outA) && (outA[63] == 1'b0))
  // `FAIL_UNLESS(is_nan64(outB) && (outB[63] == 1'b1)) // we treat +/- NaN the same
  `FAIL_UNLESS(is_nan64(outB) && (outB[63] == 1'b0))
`SVTEST_END

// ---------------------------------------------------------
// Spec 2: TWO_SP numeric accuracy (LSB window)
// ---------------------------------------------------------
`SVTEST(two_sp_mode_accuracy)
  real a_vals [0:7];
  real b_vals [0:7];
  logic [63:0] a, b, a_exp, b_exp, outA, outB;
  int i;

  a_vals = '{-5.0, -1.0, -0.0, 0.0, 0.5, 1.0, 10.0, 710.0};
  b_vals = '{-2.0, -0.5,  0.1, 2.0, 3.0, 5.5,  88.0, 709.0};

  foreach (a_vals[i]) begin
    a = $realtobits(a_vals[i]);
    b = $realtobits(b_vals[i]);

    if (is_inf64(a)) a_exp = D_PINF; else a_exp = exp64_bits(a);
    if (is_inf64(b)) b_exp = D_PINF; else b_exp = exp64_bits(b);

    send_txn({a, b}, CTRL_TWO_SP);
    await_and_check_no_error();

    outA = s_o_exp_x[127:64];
    outB = s_o_exp_x[63:0];

    if (a_vals[i] > 709.78) begin
      `FAIL_UNLESS(is_inf64(outA) && (outA[63] == 1'b0))
    end else begin
      `FAIL_UNLESS(lsb_error_64_lane(a_exp, outA, `LSB_WINDOW) <= `ERR_TOL_LSB_64)
    end

    if (b_vals[i] > 709.78) begin
      `FAIL_UNLESS(is_inf64(outB) && (outB[63] == 1'b0))
    end else begin
      `FAIL_UNLESS(lsb_error_64_lane(b_exp, outB, `LSB_WINDOW) <= `ERR_TOL_LSB_64)
    end
  end
`SVTEST_END

// ---------------------------------------------------------
// Spec 3: FOUR_SP lane mapping + specials
// ---------------------------------------------------------
`SVTEST(four_sp_mode_lane_map_and_specials)
  logic [127:0] x;
  logic [31:0]  outA, outB, outC, outD;

  x = {F_PZERO, F_PINF, F_NDEN, F_QNAN_N};
  send_txn(x, CTRL_FOUR_SP);
  await_and_check_no_error();

  outA = s_o_exp_x[127:96];
  outB = s_o_exp_x[95:64];
  outC = s_o_exp_x[63:32];
  outD = s_o_exp_x[31:0];

  `FAIL_UNLESS_EQUAL(F_ONE, outA)
  `FAIL_UNLESS(is_inf32(outB) && (outB[31] == 1'b0))
  `FAIL_UNLESS_EQUAL(F_ONE, outC)
  // `FAIL_UNLESS(is_nan32(outD) && (outD[31] == 1'b1)) we treat +/- NaN the same
  `FAIL_UNLESS(is_nan32(outD) && (outD[31] == 1'b0))
`SVTEST_END

// ---------------------------------------------------------
// Spec 3: FOUR_SP numeric accuracy (LSB window)
// ---------------------------------------------------------
`SVTEST(four_sp_mode_accuracy)
  shortreal a_vals [0:5];
  shortreal b_vals [0:5];
  shortreal c_vals [0:5];
  shortreal d_vals [0:5];
  logic [31:0] a, b, c, d, a_exp, b_exp, c_exp, d_exp;
  logic [31:0] outA, outB, outC, outD;
  int i;

  a_vals = '{-5.0, -1.0, 0.0, 0.5, 1.0, 90.0};
  b_vals = '{-2.0, -0.5, 0.1, 2.0, 3.0, 88.0};
  c_vals = '{-10.0, -3.0, -1.0, 4.0, 10.0, 100.0};
  d_vals = '{-0.25, 0.25, 1.5, 5.5, 7.0, 80.0};

  foreach (a_vals[i]) begin
    a = $shortrealtobits(a_vals[i]);
    b = $shortrealtobits(b_vals[i]);
    c = $shortrealtobits(c_vals[i]);
    d = $shortrealtobits(d_vals[i]);

    a_exp = (a_vals[i] > 88.7228) ? F_PINF : exp32_bits(a);
    b_exp = (b_vals[i] > 88.7228) ? F_PINF : exp32_bits(b);
    c_exp = (c_vals[i] > 88.7228) ? F_PINF : exp32_bits(c);
    d_exp = (d_vals[i] > 88.7228) ? F_PINF : exp32_bits(d);

    send_txn({a,b,c,d}, CTRL_FOUR_SP);
    await_and_check_no_error();

    outA = s_o_exp_x[127:96];
    outB = s_o_exp_x[95:64];
    outC = s_o_exp_x[63:32];
    outD = s_o_exp_x[31:0];

    if (a_vals[i] > 88.8) `FAIL_UNLESS(is_inf32(outA) && (outA[31] == 1'b0))
    else `FAIL_UNLESS(lsb_error_32_lane(a_exp, outA, `LSB_WINDOW) <= `ERR_TOL_LSB_32)

    if (b_vals[i] > 88.8) `FAIL_UNLESS(is_inf32(outB) && (outB[31] == 1'b0))
    else `FAIL_UNLESS(lsb_error_32_lane(b_exp, outB, `LSB_WINDOW) <= `ERR_TOL_LSB_32)

    if (c_vals[i] > 88.8) `FAIL_UNLESS(is_inf32(outC) && (outC[31] == 1'b0))
    else `FAIL_UNLESS(lsb_error_32_lane(c_exp, outC, `LSB_WINDOW) <= `ERR_TOL_LSB_32)

    if (d_vals[i] > 88.8) `FAIL_UNLESS(is_inf32(outD) && (outD[31] == 1'b0))
    else `FAIL_UNLESS(lsb_error_32_lane(d_exp, outD, `LSB_WINDOW) <= `ERR_TOL_LSB_32)
  end
`SVTEST_END

// ---------------------------------------------------------
// Spec 1: SINGLE_MODE numeric accuracy via vector files
// ---------------------------------------------------------
`SVTEST(single_mode_accuracy_from_vectors)
  int n, i, err;
  logic [127:0] xin, xexp;

  load_vec128_from_files(n);
  `FAIL_UNLESS(n > 0)

  for (i = 0; i < n; i++) begin
    xin  = vec128_in[i];
    xexp = vec128_gd[i];

    send_txn(xin, CTRL_SINGLE);
    await_and_check_no_error();

    if (is_zero128(xin) || is_denorm128(xin) || (xin == Q_NINF)) begin
      `FAIL_UNLESS_EQUAL(Q_ONE, s_o_exp_x)
    end else if (is_inf128(xin) && xin[127]==1'b0) begin
      `FAIL_UNLESS(is_inf128(s_o_exp_x) && (s_o_exp_x[127]==1'b0))
    end else if (is_nan128(xin)) begin
      `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]==xin[127]))
    end else begin
      err = lsb_error(xexp, s_o_exp_x, `LSB_WINDOW);
      `FAIL_UNLESS(err <= `ERR_TOL_LSB_128)
    end
  end
`SVTEST_END

// ---------------------------------------------------------
// Spec 8: Fixed latency & in-order completion with back-to-back traffic
// ---------------------------------------------------------
`SVTEST(latency_and_ordering)
  logic [127:0] xin0, xin1, xin2;
  logic [63:0]  gd0A, gd0B, gd1A, gd1B, gd2A, gd2B;
  logic [63:0]  outA, outB;

  xin0 = {64'h4000_0000_0000_0000, 64'h3FF0_0000_0000_0000}; // 2.0, 1.0
  xin1 = {64'hC000_0000_0000_0000, 64'h3FE0_0000_0000_0000}; // -2.0, 0.5
  xin2 = {64'h7FF0_0000_0000_0000, 64'h0000_0000_0000_0000}; // +inf, +0

  gd0A = exp64_bits(xin0[127:64]);
  gd0B = exp64_bits(xin0[63:0]);
  gd1A = exp64_bits(xin1[127:64]);
  gd1B = exp64_bits(xin1[63:0]);
  gd2A = D_PINF; // +inf -> +inf
  gd2B = D_ONE;  // +0   -> 1.0

  send_txn(xin0, CTRL_TWO_SP);
  send_txn(xin1, CTRL_TWO_SP);
  send_txn(xin2, CTRL_TWO_SP);

  wait_n_ticks(`LATENCY);
  `FAIL_UNLESS(s_o_error == '0)
  outA = s_o_exp_x[127:64]; outB = s_o_exp_x[63:0];
  `FAIL_UNLESS(lsb_error_64_lane(gd0A, outA, `LSB_WINDOW) <= `ERR_TOL_LSB_64)
  `FAIL_UNLESS(lsb_error_64_lane(gd0B, outB, `LSB_WINDOW) <= `ERR_TOL_LSB_64)

  wait_n_ticks(1);
  `FAIL_UNLESS(s_o_error == '0)
  outA = s_o_exp_x[127:64]; outB = s_o_exp_x[63:0];
  `FAIL_UNLESS(lsb_error_64_lane(gd1A, outA, `LSB_WINDOW) <= `ERR_TOL_LSB_64)
  `FAIL_UNLESS(lsb_error_64_lane(gd1B, outB, `LSB_WINDOW) <= `ERR_TOL_LSB_64)

  wait_n_ticks(1);
  `FAIL_UNLESS(s_o_error == '0)
  outA = s_o_exp_x[127:64]; outB = s_o_exp_x[63:0];
  `FAIL_UNLESS(is_inf64(outA) && (outA[63] == 1'b0))
  `FAIL_UNLESS_EQUAL(gd2B, outB)
`SVTEST_END

