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

    $display(">>>>> i=%d, xin=0x%x, xexp=0x%x", i, xin, xexp);
    print_lsb_error(xexp, s_o_exp_x, `LSB_WINDOW);
    `PRINT_INTERMEDIATE_RESULTS
    $display(">>>>> expected=0x%x", xexp);
    $display(">>>>> actual  =0x%x", s_o_exp_x);

    if (is_zero128(xin) || is_denorm128(xin)) begin
      `FAIL_UNLESS_EQUAL(Q_ONE, s_o_exp_x)
    end else if (xin == Q_NINF) begin
      `FAIL_UNLESS_EQUAL(Q_PZERO, s_o_exp_x)
    end else if (is_inf128(xin) && xin[127]==1'b0) begin
      `FAIL_UNLESS(is_inf128(s_o_exp_x) && (s_o_exp_x[127]==1'b0))
    end else if (is_nan128(xin)) begin
      // `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]==xin[127])) we treat +/- NaN the same
      `FAIL_UNLESS(is_nan128(s_o_exp_x) && (s_o_exp_x[127]=='0))
    end else begin
      err = lsb_error(xexp, s_o_exp_x, `LSB_WINDOW);
      `FAIL_UNLESS(err <= `ERR_TOL_LSB_128)
    end
  end
`SVTEST_END

/*

first case:
# >>>>> expected=0x3fd02d1a5ca0fec70aa9cad1be48faa4 == 8.3572864158125960387577947030809158921e-15
                   3fd0=16336-16383=-47
# >>>>> actual  =0x402db34e64cf60850b2393ba4eab7e98 == 119656064210977.26087790321950476491505
                   402d=16429-16383=46

*/