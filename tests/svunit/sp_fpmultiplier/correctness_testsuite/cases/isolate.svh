`SVTEST(metadata_passthrough_and_error_zero)
  drive_meta(SINGLE_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_SINGLE
  wait_n_ticks(`LATENCY);
  `FAIL_UNLESS(s_o_metadata.sp_mode == SINGLE_MODE)

  wait_n_ticks(1);

  drive_meta(TWO_SP_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_TWO_SP
  wait_n_ticks(`LATENCY);
  $display(">>>>> s_o_metadata.sp_mode = %d", s_o_metadata.sp_mode);
  `FAIL_UNLESS(s_o_metadata.sp_mode == TWO_SP_MODE)

  wait_n_ticks(1);

  drive_meta(FOUR_SP_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_FOUR_SP
  wait_n_ticks(`LATENCY);
  $display(">>>>> s_o_metadata.sp_mode = %d", s_o_metadata.sp_mode);
  `FAIL_UNLESS(s_o_metadata.sp_mode == FOUR_SP_MODE)

  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END