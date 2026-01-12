`SVTEST(partial_valid64_disables_outputs)
  float_metadata_t meta = mk_meta(TWO_SP_MODE, POS_INF, NEG_DENORMAL, NA, ZERO);
  float_metadata_t meta_hold = meta;
  logic [10:0] lane_a = 11'b0_0000001010;
  logic [10:0] lane_b = 11'b1_0000001011;
  logic [10:0] lane_c = 11'b0_0000001100;
  logic [10:0] lane_d = 11'b1_0000001101;
  binary128_t exp128 = '0;
  binary64_t  exp64a = '0;
  binary64_t  exp64b = '0;
  binary32_t  exp32a = '0;
  binary32_t  exp32b = '0;
  binary32_t  exp32c = '0;
  binary32_t  exp32d = '0;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_disabled_outputs_hold(meta_hold, exp128, exp64a, exp64b, exp32a, exp32b, exp32c, exp32d,
                               "partial64 disable");
`SVTEST_END
