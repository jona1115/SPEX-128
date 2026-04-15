/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/29/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a wrapper for SPEX-128 components. x comes in, e^x goes out.
 * 
 * The whole thing is seperated into three "lavels". See the diagram
 * here: https://github.com/jona1115/SPEX-128/issues/20#issuecomment-3544661227
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	    |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  11/29/2025   |  Birth of this file
 * 
 *******************************************************************/

`include "config.svh" // Here lives a bunch of macro flags...

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;
import unbiasing_pkg::*;


module SPEX128_top #(
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32,

  // Identifier const
  parameter logic [3:0] MODULE_IDENTIFIER = 4'b0000
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  input   logic [NUM_BITS_128-1:0]                i_x,
  input   logic [3:0]                             i_ctrl,
  output  logic [127:0]                           o_exp_x,

  // Handshake
  input   logic                                   i_valid,
  output  logic                                   o_valid,
  output  logic                                   o_ready,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

`ifndef RUNNING_VIVADO_SYNTHESIS
  // These are temporary... probably "ds" = debug signals
  logic [127:0]     ds_my_float_to_fixed_fixed,
  binary128_t       ds_my_fixed_partition_sp_par_a_exp_a128,
  binary64_t        ds_my_fixed_partition_sp_par_a_exp_64a,
  binary64_t        ds_my_fixed_partition_sp_par_a_exp_64b,
  binary32_t        ds_my_fixed_partition_sp_par_a_exp_32a,
  binary32_t        ds_my_fixed_partition_sp_par_a_exp_32b,
  binary32_t        ds_my_fixed_partition_sp_par_a_exp_32c,
  binary32_t        ds_my_fixed_partition_sp_par_a_exp_32d,
  binary128_t       ds_my_fixed_partition_sp_par_b_exp_a128,
  binary64_t        ds_my_fixed_partition_sp_par_b_exp_64a,
  binary64_t        ds_my_fixed_partition_sp_par_b_exp_64b,
  binary32_t        ds_my_fixed_partition_sp_par_b_exp_32a,
  binary32_t        ds_my_fixed_partition_sp_par_b_exp_32b,
  binary32_t        ds_my_fixed_partition_sp_par_b_exp_32c,
  binary32_t        ds_my_fixed_partition_sp_par_b_exp_32d,
  binary128_t       ds_my_fixed_partition_sp_par_c_exp_a128,
  binary64_t        ds_my_fixed_partition_sp_par_c_exp_64a,
  binary64_t        ds_my_fixed_partition_sp_par_c_exp_64b,
  binary32_t        ds_my_fixed_partition_sp_par_c_exp_32a,
  binary32_t        ds_my_fixed_partition_sp_par_c_exp_32b,
  binary32_t        ds_my_fixed_partition_sp_par_c_exp_32c,
  binary32_t        ds_my_fixed_partition_sp_par_c_exp_32d,
  binary128_t       ds_my_fixed_partition_sp_par_d_exp_a128,
  binary128_t       ds_my_fixed_partition_sp_par_e_exp_a128,
  binary128_t       ds_my_fixed128_partitionf_ts_exp_f128,
  binary64_t        ds_my_fixed64_partitionf_ts_a_exp_f64a,
  binary64_t        ds_my_fixed64_partitionf_ts_b_exp_f64b,
  logic [127:0]     ds_mux_0,
  logic [127:0]     ds_mux_1,
  logic [127:0]     ds_mux_2,
  logic [127:0]     ds_mux_3,
  logic [127:0]     ds_my_sp_fpmultiplier_0_jedi,
  logic [127:0]     ds_my_sp_fpmultiplier_1_jedi,
  logic [127:0]     ds_my_sp_fpmultiplier_2_jedi,
  logic [127:0]     ds_mux_4,
  logic [127:0]     ds_my_sp_fpmultiplier_3_jedi,
  logic [127:0]     ds_my_sp_fpmultiplier_4_jedi,
  logic [127:0]     ds_mul3_final_out,
  logic [127:0]     ds_mul4_final_out,

  float_metadata_t  ds_my_float_to_fixed_metadata,
  logic             ds_my_float_to_fixed_o_valid,
  logic             ds_my_fixed_partition_sp_par_a_o_valid128,
  logic             ds_my_fixed_partition_sp_par_a_o_valid64a,
  logic             ds_my_fixed_partition_sp_par_a_o_valid64b,
  logic             ds_my_fixed_partition_sp_par_a_o_valid32a,
  logic             ds_my_fixed_partition_sp_par_a_o_valid32b,
  logic             ds_my_fixed_partition_sp_par_a_o_valid32c,
  logic             ds_my_fixed_partition_sp_par_a_o_valid32d,
  logic             ds_my_fixed_partition_sp_par_b_o_valid128,
  logic             ds_my_fixed_partition_sp_par_b_o_valid64a,
  logic             ds_my_fixed_partition_sp_par_b_o_valid64b,
  logic             ds_my_fixed_partition_sp_par_b_o_valid32a,
  logic             ds_my_fixed_partition_sp_par_b_o_valid32b,
  logic             ds_my_fixed_partition_sp_par_b_o_valid32c,
  logic             ds_my_fixed_partition_sp_par_b_o_valid32d,
  logic             ds_my_fixed_partition_sp_par_c_o_valid128,
  logic             ds_my_fixed_partition_sp_par_c_o_valid64a,
  logic             ds_my_fixed_partition_sp_par_c_o_valid64b,
  logic             ds_my_fixed_partition_sp_par_c_o_valid32a,
  logic             ds_my_fixed_partition_sp_par_c_o_valid32b,
  logic             ds_my_fixed_partition_sp_par_c_o_valid32c,
  logic             ds_my_fixed_partition_sp_par_c_o_valid32d,
  logic             ds_my_fixed_partition_sp_par_d_o_valid128,
  logic             ds_my_fixed_partition_sp_par_e_o_valid128,
  logic             ds_my_fixed128_partitionf_ts_o_valid,
  logic             ds_my_fixed64_partitionf_ts_a_o_valid,
  logic             ds_my_fixed64_partitionf_ts_b_o_valid,
  logic             ds_my_sp_fpmultiplier_0_valid128_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid64a_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid64b_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid32a_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid32b_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid32c_jedi,
  logic             ds_my_sp_fpmultiplier_0_valid32d_jedi,
  logic             ds_my_sp_fpmultiplier_1_valid128_jedi,
  logic             ds_my_sp_fpmultiplier_1_valid64a_jedi,
  logic             ds_my_sp_fpmultiplier_1_valid64b_jedi,
  logic             ds_my_sp_fpmultiplier_2_valid128_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid128_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid64a_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid64b_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid32a_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid32b_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid32c_jedi,
  logic             ds_my_sp_fpmultiplier_3_valid32d_jedi,
  logic             ds_my_sp_fpmultiplier_4_valid128_jedi,
`endif

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic s_GND;

//=====================================================================================
// Module body
//=====================================================================================
// Signal naming convention: s_<module-name>_<signal-name>
`ifdef USE_DSP
localparam int SP_FPMULTIPLIER_INTMUL_LATENCY = 9;
`else
localparam int SP_FPMULTIPLIER_INTMUL_LATENCY = 3;
`endif
localparam int SP_FPMULTIPLIER_SURROUNDING_LOGIC = 5;
localparam int SP_FPMULTIPLIER_MODULE_LATENCY = SP_FPMULTIPLIER_INTMUL_LATENCY +
                                                SP_FPMULTIPLIER_SURROUNDING_LOGIC;

/******************************************************************
 * 
 * Level 1
 * 
 *****************************************************************/
logic [127:0]     s_my_float_to_fixed_fixed;
float_metadata_t  s_my_float_to_fixed_metadata;
logic             s_my_float_to_fixed_o_valid;
// Identifier signals
logic [3:0] s_my_float_to_fixed_identifier;
// Error signals
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_float_to_fixed_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_float_to_fixed_debug;
float_to_fixed #() my_float_to_fixed (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_float(i_x),
  .i_ctrl(i_ctrl),
  .o_fixed(s_my_float_to_fixed_fixed),
  .o_metadata(s_my_float_to_fixed_metadata),
  .i_valid(i_valid),
  .o_valid(s_my_float_to_fixed_o_valid),
  .o_sanity_identifier(s_my_float_to_fixed_identifier),
  .o_error(s_my_float_to_fixed_error),
  .o_debug(s_my_float_to_fixed_debug)
);

/******************************************************************
 * 
 * Level 2
 * 
 *****************************************************************/
