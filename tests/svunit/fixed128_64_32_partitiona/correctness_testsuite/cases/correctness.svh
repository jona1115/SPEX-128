/** 
I gave ChatGPT the specification of the module and it generated all the tests
The specification of fixed128_64_32_partitiona:
1. The enable of the module is if i_valid128 is set, or if (i_valid64a & 
   i_valid64b) is set, or if (i_valid32a & i_valid32b & i_valid32c & i_valid32d) 
   is set. This is the "all or nothing" rule that is consistent throughout 
   the entire system.
2. If the module is enabled: Metadata input i_metadata will be outputted 
   exactly the same after LATENCY cycles.
3. If the module is enabled: All 7 valid bits will also be outputted exactly 
   the same after LATENCY cycles.
4. If the module is enabled: When sp_mode (a parameter in i_metadata) is 
   SINGLE_MODE, after LATENCY cycles, o_valid128 = exp(i_lane_a) in IEEE-754 
   binary128 format. Note that the MSB of i_lane_a is the sign bit, the LSB 
   10 bits are a integer value. The ground truth is stored in the hex file 
   fixed128_0a_partition.hex for positive inputs (i_lane_a[10] === 1'b0) and 
   fixed128_1a_partition.hex for negative inputs (i_lane_a[10] === 1'b1). The 
   line number of the hex files is the same as i_lane_a[9:0], and the content 
   of the line is exp(i_lane_a[9:0]).
5. If the module is enabled: When sp_mode (a parameter in i_metadata) is 
   TWO_SP_MODE, after LATENCY cycles, o_valid64a = exp(i_lane_a), and 
   o_valid64b = exp(i_lane_b) in IEEE-754 binary64 format. Note that the MSB 
   of i_lane_a, and i_lane_b is the sign bit, the LSB 10 bits are a integer 
   value. The ground truth is stored in the hex file fixed64_0a_partition.hex 
   for positive inputs (i_lane_a[10] === 1'b0, or i_lane_b[10] === 1'b0) and 
   fixed64_1a_partition.hex for negative inputs (i_lane_a[10] === 1'b1, 
   i_lane_b[10] === 1'b1). The line number of the hex files is the same as 
   i_lane_a[9:0]/i_lane_b[9:0], and the content of the line is exp(i_lane_a[9:0]) 
   or exp(i_lane_b[9:0]).
6. If the module is enabled: (I will use short form to write the lane names 
   from now on) When sp_mode (a parameter in i_metadata) is FOUR_SP_MODE, after 
   LATENCY cycles, o_valid32a/b/c/d = exp(i_lane_a/b/c/d) in IEEE-754 binary32 
   format. Note that the MSB of i_lane_a/b/c/d is the sign bit, the LSB 10 bits 
   are a integer value. The ground truth is stored in the hex file 
   fixed32_0a_partition.hex for positive inputs (i_lane_a[10] === 1'b0) and 
   fixed32_1a_partition.hex for negative inputs (i_lane_a/b/c/d[10] === 1'b1). 
   The line number of the hex files is the same as i_lane_a/b/c/d[9:0], and 
   the content of the line is exp(i_lane_a/b/c/d[9:0]).
7. LATENCY is 2.
8. No bits in o_error should ever be set at any time.
9. If the module is disabled: The exp outputs (o_exp_a128, o_exp_a64a, 
   o_exp_a64b, o_exp_a32a, o_exp_a32b, o_exp_a32c, o_exp_a32d) will output 0, 
   all valid bits will also be 0, metadata is also 0.
*/

