`SVTEST(disabled_holds_outputs_after_enable)
  float_metadata_t meta_on  = mk_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  float_metadata_t meta_off = mk_meta(FOUR_SP_MODE, POS_INF, NEG_INF, NA, ZERO);
  logic [10:0] lane_on  = 11'b0_0000001111;
  logic [10:0] lane_off = 11'b1_0000000001;
  logic [10:0] lane_b   = 11'b0_0000000010;
  logic [10:0] lane_c   = 11'b1_0000000011;
  logic [10:0] lane_d   = 11'b0_0000000100;
  float_metadata_t hold_meta;
  binary128_t hold128;
  binary64_t  hold64a;
  binary64_t  hold64b;
  binary32_t  hold32a;
  binary32_t  hold32b;
  binary32_t  hold32c;
  binary32_t  hold32d;

  drive_meta(meta_on.sp_mode, meta_on.float_type_a, meta_on.float_type_b, meta_on.float_type_c, meta_on.float_type_d);
  drive_lanes(lane_on, lane_b, lane_c, lane_d);
  drive_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta_on, "enabled meta");
  expect_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "enabled valids");
  expect_exp128(lane_on, "enabled exp128");
  expect_no_error("enabled no error");
  hold_meta = s_o_metadata;
  hold128 = s_o_exp_a128;
  hold64a = s_o_exp_a64a;
  hold64b = s_o_exp_a64b;
  hold32a = s_o_exp_a32a;
  hold32b = s_o_exp_a32b;
  hold32c = s_o_exp_a32c;
  hold32d = s_o_exp_a32d;

  drive_meta(meta_off.sp_mode, meta_off.float_type_a, meta_off.float_type_b, meta_off.float_type_c, meta_off.float_type_d);
  drive_lanes(lane_off, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  $display(">>>>> hold_meta=%x", hold_meta);
  $display(">>>>> s_o_metadata=%x", s_o_metadata);
  expect_disabled_outputs_hold(hold_meta, hold128, hold64a, hold64b, hold32a, hold32b, hold32c, hold32d,
                               "disabled holds");
`SVTEST_END