float_metadata_t  s_my_fixed_partition_sp_par_a_metadata;
binary128_t       s_my_fixed_partition_sp_par_a_exp_a128;
binary64_t        s_my_fixed_partition_sp_par_a_exp_64a;
binary64_t        s_my_fixed_partition_sp_par_a_exp_64b;
binary32_t        s_my_fixed_partition_sp_par_a_exp_32a;
binary32_t        s_my_fixed_partition_sp_par_a_exp_32b;
binary32_t        s_my_fixed_partition_sp_par_a_exp_32c;
binary32_t        s_my_fixed_partition_sp_par_a_exp_32d;
logic             s_my_fixed_partition_sp_par_a_o_valid128;
logic             s_my_fixed_partition_sp_par_a_o_valid64a;
logic             s_my_fixed_partition_sp_par_a_o_valid64b;
logic             s_my_fixed_partition_sp_par_a_o_valid32a;
logic             s_my_fixed_partition_sp_par_a_o_valid32b;
logic             s_my_fixed_partition_sp_par_a_o_valid32c;
logic             s_my_fixed_partition_sp_par_a_o_valid32d;
// Metadata
logic [3:0] s_my_fixed_partition_sp_par_a_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_a_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_a_debug;
fixed_partition_sp #(
  .HAS_SIGN(1'b1),
  .USE_COMBINED_SIGNED_128(1'b1),
  .USE_COMBINED_SIGNED_64(1'b1),
  .USE_COMBINED_SIGNED_32(1'b1),
  .ADDR_BITS_128(10),
  .ADDR_BITS_64(10),
  .ADDR_BITS_32(10),
`ifdef USE_DEDICATED_LUT_FOR_LANE_CD
  .USE_DEDICATED_32_FOR_CD(1'b1),
`endif
`ifdef NAIVE_L2
  .USE_128_FOR_64(1'b0),
  .USE_128_FOR_32(1'b0),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .INIT_128_FILE({"fixed128_01a_partition.", `SPEX_RAM_EXT}),
  .INIT_64_FILE({"fixed64_01a_partition.", `SPEX_RAM_EXT}),
  .INIT_32_FILE({"fixed32_01a_partition.", `SPEX_RAM_EXT})
`else
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  `ifdef USE_DEDICATED_LUT_FOR_LANE_CD
    .INIT_32_FILE({"fixed32_01a_partition.", `SPEX_RAM_EXT}),
  `endif
  .INIT_128_FILE({"fixed128_01a_partition.", `SPEX_RAM_EXT})
`endif
) my_fixed_partition_sp_par_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_a_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[127:117]),
  .i_lane_64a(s_my_float_to_fixed_fixed[127:117]),
  .i_lane_64b(s_my_float_to_fixed_fixed[63:53]),
  .i_lane_32a(s_my_float_to_fixed_fixed[127:117]),
  .i_lane_32b(s_my_float_to_fixed_fixed[95:85]),
  .i_lane_32c(s_my_float_to_fixed_fixed[63:53]),
  .i_lane_32d(s_my_float_to_fixed_fixed[31:21]),
  .o_exp_a128(s_my_fixed_partition_sp_par_a_exp_a128),
  .o_exp_64a(s_my_fixed_partition_sp_par_a_exp_64a),
  .o_exp_64b(s_my_fixed_partition_sp_par_a_exp_64b),
  .o_exp_32a(s_my_fixed_partition_sp_par_a_exp_32a),
  .o_exp_32b(s_my_fixed_partition_sp_par_a_exp_32b),
  .o_exp_32c(s_my_fixed_partition_sp_par_a_exp_32c),
  .o_exp_32d(s_my_fixed_partition_sp_par_a_exp_32d),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid32a(s_my_float_to_fixed_o_valid),
  .i_valid32b(s_my_float_to_fixed_o_valid),
  .i_valid32c(s_my_float_to_fixed_o_valid),
  .i_valid32d(s_my_float_to_fixed_o_valid),
  .o_valid128(s_my_fixed_partition_sp_par_a_o_valid128),
  .o_valid64a(s_my_fixed_partition_sp_par_a_o_valid64a),
  .o_valid64b(s_my_fixed_partition_sp_par_a_o_valid64b),
  .o_valid32a(s_my_fixed_partition_sp_par_a_o_valid32a),
  .o_valid32b(s_my_fixed_partition_sp_par_a_o_valid32b),
  .o_valid32c(s_my_fixed_partition_sp_par_a_o_valid32c),
  .o_valid32d(s_my_fixed_partition_sp_par_a_o_valid32d),
  .o_sanity_identifier(s_my_fixed_partition_sp_par_a_identifier),
  .o_error(s_my_fixed_partition_sp_par_a_error),
  .o_debug(s_my_fixed_partition_sp_par_a_debug)
);

float_metadata_t  s_my_fixed_partition_sp_par_b_metadata;
binary128_t       s_my_fixed_partition_sp_par_b_exp_a128;
binary64_t        s_my_fixed_partition_sp_par_b_exp_64a;
binary64_t        s_my_fixed_partition_sp_par_b_exp_64b;
binary32_t        s_my_fixed_partition_sp_par_b_exp_32a;
binary32_t        s_my_fixed_partition_sp_par_b_exp_32b;
binary32_t        s_my_fixed_partition_sp_par_b_exp_32c;
binary32_t        s_my_fixed_partition_sp_par_b_exp_32d;
logic             s_my_fixed_partition_sp_par_b_o_valid128;
logic             s_my_fixed_partition_sp_par_b_o_valid64a;
logic             s_my_fixed_partition_sp_par_b_o_valid64b;
logic             s_my_fixed_partition_sp_par_b_o_valid32a;
logic             s_my_fixed_partition_sp_par_b_o_valid32b;
logic             s_my_fixed_partition_sp_par_b_o_valid32c;
logic             s_my_fixed_partition_sp_par_b_o_valid32d;
// Metadata
logic [3:0] s_my_fixed_partition_sp_par_b_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_b_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_b_debug;
fixed_partition_sp #(
  .HAS_SIGN(1'b0),
  .ADDR_BITS_128(13),
  .ADDR_BITS_64(13),
  .ADDR_BITS_32(13),
`ifdef USE_DEDICATED_LUT_FOR_LANE_CD
  .USE_DEDICATED_32_FOR_CD(1'b1),
`endif
`ifdef NAIVE_L2
  .USE_128_FOR_64(1'b0),
  .USE_128_FOR_32(1'b0),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .INIT_128_FILE({"fixed128_b_partition.", `SPEX_RAM_EXT}),
  .INIT_64_FILE({"fixed64_b_partition.", `SPEX_RAM_EXT}),
  .INIT_32_FILE({"fixed32_b_partition.", `SPEX_RAM_EXT})
`else
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  `ifdef USE_DEDICATED_LUT_FOR_LANE_CD
    .INIT_32_FILE({"fixed32_b_partition.", `SPEX_RAM_EXT}),
  `endif
  .INIT_128_FILE({"fixed128_b_partition.", `SPEX_RAM_EXT})
`endif
) my_fixed_partition_sp_par_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_b_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[116:104]),
  .i_lane_64a(s_my_float_to_fixed_fixed[116:104]),
  .i_lane_64b(s_my_float_to_fixed_fixed[52:40]),
  .i_lane_32a(s_my_float_to_fixed_fixed[116:104]),
  .i_lane_32b(s_my_float_to_fixed_fixed[84:72]),
  .i_lane_32c(s_my_float_to_fixed_fixed[52:40]),
  .i_lane_32d(s_my_float_to_fixed_fixed[20:8]),
  .o_exp_a128(s_my_fixed_partition_sp_par_b_exp_a128),
  .o_exp_64a(s_my_fixed_partition_sp_par_b_exp_64a),
  .o_exp_64b(s_my_fixed_partition_sp_par_b_exp_64b),
  .o_exp_32a(s_my_fixed_partition_sp_par_b_exp_32a),
  .o_exp_32b(s_my_fixed_partition_sp_par_b_exp_32b),
  .o_exp_32c(s_my_fixed_partition_sp_par_b_exp_32c),
  .o_exp_32d(s_my_fixed_partition_sp_par_b_exp_32d),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid32a(s_my_float_to_fixed_o_valid),
  .i_valid32b(s_my_float_to_fixed_o_valid),
  .i_valid32c(s_my_float_to_fixed_o_valid),
  .i_valid32d(s_my_float_to_fixed_o_valid),
  .o_valid128(s_my_fixed_partition_sp_par_b_o_valid128),
  .o_valid64a(s_my_fixed_partition_sp_par_b_o_valid64a),
  .o_valid64b(s_my_fixed_partition_sp_par_b_o_valid64b),
  .o_valid32a(s_my_fixed_partition_sp_par_b_o_valid32a),
  .o_valid32b(s_my_fixed_partition_sp_par_b_o_valid32b),
  .o_valid32c(s_my_fixed_partition_sp_par_b_o_valid32c),
  .o_valid32d(s_my_fixed_partition_sp_par_b_o_valid32d),
  .o_sanity_identifier(s_my_fixed_partition_sp_par_b_identifier),
  .o_error(s_my_fixed_partition_sp_par_b_error),
  .o_debug(s_my_fixed_partition_sp_par_b_debug)
);

float_metadata_t  s_my_fixed_partition_sp_par_c_metadata;
binary128_t       s_my_fixed_partition_sp_par_c_exp_a128;
binary64_t        s_my_fixed_partition_sp_par_c_exp_64a;
binary64_t        s_my_fixed_partition_sp_par_c_exp_64b;
binary32_t        s_my_fixed_partition_sp_par_c_exp_32a;
binary32_t        s_my_fixed_partition_sp_par_c_exp_32b;
binary32_t        s_my_fixed_partition_sp_par_c_exp_32c;
binary32_t        s_my_fixed_partition_sp_par_c_exp_32d;
logic             s_my_fixed_partition_sp_par_c_o_valid128;
logic             s_my_fixed_partition_sp_par_c_o_valid64a;
logic             s_my_fixed_partition_sp_par_c_o_valid64b;
logic             s_my_fixed_partition_sp_par_c_o_valid32a;
logic             s_my_fixed_partition_sp_par_c_o_valid32b;
logic             s_my_fixed_partition_sp_par_c_o_valid32c;
logic             s_my_fixed_partition_sp_par_c_o_valid32d;
// Metadata
logic [3:0] s_my_fixed_partition_sp_par_c_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_c_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_c_debug;
fixed_partition_sp #(
  .HAS_SIGN(1'b0),
  .ADDR_BITS_128(13),
  .ADDR_BITS_64(13),
  .ADDR_BITS_32(11),
`ifdef USE_DEDICATED_LUT_FOR_LANE_CD
  .USE_DEDICATED_32_FOR_CD(1'b1),
`endif
`ifdef NAIVE_L2
  .USE_128_FOR_64(1'b0),
  .USE_128_FOR_32(1'b0),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .INIT_128_FILE({"fixed128_c_partition.", `SPEX_RAM_EXT}),
  .INIT_64_FILE({"fixed64_c_partition.", `SPEX_RAM_EXT}),
  .INIT_32_FILE({"fixed32_c_partition.", `SPEX_RAM_EXT})
`else
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  `ifdef USE_DEDICATED_LUT_FOR_LANE_CD
    .INIT_32_FILE({"fixed32_c_partition.", `SPEX_RAM_EXT}),
  `endif
  .INIT_128_FILE({"fixed128_c_partition.", `SPEX_RAM_EXT})
`endif
) my_fixed_partition_sp_par_c (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_c_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[103:91]),
  .i_lane_64a(s_my_float_to_fixed_fixed[103:91]),
  .i_lane_64b(s_my_float_to_fixed_fixed[39:27]),
  .i_lane_32a(s_my_float_to_fixed_fixed[106:96]),
  .i_lane_32b(s_my_float_to_fixed_fixed[74:64]),
  .i_lane_32c(s_my_float_to_fixed_fixed[42:32]),
  .i_lane_32d(s_my_float_to_fixed_fixed[10:0]),
  .o_exp_a128(s_my_fixed_partition_sp_par_c_exp_a128),
  .o_exp_64a(s_my_fixed_partition_sp_par_c_exp_64a),
  .o_exp_64b(s_my_fixed_partition_sp_par_c_exp_64b),
  .o_exp_32a(s_my_fixed_partition_sp_par_c_exp_32a),
  .o_exp_32b(s_my_fixed_partition_sp_par_c_exp_32b),
  .o_exp_32c(s_my_fixed_partition_sp_par_c_exp_32c),
  .o_exp_32d(s_my_fixed_partition_sp_par_c_exp_32d),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid32a(s_my_float_to_fixed_o_valid),
  .i_valid32b(s_my_float_to_fixed_o_valid),
  .i_valid32c(s_my_float_to_fixed_o_valid),
  .i_valid32d(s_my_float_to_fixed_o_valid),
  .o_valid128(s_my_fixed_partition_sp_par_c_o_valid128),
  .o_valid64a(s_my_fixed_partition_sp_par_c_o_valid64a),
  .o_valid64b(s_my_fixed_partition_sp_par_c_o_valid64b),
  .o_valid32a(s_my_fixed_partition_sp_par_c_o_valid32a),
  .o_valid32b(s_my_fixed_partition_sp_par_c_o_valid32b),
  .o_valid32c(s_my_fixed_partition_sp_par_c_o_valid32c),
  .o_valid32d(s_my_fixed_partition_sp_par_c_o_valid32d),
  .o_sanity_identifier(s_my_fixed_partition_sp_par_c_identifier),
  .o_error(s_my_fixed_partition_sp_par_c_error),
  .o_debug(s_my_fixed_partition_sp_par_c_debug)
);

logic             unused_my_fixed_partition_sp_par_d_0,
                  unused_my_fixed_partition_sp_par_d_1,
                  unused_my_fixed_partition_sp_par_d_2,
                  unused_my_fixed_partition_sp_par_d_3,
                  unused_my_fixed_partition_sp_par_d_4,
                  unused_my_fixed_partition_sp_par_d_5;
binary64_t        unused_my_fixed_partition_sp_par_d_64_0,
                  unused_my_fixed_partition_sp_par_d_64_1;
binary32_t        unused_my_fixed_partition_sp_par_d_32_0,
                  unused_my_fixed_partition_sp_par_d_32_1,
                  unused_my_fixed_partition_sp_par_d_32_2,
                  unused_my_fixed_partition_sp_par_d_32_3;
float_metadata_t  s_my_fixed_partition_sp_par_d_metadata;
binary128_t       s_my_fixed_partition_sp_par_d_exp_a128;
logic             s_my_fixed_partition_sp_par_d_o_valid128;
// Metadata
logic [3:0] s_my_fixed_partition_sp_par_d_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_d_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_d_debug;
fixed_partition_sp #(
  .HAS_SIGN(1'b0),
  .USE_128_FOR_64(1'b0),
  .USE_128_FOR_32(1'b0),
  .ENABLE_64(1'b0),
  .ENABLE_32(1'b0),
  .ADDR_BITS_128(13),
  .INIT_128_FILE({"fixed128_d_partition.", `SPEX_RAM_EXT})
) my_fixed_partition_sp_par_d (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_d_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[90:78]),
  .i_lane_64a('0),
  .i_lane_64b('0),
  .i_lane_32a('0),
  .i_lane_32b('0),
  .i_lane_32c('0),
  .i_lane_32d('0),
  .o_exp_a128(s_my_fixed_partition_sp_par_d_exp_a128),
  .o_exp_64a(unused_my_fixed_partition_sp_par_d_64_0),
  .o_exp_64b(unused_my_fixed_partition_sp_par_d_64_1),
  .o_exp_32a(unused_my_fixed_partition_sp_par_d_32_0),
  .o_exp_32b(unused_my_fixed_partition_sp_par_d_32_1),
  .o_exp_32c(unused_my_fixed_partition_sp_par_d_32_2),
  .o_exp_32d(unused_my_fixed_partition_sp_par_d_32_3),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .i_valid64a('0),
  .i_valid64b('0),
  .i_valid32a('0),
  .i_valid32b('0),
  .i_valid32c('0),
  .i_valid32d('0),
  .o_valid128(s_my_fixed_partition_sp_par_d_o_valid128),
  .o_valid64a(unused_my_fixed_partition_sp_par_d_0),
  .o_valid64b(unused_my_fixed_partition_sp_par_d_1),
  .o_valid32a(unused_my_fixed_partition_sp_par_d_2),
  .o_valid32b(unused_my_fixed_partition_sp_par_d_3),
  .o_valid32c(unused_my_fixed_partition_sp_par_d_4),
  .o_valid32d(unused_my_fixed_partition_sp_par_d_5),
  .o_sanity_identifier(s_my_fixed_partition_sp_par_d_identifier),
  .o_error(s_my_fixed_partition_sp_par_d_error),
  .o_debug(s_my_fixed_partition_sp_par_d_debug)
);

logic             unused_my_fixed_partition_sp_par_e_0,
                  unused_my_fixed_partition_sp_par_e_1,
                  unused_my_fixed_partition_sp_par_e_2,
                  unused_my_fixed_partition_sp_par_e_3,
                  unused_my_fixed_partition_sp_par_e_4,
                  unused_my_fixed_partition_sp_par_e_5;
binary64_t        unused_my_fixed_partition_sp_par_e_64_0,
                  unused_my_fixed_partition_sp_par_e_64_1;
binary32_t        unused_my_fixed_partition_sp_par_e_32_0,
                  unused_my_fixed_partition_sp_par_e_32_1,
                  unused_my_fixed_partition_sp_par_e_32_2,
                  unused_my_fixed_partition_sp_par_e_32_3;
float_metadata_t  s_my_fixed_partition_sp_par_e_metadata;
binary128_t       s_my_fixed_partition_sp_par_e_exp_a128;
logic             s_my_fixed_partition_sp_par_e_o_valid128;
// Metadata
logic [3:0] s_my_fixed_partition_sp_par_e_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_e_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed_partition_sp_par_e_debug;
fixed_partition_sp #(
  .HAS_SIGN(1'b0),
  .USE_128_FOR_64(1'b0),
  .USE_128_FOR_32(1'b0),
  .ENABLE_64(1'b0),
  .ENABLE_32(1'b0),
  .ADDR_BITS_128(13),
  .INIT_128_FILE({"fixed128_e_partition.", `SPEX_RAM_EXT})
) my_fixed_partition_sp_par_e (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_e_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[77:65]),
  .i_lane_64a('0),
  .i_lane_64b('0),
  .i_lane_32a('0),
  .i_lane_32b('0),
  .i_lane_32c('0),
  .i_lane_32d('0),
  .o_exp_a128(s_my_fixed_partition_sp_par_e_exp_a128),
  .o_exp_64a(unused_my_fixed_partition_sp_par_e_64_0),
  .o_exp_64b(unused_my_fixed_partition_sp_par_e_64_1),
  .o_exp_32a(unused_my_fixed_partition_sp_par_e_32_0),
  .o_exp_32b(unused_my_fixed_partition_sp_par_e_32_1),
  .o_exp_32c(unused_my_fixed_partition_sp_par_e_32_2),
  .o_exp_32d(unused_my_fixed_partition_sp_par_e_32_3),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .i_valid64a('0),
  .i_valid64b('0),
  .i_valid32a('0),
  .i_valid32b('0),
  .i_valid32c('0),
  .i_valid32d('0),
  .o_valid128(s_my_fixed_partition_sp_par_e_o_valid128),
  .o_valid64a(unused_my_fixed_partition_sp_par_e_0),
  .o_valid64b(unused_my_fixed_partition_sp_par_e_1),
  .o_valid32a(unused_my_fixed_partition_sp_par_e_2),
  .o_valid32b(unused_my_fixed_partition_sp_par_e_3),
  .o_valid32c(unused_my_fixed_partition_sp_par_e_4),
  .o_valid32d(unused_my_fixed_partition_sp_par_e_5),
  .o_sanity_identifier(s_my_fixed_partition_sp_par_e_identifier),
  .o_error(s_my_fixed_partition_sp_par_e_error),
  .o_debug(s_my_fixed_partition_sp_par_e_debug)
);

binary128_t s_my_fixed128_partitionf_ts_exp_f128;
logic       s_my_fixed128_partitionf_ts_o_valid;
// Metadata
logic [3:0] s_my_fixed128_partitionf_ts_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitionf_ts_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitionf_ts_debug;
fixed128_partitionf_ts #() my_fixed128_partitionf_ts (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .i_f(s_my_float_to_fixed_fixed[64:0]),
  .o_exp_f(s_my_fixed128_partitionf_ts_exp_f128),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed128_partitionf_ts_o_valid),
  .o_sanity_identifier(s_my_fixed128_partitionf_ts_identifier),
  .o_error(s_my_fixed128_partitionf_ts_error),
  .o_debug(s_my_fixed128_partitionf_ts_debug)
);

binary64_t  s_my_fixed64_partitionf_ts_a_exp_f64a;
logic       s_my_fixed64_partitionf_ts_a_o_valid;
// Metadata
logic [3:0] s_my_fixed64_partitionf_ts_a_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed64_partitionf_ts_a_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed64_partitionf_ts_a_debug;
fixed64_partitionf_ts #() my_fixed64_partitionf_ts_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .i_f(s_my_float_to_fixed_fixed[90:64]),
  .o_exp_f(s_my_fixed64_partitionf_ts_a_exp_f64a),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed64_partitionf_ts_a_o_valid),
  .o_sanity_identifier(s_my_fixed64_partitionf_ts_a_identifier),
  .o_error(s_my_fixed64_partitionf_ts_a_error),
  .o_debug(s_my_fixed64_partitionf_ts_a_debug)
);

binary64_t  s_my_fixed64_partitionf_ts_b_exp_f64b;
logic       s_my_fixed64_partitionf_ts_b_o_valid;
// Metadata
logic [3:0] s_my_fixed64_partitionf_ts_b_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed64_partitionf_ts_b_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed64_partitionf_ts_b_debug;
fixed64_partitionf_ts #() my_fixed64_partitionf_ts_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .i_f(s_my_float_to_fixed_fixed[26:0]),
  .o_exp_f(s_my_fixed64_partitionf_ts_b_exp_f64b),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed64_partitionf_ts_b_o_valid),
  .o_sanity_identifier(s_my_fixed64_partitionf_ts_b_identifier),
  .o_error(s_my_fixed64_partitionf_ts_b_error),
  .o_debug(s_my_fixed64_partitionf_ts_b_debug)
);


// We also need to pass the metadata across level 2
float_metadata_t s_level2_metadata;
/**
 * Register for the metadata
 */
always_ff @( posedge i_clk ) begin : level2_metadata_register
  if (!i_rst_n) begin
    s_level2_metadata <= '0;
  end
  else begin
    s_level2_metadata <= s_my_float_to_fixed_metadata;
  end
end // always_ff

/******************************************************************
 * 
 * Level 3
 * 
 *****************************************************************/
`define S (s_level2_metadata.sp_mode) // todo give this macro a better name
logic [127:0] s_mux_0;
logic         s_mux_0_valid;
always_comb begin : mux_0
  case (`S)
    SINGLE_MODE: begin
      s_mux_0       = s_my_fixed_partition_sp_par_a_exp_a128;
      s_mux_0_valid = s_my_fixed_partition_sp_par_a_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_0       = {s_my_fixed_partition_sp_par_a_exp_64a, 
                       s_my_fixed_partition_sp_par_a_exp_64b};
      s_mux_0_valid = s_my_fixed_partition_sp_par_a_o_valid64a &
                      s_my_fixed_partition_sp_par_a_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_0       = {s_my_fixed_partition_sp_par_a_exp_32a,
                       s_my_fixed_partition_sp_par_a_exp_32b,
                       s_my_fixed_partition_sp_par_a_exp_32c,
                       s_my_fixed_partition_sp_par_a_exp_32d};
      s_mux_0_valid = s_my_fixed_partition_sp_par_a_o_valid32a &
                      s_my_fixed_partition_sp_par_a_o_valid32b &
                      s_my_fixed_partition_sp_par_a_o_valid32c & 
                      s_my_fixed_partition_sp_par_a_o_valid32d;
    end // FOUR_SP_MODE

    default: begin
      s_mux_0       = '0;
      s_mux_0_valid = '0;
    end
  endcase
end

logic [127:0] s_mux_1;
logic         s_mux_1_valid;
always_comb begin : mux_1
  case (`S)
    SINGLE_MODE: begin
      s_mux_1       = s_my_fixed_partition_sp_par_b_exp_a128;
      s_mux_1_valid = s_my_fixed_partition_sp_par_b_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_1       = {s_my_fixed_partition_sp_par_b_exp_64a, 
                       s_my_fixed_partition_sp_par_b_exp_64b};
      s_mux_1_valid = s_my_fixed_partition_sp_par_b_o_valid64a &
                      s_my_fixed_partition_sp_par_b_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_1       = {s_my_fixed_partition_sp_par_b_exp_32a,
                       s_my_fixed_partition_sp_par_b_exp_32b,
                       s_my_fixed_partition_sp_par_b_exp_32c,
                       s_my_fixed_partition_sp_par_b_exp_32d};
      s_mux_1_valid = s_my_fixed_partition_sp_par_b_o_valid32a &
                      s_my_fixed_partition_sp_par_b_o_valid32b &
                      s_my_fixed_partition_sp_par_b_o_valid32c &
                      s_my_fixed_partition_sp_par_b_o_valid32d;
    end // FOUR_SP_MODE

    default: begin
      s_mux_1       = '0;
      s_mux_1_valid = '0;
    end
  endcase
end

logic [127:0] s_mux_2;
logic         s_mux_2_valid;
always_comb begin : mux_2
  case (`S)
    SINGLE_MODE: begin
      s_mux_2       = s_my_fixed_partition_sp_par_c_exp_a128;
      s_mux_2_valid = s_my_fixed_partition_sp_par_c_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_2       = {s_my_fixed_partition_sp_par_c_exp_64a, 
                       s_my_fixed_partition_sp_par_c_exp_64b};
      s_mux_2_valid = s_my_fixed_partition_sp_par_c_o_valid64a &
                      s_my_fixed_partition_sp_par_c_o_valid64b;
    end // TWO_SP_MODE

    default: begin
      s_mux_2       = '0;
      s_mux_2_valid = '0;
    end
  endcase
end

logic [127:0] s_mux_3;
logic         s_mux_3_valid;
always_comb begin : mux_3
  case (`S)
    SINGLE_MODE: begin
      s_mux_3       = s_my_fixed_partition_sp_par_d_exp_a128;
      s_mux_3_valid = s_my_fixed_partition_sp_par_d_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_3       = {s_my_fixed64_partitionf_ts_a_exp_f64a, 
                       s_my_fixed64_partitionf_ts_b_exp_f64b};
      s_mux_3_valid = s_my_fixed64_partitionf_ts_a_o_valid &
                      s_my_fixed64_partitionf_ts_b_o_valid;
    end // TWO_SP_MODE

    default: begin
      s_mux_3       = '0;
      s_mux_3_valid = '0;
    end
  endcase
end

float_metadata_t unused_metadata_0;
logic [127:0] s_my_sp_fpmultiplier_0_jedi;
logic s_my_sp_fpmultiplier_0_valid128_jedi;
logic s_my_sp_fpmultiplier_0_valid64a_jedi;
logic s_my_sp_fpmultiplier_0_valid64b_jedi;
logic s_my_sp_fpmultiplier_0_valid32a_jedi;
logic s_my_sp_fpmultiplier_0_valid32b_jedi;
logic s_my_sp_fpmultiplier_0_valid32c_jedi;
logic s_my_sp_fpmultiplier_0_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_fpmultiplier_0_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_0_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_0_debug;
sp_fpmultiplier #(
  .INTMUL_LATENCY(SP_FPMULTIPLIER_INTMUL_LATENCY),
  .SURROUNDING_LOGIC(SP_FPMULTIPLIER_SURROUNDING_LOGIC),
  .MODULE_LATENCY(SP_FPMULTIPLIER_MODULE_LATENCY)
) my_sp_fpmultiplier_0 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_0/*not like it is useful anyway*/),
  .i_in_anikin(s_mux_0),
  .i_in_force(s_mux_1),
  .o_out_jedi(s_my_sp_fpmultiplier_0_jedi),
  .i_valid128_anikin(s_mux_0_valid),
  .i_valid128_force(s_mux_1_valid),
  .i_valid64a_anikin(s_mux_0_valid),
  .i_valid64a_force(s_mux_1_valid),
  .i_valid64b_anikin(s_mux_0_valid),
  .i_valid64b_force(s_mux_1_valid),
  .i_valid32a_anikin(s_mux_0_valid),
  .i_valid32a_force(s_mux_1_valid),
  .i_valid32b_anikin(s_mux_0_valid),
  .i_valid32b_force(s_mux_1_valid),
  .i_valid32c_anikin(s_mux_0_valid),
  .i_valid32c_force(s_mux_1_valid),
  .i_valid32d_anikin(s_mux_0_valid),
  .i_valid32d_force(s_mux_1_valid),
  .o_valid128_jedi(s_my_sp_fpmultiplier_0_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_fpmultiplier_0_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_fpmultiplier_0_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_fpmultiplier_0_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_fpmultiplier_0_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_fpmultiplier_0_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_fpmultiplier_0_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_fpmultiplier_0_identifier),
  .o_error(s_my_sp_fpmultiplier_0_error),
  .o_debug(s_my_sp_fpmultiplier_0_debug)
);

float_metadata_t unused_metadata_1;
logic [127:0] s_my_sp_fpmultiplier_1_jedi;
logic s_my_sp_fpmultiplier_1_valid128_jedi;
logic s_my_sp_fpmultiplier_1_valid64a_jedi;
logic s_my_sp_fpmultiplier_1_valid64b_jedi;
logic s_my_sp_fpmultiplier_1_valid32a_jedi;
logic s_my_sp_fpmultiplier_1_valid32b_jedi;
logic s_my_sp_fpmultiplier_1_valid32c_jedi;
logic s_my_sp_fpmultiplier_1_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_fpmultiplier_1_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_1_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_1_debug;
logic unused_mul1_1, unused_mul1_2, unused_mul1_3, unused_mul1_4;
sp_fpmultiplier #(
  .INTMUL_LATENCY(SP_FPMULTIPLIER_INTMUL_LATENCY),
  .SURROUNDING_LOGIC(SP_FPMULTIPLIER_SURROUNDING_LOGIC),
  .MODULE_LATENCY(SP_FPMULTIPLIER_MODULE_LATENCY)
) my_sp_fpmultiplier_1 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_1/*not like it is useful anyway*/),
  .i_in_anikin(s_mux_2),
  .i_in_force(s_mux_3),
  .o_out_jedi(s_my_sp_fpmultiplier_1_jedi),
  .i_valid128_anikin(s_mux_2_valid),
  .i_valid128_force(s_mux_3_valid),
  .i_valid64a_anikin(s_mux_2_valid),
  .i_valid64a_force(s_mux_3_valid),
  .i_valid64b_anikin(s_mux_2_valid),
  .i_valid64b_force(s_mux_3_valid),
  .i_valid32a_anikin('0),
  .i_valid32a_force('0),
  .i_valid32b_anikin('0),
  .i_valid32b_force('0),
  .i_valid32c_anikin('0),
  .i_valid32c_force('0),
  .i_valid32d_anikin('0),
  .i_valid32d_force('0),
  .o_valid128_jedi(s_my_sp_fpmultiplier_1_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_fpmultiplier_1_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_fpmultiplier_1_valid64b_jedi),
  .o_valid32a_jedi(unused_mul1_1),
  .o_valid32b_jedi(unused_mul1_2),
  .o_valid32c_jedi(unused_mul1_3),
  .o_valid32d_jedi(unused_mul1_4),
  .o_sanity_identifier(s_my_sp_fpmultiplier_1_identifier),
  .o_error(s_my_sp_fpmultiplier_1_error),
  .o_debug(s_my_sp_fpmultiplier_1_debug)
);

float_metadata_t unused_metadata_2;
logic [127:0] s_my_sp_fpmultiplier_2_jedi;
logic s_my_sp_fpmultiplier_2_valid128_jedi;
logic s_my_sp_fpmultiplier_2_valid64a_jedi;
logic s_my_sp_fpmultiplier_2_valid64b_jedi;
logic s_my_sp_fpmultiplier_2_valid32a_jedi;
logic s_my_sp_fpmultiplier_2_valid32b_jedi;
logic s_my_sp_fpmultiplier_2_valid32c_jedi;
logic s_my_sp_fpmultiplier_2_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_fpmultiplier_2_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_2_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_2_debug;
logic unused_mul2_1, unused_mul2_2, unused_mul2_3, unused_mul2_4, unused_mul2_5, unused_mul2_6;
sp_fpmultiplier #(
  .INTMUL_LATENCY(SP_FPMULTIPLIER_INTMUL_LATENCY),
  .SURROUNDING_LOGIC(SP_FPMULTIPLIER_SURROUNDING_LOGIC),
  .MODULE_LATENCY(SP_FPMULTIPLIER_MODULE_LATENCY)
) my_sp_fpmultiplier_2 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_2/*not like it is useful anyway*/),
  .i_in_anikin(s_my_fixed_partition_sp_par_e_exp_a128),
  .i_in_force(s_my_fixed128_partitionf_ts_exp_f128),
  .o_out_jedi(s_my_sp_fpmultiplier_2_jedi),
  .i_valid128_anikin(s_my_fixed_partition_sp_par_e_o_valid128),
  .i_valid128_force(s_my_fixed128_partitionf_ts_o_valid),
  .i_valid64a_anikin('0),
  .i_valid64a_force('0),
  .i_valid64b_anikin('0),
  .i_valid64b_force('0),
  .i_valid32a_anikin('0),
  .i_valid32a_force('0),
  .i_valid32b_anikin('0),
  .i_valid32b_force('0),
  .i_valid32c_anikin('0),
  .i_valid32c_force('0),
  .i_valid32d_anikin('0),
  .i_valid32d_force('0),
  .o_valid128_jedi(s_my_sp_fpmultiplier_2_valid128_jedi),
  .o_valid64a_jedi(unused_mul2_1),
  .o_valid64b_jedi(unused_mul2_2),
  .o_valid32a_jedi(unused_mul2_3),
  .o_valid32b_jedi(unused_mul2_4),
  .o_valid32c_jedi(unused_mul2_5),
  .o_valid32d_jedi(unused_mul2_6),
  .o_sanity_identifier(s_my_sp_fpmultiplier_2_identifier),
  .o_error(s_my_sp_fpmultiplier_2_error),
  .o_debug(s_my_sp_fpmultiplier_2_debug)
);

logic [127:0] s_mul2_for_mul4_pipe [SP_FPMULTIPLIER_MODULE_LATENCY-1:0];
logic         s_mul2_for_mul4_valid_pipe [SP_FPMULTIPLIER_MODULE_LATENCY-1:0];
logic [127:0] s_mul2_for_mul4_aligned;
logic         s_mul2_for_mul4_valid_aligned;

// SINGLE_MODE reaches mul4 through mul0/mul1 -> mul3 on one side and only mul2 on the
// other, so delay mul2 by one multiplier latency before feeding the final multiply.
always_ff @(posedge i_clk) begin : mul2_for_mul4_align
  int i;
  if (!i_rst_n) begin
    s_mul2_for_mul4_pipe <= '{default:'0};
    s_mul2_for_mul4_valid_pipe <= '{default:'0};
  end
  else begin
    s_mul2_for_mul4_pipe[0] <= s_my_sp_fpmultiplier_2_jedi;
    s_mul2_for_mul4_valid_pipe[0] <= s_my_sp_fpmultiplier_2_valid128_jedi;

    for (i = 1; i < SP_FPMULTIPLIER_MODULE_LATENCY; i++) begin
      s_mul2_for_mul4_pipe[i] <= s_mul2_for_mul4_pipe[i-1];
      s_mul2_for_mul4_valid_pipe[i] <= s_mul2_for_mul4_valid_pipe[i-1];
    end
  end
end

assign s_mul2_for_mul4_aligned = s_mul2_for_mul4_pipe[SP_FPMULTIPLIER_MODULE_LATENCY-1];
assign s_mul2_for_mul4_valid_aligned = s_mul2_for_mul4_valid_pipe[SP_FPMULTIPLIER_MODULE_LATENCY-1];

logic [127:0] s_mux_4;
logic         s_mux_4_valid;
logic [127:0] s_mux_4_foursp_raw;
logic         s_mux_4_foursp_valid_raw;
logic [127:0] s_mux_4_foursp_pipe [SP_FPMULTIPLIER_MODULE_LATENCY-1:0];
logic         s_mux_4_foursp_valid_pipe [SP_FPMULTIPLIER_MODULE_LATENCY-1:0];
logic [127:0] s_mux_4_foursp_aligned;
logic         s_mux_4_foursp_valid_aligned;

assign s_mux_4_foursp_raw = {s_my_fixed_partition_sp_par_c_exp_32a,
                             s_my_fixed_partition_sp_par_c_exp_32b,
                             s_my_fixed_partition_sp_par_c_exp_32c,
                             s_my_fixed_partition_sp_par_c_exp_32d};
assign s_mux_4_foursp_valid_raw = s_my_fixed_partition_sp_par_c_o_valid32a &
                                  s_my_fixed_partition_sp_par_c_o_valid32b &
                                  s_my_fixed_partition_sp_par_c_o_valid32c &
                                  s_my_fixed_partition_sp_par_c_o_valid32d;

// FOUR_SP bypasses multiplier_1, so delay partition-c by the bypassed multiplier latency.
always_ff @(posedge i_clk) begin : mux_4_foursp_align
  int i;
  if (!i_rst_n) begin
    s_mux_4_foursp_pipe <= '{default:'0};
    s_mux_4_foursp_valid_pipe <= '{default:'0};
  end
  else begin
    s_mux_4_foursp_pipe[0] <= s_mux_4_foursp_raw;
    s_mux_4_foursp_valid_pipe[0] <= s_mux_4_foursp_valid_raw;

    for (i = 1; i < SP_FPMULTIPLIER_MODULE_LATENCY; i++) begin
      s_mux_4_foursp_pipe[i] <= s_mux_4_foursp_pipe[i-1];
      s_mux_4_foursp_valid_pipe[i] <= s_mux_4_foursp_valid_pipe[i-1];
    end
  end
end

assign s_mux_4_foursp_aligned = s_mux_4_foursp_pipe[SP_FPMULTIPLIER_MODULE_LATENCY-1];
assign s_mux_4_foursp_valid_aligned = s_mux_4_foursp_valid_pipe[SP_FPMULTIPLIER_MODULE_LATENCY-1];

always_comb begin : mux_4
  case (`S)
    SINGLE_MODE: begin
      s_mux_4       = s_my_sp_fpmultiplier_1_jedi;
      s_mux_4_valid = s_my_sp_fpmultiplier_1_valid128_jedi;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_4       = s_my_sp_fpmultiplier_1_jedi;
      s_mux_4_valid = s_my_sp_fpmultiplier_1_valid64a_jedi &
                      s_my_sp_fpmultiplier_1_valid64b_jedi;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_4       = s_mux_4_foursp_aligned;
      s_mux_4_valid = s_mux_4_foursp_valid_aligned;

    end

    default: begin
      s_mux_4       = '0;
      s_mux_4_valid = '0;
    end
  endcase
end

float_metadata_t unused_metadata_3;
logic [127:0] s_my_sp_fpmultiplier_3_jedi;
logic s_my_sp_fpmultiplier_3_valid128_jedi;
logic s_my_sp_fpmultiplier_3_valid64a_jedi;
logic s_my_sp_fpmultiplier_3_valid64b_jedi;
logic s_my_sp_fpmultiplier_3_valid32a_jedi;
logic s_my_sp_fpmultiplier_3_valid32b_jedi;
logic s_my_sp_fpmultiplier_3_valid32c_jedi;
logic s_my_sp_fpmultiplier_3_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_fpmultiplier_3_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_3_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_3_debug;
sp_fpmultiplier #(
  .INTMUL_LATENCY(SP_FPMULTIPLIER_INTMUL_LATENCY),
  .SURROUNDING_LOGIC(SP_FPMULTIPLIER_SURROUNDING_LOGIC),
  .MODULE_LATENCY(SP_FPMULTIPLIER_MODULE_LATENCY),
  .DEBUG_PRINT_EN(0)
) my_sp_fpmultiplier_3 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_3/*not like it is useful anyway*/),
  .i_in_anikin(s_my_sp_fpmultiplier_0_jedi),
  .i_in_force(s_mux_4),
  .o_out_jedi(s_my_sp_fpmultiplier_3_jedi),
  .i_valid128_anikin(s_my_sp_fpmultiplier_0_valid128_jedi),
  .i_valid128_force(s_mux_4_valid),
  .i_valid64a_anikin(s_my_sp_fpmultiplier_0_valid64a_jedi),
  .i_valid64a_force(s_mux_4_valid),
  .i_valid64b_anikin(s_my_sp_fpmultiplier_0_valid64b_jedi),
  .i_valid64b_force(s_mux_4_valid),
  .i_valid32a_anikin(s_my_sp_fpmultiplier_0_valid32a_jedi),
  .i_valid32a_force(s_mux_4_valid),
  .i_valid32b_anikin(s_my_sp_fpmultiplier_0_valid32b_jedi),
  .i_valid32b_force(s_mux_4_valid),
  .i_valid32c_anikin(s_my_sp_fpmultiplier_0_valid32c_jedi),
  .i_valid32c_force(s_mux_4_valid),
  .i_valid32d_anikin(s_my_sp_fpmultiplier_0_valid32d_jedi),
  .i_valid32d_force(s_mux_4_valid),
  .o_valid128_jedi(s_my_sp_fpmultiplier_3_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_fpmultiplier_3_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_fpmultiplier_3_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_fpmultiplier_3_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_fpmultiplier_3_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_fpmultiplier_3_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_fpmultiplier_3_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_fpmultiplier_3_identifier),
  .o_error(s_my_sp_fpmultiplier_3_error),
  .o_debug(s_my_sp_fpmultiplier_3_debug)
);

float_metadata_t unused_metadata_4;
logic [127:0] s_my_sp_fpmultiplier_4_jedi;
logic s_my_sp_fpmultiplier_4_valid128_jedi;
logic s_my_sp_fpmultiplier_4_valid64a_jedi;
logic s_my_sp_fpmultiplier_4_valid64b_jedi;
logic s_my_sp_fpmultiplier_4_valid32a_jedi;
logic s_my_sp_fpmultiplier_4_valid32b_jedi;
logic s_my_sp_fpmultiplier_4_valid32c_jedi;
logic s_my_sp_fpmultiplier_4_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_fpmultiplier_4_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_4_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_fpmultiplier_4_debug;
logic unused_mul4_1, unused_mul4_2, unused_mul4_3, unused_mul4_4, unused_mul4_5, unused_mul4_6;
sp_fpmultiplier #(
  .INTMUL_LATENCY(SP_FPMULTIPLIER_INTMUL_LATENCY),
  .SURROUNDING_LOGIC(SP_FPMULTIPLIER_SURROUNDING_LOGIC),
  .MODULE_LATENCY(SP_FPMULTIPLIER_MODULE_LATENCY),
  .DEBUG_PRINT_EN(0)
) my_sp_fpmultiplier_4 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_4/*not like it is useful anyway*/),
  .i_in_anikin(s_my_sp_fpmultiplier_3_jedi),
  .i_in_force(s_mul2_for_mul4_aligned),
  .o_out_jedi(s_my_sp_fpmultiplier_4_jedi),
  .i_valid128_anikin(s_my_sp_fpmultiplier_3_valid128_jedi),
  .i_valid128_force(s_mul2_for_mul4_valid_aligned),
  .i_valid64a_anikin('0),
  .i_valid64a_force('0),
  .i_valid64b_anikin('0),
  .i_valid64b_force('0),
  .i_valid32a_anikin('0),
  .i_valid32a_force('0),
  .i_valid32b_anikin('0),
  .i_valid32b_force('0),
  .i_valid32c_anikin('0),
  .i_valid32c_force('0),
  .i_valid32d_anikin('0),
  .i_valid32d_force('0),
  .o_valid128_jedi(s_my_sp_fpmultiplier_4_valid128_jedi),
  .o_valid64a_jedi(unused_mul4_1),
  .o_valid64b_jedi(unused_mul4_2),
  .o_valid32a_jedi(unused_mul4_3),
  .o_valid32b_jedi(unused_mul4_4),
  .o_valid32c_jedi(unused_mul4_5),
  .o_valid32d_jedi(unused_mul4_6),
  .o_sanity_identifier(s_my_sp_fpmultiplier_4_identifier),
  .o_error(s_my_sp_fpmultiplier_4_error),
  .o_debug(s_my_sp_fpmultiplier_4_debug)
);

// Finish line subnormal type processing
`define SA (s_level2_metadata.float_type_a) // todo give this macro a better name
`define SB (s_level2_metadata.float_type_b) // todo give this macro a better name
`define SC (s_level2_metadata.float_type_c) // todo give this macro a better name
`define SD (s_level2_metadata.float_type_d) // todo give this macro a better name
`define BINARY128_POSZERO   (128'h0000_0000_0000_0000_0000_0000_0000_0000)
`define BINARY128_ONE       (128'h3FFF_0000_0000_0000_0000_0000_0000_0000)
`define BINARY128_POSINF    (128'h7FFF_0000_0000_0000_0000_0000_0000_0000)
`define BINARY128_NAN_POS   (128'h7FFF_8000_0000_0000_0000_0000_0000_0001)
`define BINARY64_POSZERO    (64'h0000_0000_0000_0000)
`define BINARY64_ONE        (64'h3FF0_0000_0000_0000)
`define BINARY64_POSINF     (64'h7FF0_0000_0000_0000)
`define BINARY64_NAN_POS    (64'h7FF8_0000_0000_0001)
`define BINARY32_POSZERO    (32'h0000_0000)
`define BINARY32_ONE        (32'h3F80_0000)
`define BINARY32_POSINF     (32'h7F80_0000)
`define BINARY32_NAN_POS    (32'h7FC0_0001)
logic [127:0] s_mul3_final_out;
always_comb begin : finish_line_subnormal_type_processing_mul3
  case (`S)
    TWO_SP_MODE: begin
      s_mul3_final_out[127:64] =  (`SA === ZERO)          ? `BINARY64_ONE     :
                                  (`SA === POS_INF)       ? `BINARY64_POSINF  :
                                  (`SA === NEG_INF)       ? `BINARY64_POSZERO :
                                  (`SA === NAN)           ? `BINARY64_NAN_POS :
                                  (`SA === POS_DENORMAL)  ? `BINARY64_ONE     :
                                  (`SA === NEG_DENORMAL)  ? `BINARY64_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[127:64];
      s_mul3_final_out[63:0]   =  (`SB === ZERO)          ? `BINARY64_ONE     :
                                  (`SB === POS_INF)       ? `BINARY64_POSINF  :
                                  (`SB === NEG_INF)       ? `BINARY64_POSZERO :
                                  (`SB === NAN)           ? `BINARY64_NAN_POS :
                                  (`SB === POS_DENORMAL)  ? `BINARY64_ONE     :
                                  (`SB === NEG_DENORMAL)  ? `BINARY64_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[63:0];
    end

    FOUR_SP_MODE: begin
      s_mul3_final_out[127:96] =  (`SA === ZERO)          ? `BINARY32_ONE     :
                                  (`SA === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SA === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SA === NAN)           ? `BINARY32_NAN_POS :
                                  (`SA === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SA === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[127:96];

      s_mul3_final_out[95:64] =   (`SB === ZERO)          ? `BINARY32_ONE     :
                                  (`SB === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SB === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SB === NAN)           ? `BINARY32_NAN_POS :
                                  (`SB === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SB === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[95:64];

      s_mul3_final_out[63:32] =   (`SC === ZERO)          ? `BINARY32_ONE     :
                                  (`SC === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SC === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SC === NAN)           ? `BINARY32_NAN_POS :
                                  (`SC === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SC === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[63:32];

      s_mul3_final_out[31:0] =    (`SD === ZERO)          ? `BINARY32_ONE     :
                                  (`SD === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SD === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SD === NAN)           ? `BINARY32_NAN_POS :
                                  (`SD === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SD === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_fpmultiplier_3_jedi[31:0];
    end

    default: begin
      s_mul3_final_out = '0;
    end
  endcase
end

logic [127:0] s_mul4_final_out;
always_comb begin : finish_line_subnormal_type_processing_mul4
  case (`S)
    SINGLE_MODE: begin
      s_mul4_final_out =  (`SA === ZERO)          ? `BINARY128_ONE      :
                          (`SA === POS_INF)       ? `BINARY128_POSINF   :
                          (`SA === NEG_INF)       ? `BINARY128_POSZERO  :
                          (`SA === NAN)           ? `BINARY128_NAN_POS  :
                          (`SA === POS_DENORMAL)  ? `BINARY128_ONE      :  // For now we treat denormal as zero, todo
                          (`SA === NEG_DENORMAL)  ? `BINARY128_ONE      :  // For now we treat denormal as zero, todo
                          s_my_sp_fpmultiplier_4_jedi;
    end

    default: begin
      s_mul4_final_out = '0;
    end
  endcase
end

//=====================================================================================
// Final assignment
//=====================================================================================
assign o_exp_x              = `S === SINGLE_MODE  ?  s_mul4_final_out :
                              `S === TWO_SP_MODE  ?  s_mul3_final_out :
                              `S === FOUR_SP_MODE ?  s_mul3_final_out :
                              '0;
assign o_ready              = '1; //todo
assign o_valid              = `S === SINGLE_MODE  ?  s_my_sp_fpmultiplier_4_valid128_jedi     :
                              `S === TWO_SP_MODE  ?  s_my_sp_fpmultiplier_3_valid64a_jedi &
                                                     s_my_sp_fpmultiplier_3_valid64b_jedi     :
                              `S === FOUR_SP_MODE ?  s_my_sp_fpmultiplier_3_valid32a_jedi &
                                                     s_my_sp_fpmultiplier_3_valid32b_jedi &
                                                     s_my_sp_fpmultiplier_3_valid32c_jedi &
                                                     s_my_sp_fpmultiplier_3_valid32d_jedi     :
                              '0;
assign o_sanity_identifier  = MODULE_IDENTIFIER;
assign o_error              = s_my_float_to_fixed_error &
                              s_my_fixed_partition_sp_par_a_error &
                              s_my_fixed_partition_sp_par_b_error &
                              s_my_fixed_partition_sp_par_c_error &
                              s_my_fixed_partition_sp_par_d_error &
                              s_my_fixed_partition_sp_par_e_error &
                              s_my_fixed128_partitionf_ts_error &
                              s_my_fixed64_partitionf_ts_a_error &
                              s_my_fixed64_partitionf_ts_b_error &
                              s_my_sp_fpmultiplier_0_error &
                              s_my_sp_fpmultiplier_1_error &
                              s_my_sp_fpmultiplier_2_error &
                              s_my_sp_fpmultiplier_3_error &
                              s_my_sp_fpmultiplier_4_error;
assign o_debug              = '0;

`ifndef RUNNING_VIVADO_SYNTHESIS
// Temp, maybe
assign ds_my_float_to_fixed_fixed = s_my_float_to_fixed_fixed;
assign ds_my_fixed_partition_sp_par_a_exp_a128 = s_my_fixed_partition_sp_par_a_exp_a128;
assign ds_my_fixed_partition_sp_par_a_exp_64a = s_my_fixed_partition_sp_par_a_exp_64a;
assign ds_my_fixed_partition_sp_par_a_exp_64b = s_my_fixed_partition_sp_par_a_exp_64b;
assign ds_my_fixed_partition_sp_par_a_exp_32a = s_my_fixed_partition_sp_par_a_exp_32a;
assign ds_my_fixed_partition_sp_par_a_exp_32b = s_my_fixed_partition_sp_par_a_exp_32b;
assign ds_my_fixed_partition_sp_par_a_exp_32c = s_my_fixed_partition_sp_par_a_exp_32c;
assign ds_my_fixed_partition_sp_par_a_exp_32d = s_my_fixed_partition_sp_par_a_exp_32d;
assign ds_my_fixed_partition_sp_par_b_exp_a128 = s_my_fixed_partition_sp_par_b_exp_a128;
assign ds_my_fixed_partition_sp_par_b_exp_64a = s_my_fixed_partition_sp_par_b_exp_64a;
assign ds_my_fixed_partition_sp_par_b_exp_64b = s_my_fixed_partition_sp_par_b_exp_64b;
assign ds_my_fixed_partition_sp_par_b_exp_32a = s_my_fixed_partition_sp_par_b_exp_32a;
assign ds_my_fixed_partition_sp_par_b_exp_32b = s_my_fixed_partition_sp_par_b_exp_32b;
assign ds_my_fixed_partition_sp_par_b_exp_32c = s_my_fixed_partition_sp_par_b_exp_32c;
assign ds_my_fixed_partition_sp_par_b_exp_32d = s_my_fixed_partition_sp_par_b_exp_32d;
assign ds_my_fixed_partition_sp_par_c_exp_a128 = s_my_fixed_partition_sp_par_c_exp_a128;
assign ds_my_fixed_partition_sp_par_c_exp_64a = s_my_fixed_partition_sp_par_c_exp_64a;
assign ds_my_fixed_partition_sp_par_c_exp_64b = s_my_fixed_partition_sp_par_c_exp_64b;
assign ds_my_fixed_partition_sp_par_c_exp_32a = s_my_fixed_partition_sp_par_c_exp_32a;
assign ds_my_fixed_partition_sp_par_c_exp_32b = s_my_fixed_partition_sp_par_c_exp_32b;
assign ds_my_fixed_partition_sp_par_c_exp_32c = s_my_fixed_partition_sp_par_c_exp_32c;
assign ds_my_fixed_partition_sp_par_c_exp_32d = s_my_fixed_partition_sp_par_c_exp_32d;
assign ds_my_fixed_partition_sp_par_d_exp_a128 = s_my_fixed_partition_sp_par_d_exp_a128;
assign ds_my_fixed_partition_sp_par_e_exp_a128 = s_my_fixed_partition_sp_par_e_exp_a128;
assign ds_my_fixed128_partitionf_ts_exp_f128 = s_my_fixed128_partitionf_ts_exp_f128;
assign ds_my_fixed64_partitionf_ts_a_exp_f64a = s_my_fixed64_partitionf_ts_a_exp_f64a;
assign ds_my_fixed64_partitionf_ts_b_exp_f64b = s_my_fixed64_partitionf_ts_b_exp_f64b;
assign ds_mux_0 = s_mux_0;
assign ds_mux_1 = s_mux_1;
assign ds_mux_2 = s_mux_2;
assign ds_mux_3 = s_mux_3;
assign ds_my_sp_fpmultiplier_0_jedi = s_my_sp_fpmultiplier_0_jedi;
assign ds_my_sp_fpmultiplier_1_jedi = s_my_sp_fpmultiplier_1_jedi;
assign ds_my_sp_fpmultiplier_2_jedi = s_my_sp_fpmultiplier_2_jedi;
assign ds_mux_4 = s_mux_4;
assign ds_my_sp_fpmultiplier_3_jedi = s_my_sp_fpmultiplier_3_jedi;
assign ds_my_sp_fpmultiplier_4_jedi = s_my_sp_fpmultiplier_4_jedi;
assign ds_mul3_final_out = s_mul3_final_out;
assign ds_mul4_final_out = s_mul4_final_out;
assign ds_my_float_to_fixed_metadata = s_my_float_to_fixed_metadata;

assign ds_my_float_to_fixed_o_valid = s_my_float_to_fixed_o_valid;
assign ds_my_fixed_partition_sp_par_a_o_valid128 = s_my_fixed_partition_sp_par_a_o_valid128;
assign ds_my_fixed_partition_sp_par_a_o_valid64a = s_my_fixed_partition_sp_par_a_o_valid64a;
assign ds_my_fixed_partition_sp_par_a_o_valid64b = s_my_fixed_partition_sp_par_a_o_valid64b;
assign ds_my_fixed_partition_sp_par_a_o_valid32a = s_my_fixed_partition_sp_par_a_o_valid32a;
assign ds_my_fixed_partition_sp_par_a_o_valid32b = s_my_fixed_partition_sp_par_a_o_valid32b;
assign ds_my_fixed_partition_sp_par_a_o_valid32c = s_my_fixed_partition_sp_par_a_o_valid32c;
assign ds_my_fixed_partition_sp_par_a_o_valid32d = s_my_fixed_partition_sp_par_a_o_valid32d;
assign ds_my_fixed_partition_sp_par_b_o_valid128 = s_my_fixed_partition_sp_par_b_o_valid128;
assign ds_my_fixed_partition_sp_par_b_o_valid64a = s_my_fixed_partition_sp_par_b_o_valid64a;
assign ds_my_fixed_partition_sp_par_b_o_valid64b = s_my_fixed_partition_sp_par_b_o_valid64b;
assign ds_my_fixed_partition_sp_par_b_o_valid32a = s_my_fixed_partition_sp_par_b_o_valid32a;
assign ds_my_fixed_partition_sp_par_b_o_valid32b = s_my_fixed_partition_sp_par_b_o_valid32b;
assign ds_my_fixed_partition_sp_par_b_o_valid32c = s_my_fixed_partition_sp_par_b_o_valid32c;
assign ds_my_fixed_partition_sp_par_b_o_valid32d = s_my_fixed_partition_sp_par_b_o_valid32d;
assign ds_my_fixed_partition_sp_par_c_o_valid128 = s_my_fixed_partition_sp_par_c_o_valid128;
assign ds_my_fixed_partition_sp_par_c_o_valid64a = s_my_fixed_partition_sp_par_c_o_valid64a;
assign ds_my_fixed_partition_sp_par_c_o_valid64b = s_my_fixed_partition_sp_par_c_o_valid64b;
assign ds_my_fixed_partition_sp_par_c_o_valid32a = s_my_fixed_partition_sp_par_c_o_valid32a;
assign ds_my_fixed_partition_sp_par_c_o_valid32b = s_my_fixed_partition_sp_par_c_o_valid32b;
assign ds_my_fixed_partition_sp_par_c_o_valid32c = s_my_fixed_partition_sp_par_c_o_valid32c;
assign ds_my_fixed_partition_sp_par_c_o_valid32d = s_my_fixed_partition_sp_par_c_o_valid32d;
assign ds_my_fixed_partition_sp_par_d_o_valid128 = s_my_fixed_partition_sp_par_d_o_valid128;
assign ds_my_fixed_partition_sp_par_e_o_valid128 = s_my_fixed_partition_sp_par_e_o_valid128;
assign ds_my_fixed128_partitionf_ts_o_valid = s_my_fixed128_partitionf_ts_o_valid;
assign ds_my_fixed64_partitionf_ts_a_o_valid = s_my_fixed64_partitionf_ts_a_o_valid;
assign ds_my_fixed64_partitionf_ts_b_o_valid = s_my_fixed64_partitionf_ts_b_o_valid;
assign ds_my_sp_fpmultiplier_0_valid128_jedi = s_my_sp_fpmultiplier_0_valid128_jedi;
assign ds_my_sp_fpmultiplier_0_valid64a_jedi = s_my_sp_fpmultiplier_0_valid64a_jedi;
assign ds_my_sp_fpmultiplier_0_valid64b_jedi = s_my_sp_fpmultiplier_0_valid64b_jedi;
assign ds_my_sp_fpmultiplier_0_valid32a_jedi = s_my_sp_fpmultiplier_0_valid32a_jedi;
assign ds_my_sp_fpmultiplier_0_valid32b_jedi = s_my_sp_fpmultiplier_0_valid32b_jedi;
assign ds_my_sp_fpmultiplier_0_valid32c_jedi = s_my_sp_fpmultiplier_0_valid32c_jedi;
assign ds_my_sp_fpmultiplier_0_valid32d_jedi = s_my_sp_fpmultiplier_0_valid32d_jedi;
assign ds_my_sp_fpmultiplier_1_valid128_jedi = s_my_sp_fpmultiplier_1_valid128_jedi;
assign ds_my_sp_fpmultiplier_1_valid64a_jedi = s_my_sp_fpmultiplier_1_valid64a_jedi;
assign ds_my_sp_fpmultiplier_1_valid64b_jedi = s_my_sp_fpmultiplier_1_valid64b_jedi;
assign ds_my_sp_fpmultiplier_2_valid128_jedi = s_my_sp_fpmultiplier_2_valid128_jedi;
assign ds_my_sp_fpmultiplier_3_valid128_jedi = s_my_sp_fpmultiplier_3_valid128_jedi;
assign ds_my_sp_fpmultiplier_3_valid64a_jedi = s_my_sp_fpmultiplier_3_valid64a_jedi;
assign ds_my_sp_fpmultiplier_3_valid64b_jedi = s_my_sp_fpmultiplier_3_valid64b_jedi;
assign ds_my_sp_fpmultiplier_3_valid32a_jedi = s_my_sp_fpmultiplier_3_valid32a_jedi;
assign ds_my_sp_fpmultiplier_3_valid32b_jedi = s_my_sp_fpmultiplier_3_valid32b_jedi;
assign ds_my_sp_fpmultiplier_3_valid32c_jedi = s_my_sp_fpmultiplier_3_valid32c_jedi;
assign ds_my_sp_fpmultiplier_3_valid32d_jedi = s_my_sp_fpmultiplier_3_valid32d_jedi;
assign ds_my_sp_fpmultiplier_4_valid128_jedi = s_my_sp_fpmultiplier_4_valid128_jedi;
`endif

endmodule // module SPEX128_top #()