// ----------------------------------------------------------------------
// Spec 1/2/3/4/7/8: SINGLE_MODE enabled by i_valid128, metadata/valids/data after 2 cycles
// ----------------------------------------------------------------------
`SVTEST(single_mode_valid128_passthrough)
  float_metadata_t meta = mk_meta(SINGLE_MODE, NORMAL, NEG_DENORMAL, POS_INF, ZERO);
  logic [10:0] lane_pos = 11'b0_0000011011;
  logic [10:0] lane_neg = 11'b1_0000011011;
  logic [10:0] lane_b   = 11'b1_0000000101;
  logic [10:0] lane_c   = 11'b0_0000000110;
  logic [10:0] lane_d   = 11'b1_0000000111;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_pos, lane_b, lane_c, lane_d);
  drive_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta, "single meta pos");
  expect_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "single valids pos");
  expect_exp128(lane_pos, "single exp128 pos");
  expect_no_error("single no error pos");

  drive_lanes(lane_neg, lane_b, lane_c, lane_d);
  drive_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta, "single meta neg");
  expect_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "single valids neg");
  expect_exp128(lane_neg, "single exp128 neg");
  expect_no_error("single no error neg");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 1/2/3/5/7/8: TWO_SP_MODE enabled by valid64 pair, metadata/valids/data after 2 cycles
// ----------------------------------------------------------------------
`SVTEST(two_sp_mode_valid64_pair_passthrough)
  float_metadata_t meta = mk_meta(TWO_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  logic [10:0] lane_a = 11'b0_0000001110;
  logic [10:0] lane_b = 11'b1_0000010101;
  logic [10:0] lane_c = 11'b0_0000000011;
  logic [10:0] lane_d = 11'b1_0000000100;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta, "two_sp meta");
  expect_valids(1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "two_sp valids");
  expect_exp64a(lane_a, "two_sp exp64a");
  expect_exp64b(lane_b, "two_sp exp64b");
  expect_no_error("two_sp no error");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 1/2/3/6/7/8: FOUR_SP_MODE enabled by valid32 quartet, metadata/valids/data after 2 cycles
// ----------------------------------------------------------------------
`SVTEST(four_sp_mode_valid32_quartet_passthrough)
  float_metadata_t meta = mk_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  logic [10:0] lane_a = 11'b0_0000000010;
  logic [10:0] lane_b = 11'b1_0000000101;
  logic [10:0] lane_c = 11'b0_0000000111;
  logic [10:0] lane_d = 11'b1_0000001000;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta, "four_sp meta");
  expect_valids(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, "four_sp valids");
  expect_exp32a(lane_a, "four_sp exp32a");
  expect_exp32b(lane_b, "four_sp exp32b");
  expect_exp32c(lane_c, "four_sp exp32c");
  expect_exp32d(lane_d, "four_sp exp32d");
  expect_no_error("four_sp no error");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 1/9/8: partial TWO_SP_MODE valid disables module and forces zeros
// ----------------------------------------------------------------------
`SVTEST(partial_valid64_disables_outputs)
  float_metadata_t meta = mk_meta(TWO_SP_MODE, POS_INF, NEG_DENORMAL, NA, ZERO);
  logic [10:0] lane_a = 11'b0_0000001010;
  logic [10:0] lane_b = 11'b1_0000001011;
  logic [10:0] lane_c = 11'b0_0000001100;
  logic [10:0] lane_d = 11'b1_0000001101;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_all_zero_outputs("partial64 disable");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 1/9/8: partial FOUR_SP_MODE valid disables module and forces zeros
// ----------------------------------------------------------------------
`SVTEST(partial_valid32_disables_outputs)
  float_metadata_t meta = mk_meta(FOUR_SP_MODE, NEG_INF, POS_DENORMAL, NORMAL, NORMAL);
  logic [10:0] lane_a = 11'b0_0000010001;
  logic [10:0] lane_b = 11'b1_0000010010;
  logic [10:0] lane_c = 11'b0_0000010011;
  logic [10:0] lane_d = 11'b1_0000010100;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1);
  wait_n_ticks(LATENCY);
  expect_all_zero_outputs("partial32 disable");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 9/8: disabled input clears outputs to zero even after an enabled transaction
// ----------------------------------------------------------------------
`SVTEST(disabled_clears_outputs_after_enable)
  float_metadata_t meta_on  = mk_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  float_metadata_t meta_off = mk_meta(FOUR_SP_MODE, POS_INF, NEG_INF, NA, ZERO);
  logic [10:0] lane_on  = 11'b0_0000001111;
  logic [10:0] lane_off = 11'b1_0000000001;
  logic [10:0] lane_b   = 11'b0_0000000010;
  logic [10:0] lane_c   = 11'b1_0000000011;
  logic [10:0] lane_d   = 11'b0_0000000100;

  drive_meta(meta_on.sp_mode, meta_on.float_type_a, meta_on.float_type_b, meta_on.float_type_c, meta_on.float_type_d);
  drive_lanes(lane_on, lane_b, lane_c, lane_d);
  drive_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_metadata_passthrough(meta_on, "enabled meta");
  expect_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "enabled valids");
  expect_exp128(lane_on, "enabled exp128");
  expect_no_error("enabled no error");

  drive_meta(meta_off.sp_mode, meta_off.float_type_a, meta_off.float_type_b, meta_off.float_type_c, meta_off.float_type_d);
  drive_lanes(lane_off, lane_b, lane_c, lane_d);
  drive_valids(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(LATENCY);
  expect_all_zero_outputs("disabled clears");
`SVTEST_END

// ----------------------------------------------------------------------
// Spec 7/3/8: latency is 2 cycles for valid and data on SINGLE_MODE path
// ----------------------------------------------------------------------
`SVTEST(latency_two_cycles_single_mode)
  float_metadata_t meta = mk_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  logic [10:0] lane_a = 11'b0_0000000101;
  logic [10:0] lane_b = 11'b0_0000000110;
  logic [10:0] lane_c = 11'b0_0000000111;
  logic [10:0] lane_d = 11'b0_0000001000;

  drive_meta(meta.sp_mode, meta.float_type_a, meta.float_type_b, meta.float_type_c, meta.float_type_d);
  drive_lanes(lane_a, lane_b, lane_c, lane_d);
  drive_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
  wait_n_ticks(1);
  expect_valids(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "latency valid=0 @1");
  expect_no_error("latency no error @1");

  wait_n_ticks(1);
  expect_metadata_passthrough(meta, "latency meta @2");
  expect_valids(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "latency valid=1 @2");
  expect_exp128(lane_a, "latency exp128 @2");
  expect_no_error("latency no error @2");
`SVTEST_END
