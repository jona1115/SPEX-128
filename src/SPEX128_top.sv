/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/?/2025
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
 *    1.00  |  Jonathan  |  11/?/2025   |  Birth of this file
 * 
 *******************************************************************/

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

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug,

  // These are temporary... probably
  output logic [127:0] os_my_float_to_fixed_fixed,
  output logic [127:0] os_mux_0,
  output logic [127:0] os_mux_1,
  output logic [127:0] os_mux_2,
  output logic [127:0] os_mux_3,
  output logic [127:0] os_my_sp_multiplier_0_jedi,
  output logic [127:0] os_my_sp_multiplier_1_jedi,
  output logic [127:0] os_my_sp_multiplier_2_jedi,
  output logic [127:0] os_mux_4,
  output logic [127:0] os_my_sp_multiplier_3_jedi,
  output logic [127:0] os_my_sp_multiplier_4_jedi,
  output binary128_t os_my_fixed128_64_partitiona_exp_a128,
  output binary128_t os_my_fixed128_64_partitionb_exp_a128,
  output binary128_t os_my_fixed128_64_partitionc_exp_a128,
  output binary128_t os_my_fixed128_partitiond_exp_d128,
  output binary128_t os_my_fixed128_partitione_exp_d128,
  output binary128_t os_my_fixed128_partitionf_ts_exp_f128,
  output float_metadata_t os_my_float_to_fixed_metadata,
  output logic os_my_float_to_fixed_o_valid,
  output logic os_my_fixed128_partitiond_o_valid,
  output logic os_my_fixed128_partitione_o_valid,
  output logic os_my_fixed128_partitionf_ts_o_valid,
  output logic os_my_fixed64_partitionf_ts_a_o_valid,
  output logic os_my_fixed64_partitionf_ts_b_o_valid,
  output logic os_my_fixed32_partitiona_a_o_valid,
  output logic os_my_fixed32_partitiona_b_o_valid,
  output logic os_my_fixed32_partitiona_c_o_valid,
  output logic os_my_fixed32_partitiona_d_o_valid,
  output logic os_my_fixed32_partitionb_a_o_valid,
  output logic os_my_fixed32_partitionb_b_o_valid,
  output logic os_my_fixed32_partitionb_c_o_valid,
  output logic os_my_fixed32_partitionb_d_o_valid,
  output logic os_my_fixed32_partitionc_a_o_valid,
  output logic os_my_fixed32_partitionc_b_o_valid,
  output logic os_my_fixed32_partitionc_c_o_valid,
  output logic os_my_fixed32_partitionc_d_o_valid
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic s_GND;

//=====================================================================================
// Module body
//=====================================================================================
// Signal naming convention: s_<module-name>_<signal-name>
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
binary64_t        s_my_fixed_partition_sp_par_a_exp_a64a;
binary64_t        s_my_fixed_partition_sp_par_a_exp_a64b;
binary32_t        s_my_fixed_partition_sp_par_a_exp_a32a;
binary32_t        s_my_fixed_partition_sp_par_a_exp_a32b;
binary32_t        s_my_fixed_partition_sp_par_a_exp_a32c;
binary32_t        s_my_fixed_partition_sp_par_a_exp_a32d;
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
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .ADDR_BITS_128(10),
  .ADDR_BITS_64(10),
  .ADDR_BITS_32(10),
  .INIT_128_POS_FILE("fixed128_0a_partition.hex"),
  .INIT_128_NEG_FILE("fixed128_1a_partition.hex")
) my_fixed_partition_sp_par_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_a_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[127:117]),
  .i_lane_64a(s_my_float_to_fixed_fixed[127:117]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_64b(s_my_float_to_fixed_fixed[63:53]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32a(s_my_float_to_fixed_fixed[127:117]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32b(s_my_float_to_fixed_fixed[95:85]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32c(s_my_float_to_fixed_fixed[63:53]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32d(s_my_float_to_fixed_fixed[31:21]), // not really tested since the TWO/FOUR sp mode test are never passed
  .o_exp_a128(s_my_fixed_partition_sp_par_a_exp_a128),
  .o_exp_a64a(s_my_fixed_partition_sp_par_a_exp_a64a),
  .o_exp_a64b(s_my_fixed_partition_sp_par_a_exp_a64b),
  .o_exp_a32a(s_my_fixed_partition_sp_par_a_exp_a32a),
  .o_exp_a32b(s_my_fixed_partition_sp_par_a_exp_a32b),
  .o_exp_a32c(s_my_fixed_partition_sp_par_a_exp_a32c),
  .o_exp_a32d(s_my_fixed_partition_sp_par_a_exp_a32d),
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
binary64_t        s_my_fixed_partition_sp_par_b_exp_a64a;
binary64_t        s_my_fixed_partition_sp_par_b_exp_a64b;
binary32_t        s_my_fixed_partition_sp_par_b_exp_a32a;
binary32_t        s_my_fixed_partition_sp_par_b_exp_a32b;
binary32_t        s_my_fixed_partition_sp_par_b_exp_a32c;
binary32_t        s_my_fixed_partition_sp_par_b_exp_a32d;
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
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .ADDR_BITS_128(13),
  .ADDR_BITS_64(13),
  .ADDR_BITS_32(10),
  .INIT_128_FILE("fixed128_b_partition.hex")
) my_fixed_partition_sp_par_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_b_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[116:104]),
  .i_lane_64a(s_my_float_to_fixed_fixed[116:104]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_64b(s_my_float_to_fixed_fixed[52:40]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32a(s_my_float_to_fixed_fixed[116:107]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32b(s_my_float_to_fixed_fixed[84:75]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32c(s_my_float_to_fixed_fixed[52:43]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32d(s_my_float_to_fixed_fixed[20:11]), // not really tested since the TWO/FOUR sp mode test are never passed
  .o_exp_a128(s_my_fixed_partition_sp_par_b_exp_a128),
  .o_exp_a64a(s_my_fixed_partition_sp_par_b_exp_a64a),
  .o_exp_a64b(s_my_fixed_partition_sp_par_b_exp_a64b),
  .o_exp_a32a(s_my_fixed_partition_sp_par_b_exp_a32a),
  .o_exp_a32b(s_my_fixed_partition_sp_par_b_exp_a32b),
  .o_exp_a32c(s_my_fixed_partition_sp_par_b_exp_a32c),
  .o_exp_a32d(s_my_fixed_partition_sp_par_b_exp_a32d),
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
binary64_t        s_my_fixed_partition_sp_par_c_exp_a64a;
binary64_t        s_my_fixed_partition_sp_par_c_exp_a64b;
binary32_t        s_my_fixed_partition_sp_par_c_exp_a32a;
binary32_t        s_my_fixed_partition_sp_par_c_exp_a32b;
binary32_t        s_my_fixed_partition_sp_par_c_exp_a32c;
binary32_t        s_my_fixed_partition_sp_par_c_exp_a32d;
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
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .ADDR_BITS_128(13),
  .ADDR_BITS_64(13),
  .ADDR_BITS_32(10),
  .INIT_128_FILE("fixed128_c_partition.hex")
) my_fixed_partition_sp_par_c (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata),
  .o_metadata(s_my_fixed_partition_sp_par_c_metadata),
  .i_lane_128(s_my_float_to_fixed_fixed[103:91]),
  .i_lane_64a(s_my_float_to_fixed_fixed[103:91]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_64b(s_my_float_to_fixed_fixed[39:27]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32a(s_my_float_to_fixed_fixed[106:96]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32b(s_my_float_to_fixed_fixed[74:64]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32c(s_my_float_to_fixed_fixed[42:32]), // not really tested since the TWO/FOUR sp mode test are never passed
  .i_lane_32d(s_my_float_to_fixed_fixed[10:0]), // not really tested since the TWO/FOUR sp mode test are never passed
  .o_exp_a128(s_my_fixed_partition_sp_par_c_exp_a128),
  .o_exp_a64a(s_my_fixed_partition_sp_par_c_exp_a64a),
  .o_exp_a64b(s_my_fixed_partition_sp_par_c_exp_a64b),
  .o_exp_a32a(s_my_fixed_partition_sp_par_c_exp_a32a),
  .o_exp_a32b(s_my_fixed_partition_sp_par_c_exp_a32b),
  .o_exp_a32c(s_my_fixed_partition_sp_par_c_exp_a32c),
  .o_exp_a32d(s_my_fixed_partition_sp_par_c_exp_a32d),
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

binary128_t s_my_fixed128_partitiond_exp_d128;
logic       s_my_fixed128_partitiond_o_valid;
// Metadata
logic [3:0] s_my_fixed128_partitiond_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitiond_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitiond_debug;
fixed128_partitiond #() my_fixed128_partitiond (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_d(s_my_float_to_fixed_fixed[90:78]),
  .o_exp_d(s_my_fixed128_partitiond_exp_d128),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed128_partitiond_o_valid),
  .o_sanity_identifier(s_my_fixed128_partitiond_identifier),
  .o_error(s_my_fixed128_partitiond_error),
  .o_debug(s_my_fixed128_partitiond_debug)
);

binary128_t s_my_fixed128_partitione_exp_d128;
logic       s_my_fixed128_partitione_o_valid;
// Metadata
logic [3:0] s_my_fixed128_partitione_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitione_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_partitione_debug;
fixed128_partitione #() my_fixed128_partitione (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_e(s_my_float_to_fixed_fixed[77:65]),
  .o_exp_e(s_my_fixed128_partitione_exp_d128),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed128_partitione_o_valid),
  .o_sanity_identifier(s_my_fixed128_partitione_identifier),
  .o_error(s_my_fixed128_partitione_error),
  .o_debug(s_my_fixed128_partitione_debug)
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
      s_mux_0       = {s_my_fixed_partition_sp_par_a_exp_a64a, 
                       s_my_fixed_partition_sp_par_a_exp_a64b};
      s_mux_0_valid = s_my_fixed_partition_sp_par_a_o_valid64a &
                      s_my_fixed_partition_sp_par_a_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_0       = {s_my_fixed_partition_sp_par_a_exp_a32a,
                       s_my_fixed_partition_sp_par_a_exp_a32b,
                       s_my_fixed_partition_sp_par_a_exp_a32c,
                       s_my_fixed_partition_sp_par_a_exp_a32d};
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
      s_mux_1       = {s_my_fixed_partition_sp_par_b_exp_a64a, 
                       s_my_fixed_partition_sp_par_b_exp_a64b};
      s_mux_1_valid = s_my_fixed_partition_sp_par_b_o_valid64a &
                      s_my_fixed_partition_sp_par_b_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_1       = {s_my_fixed_partition_sp_par_b_exp_a32a,
                       s_my_fixed_partition_sp_par_b_exp_a32b,
                       s_my_fixed_partition_sp_par_b_exp_a32c,
                       s_my_fixed_partition_sp_par_b_exp_a32d};
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
      s_mux_2       = {s_my_fixed_partition_sp_par_c_exp_a64a, 
                       s_my_fixed_partition_sp_par_c_exp_a64b};
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
      s_mux_3       = s_my_fixed128_partitiond_exp_d128;
      s_mux_3_valid = s_my_fixed128_partitiond_o_valid;
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
logic [127:0] s_my_sp_multiplier_0_jedi;
logic s_my_sp_multiplier_0_valid128_jedi;
logic s_my_sp_multiplier_0_valid64a_jedi;
logic s_my_sp_multiplier_0_valid64b_jedi;
logic s_my_sp_multiplier_0_valid32a_jedi;
logic s_my_sp_multiplier_0_valid32b_jedi;
logic s_my_sp_multiplier_0_valid32c_jedi;
logic s_my_sp_multiplier_0_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_multiplier_0_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_0_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_0_debug;
sp_multiplier #() my_sp_multiplier_0 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_0/*not like it is useful anyway*/),
  .i_in_anikin(s_mux_0),
  .i_in_force(s_mux_1),
  .o_out_jedi(s_my_sp_multiplier_0_jedi),
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
  .o_valid128_jedi(s_my_sp_multiplier_0_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_multiplier_0_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_0_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_multiplier_0_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_multiplier_0_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_multiplier_0_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_multiplier_0_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_multiplier_0_identifier),
  .o_error(s_my_sp_multiplier_0_error),
  .o_debug(s_my_sp_multiplier_0_debug)
);

float_metadata_t unused_metadata_1;
logic [127:0] s_my_sp_multiplier_1_jedi;
logic s_my_sp_multiplier_1_valid128_jedi;
logic s_my_sp_multiplier_1_valid64a_jedi;
logic s_my_sp_multiplier_1_valid64b_jedi;
logic s_my_sp_multiplier_1_valid32a_jedi;
logic s_my_sp_multiplier_1_valid32b_jedi;
logic s_my_sp_multiplier_1_valid32c_jedi;
logic s_my_sp_multiplier_1_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_multiplier_1_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_1_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_1_debug;
logic unused_mul1_1, unused_mul1_2, unused_mul1_3, unused_mul1_4;
sp_multiplier #() my_sp_multiplier_1 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_1/*not like it is useful anyway*/),
  .i_in_anikin(s_mux_2),
  .i_in_force(s_mux_3),
  .o_out_jedi(s_my_sp_multiplier_1_jedi),
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
  .o_valid128_jedi(s_my_sp_multiplier_1_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_multiplier_1_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_1_valid64b_jedi),
  .o_valid32a_jedi(unused_mul1_1),
  .o_valid32b_jedi(unused_mul1_2),
  .o_valid32c_jedi(unused_mul1_3),
  .o_valid32d_jedi(unused_mul1_4),
  .o_sanity_identifier(s_my_sp_multiplier_1_identifier),
  .o_error(s_my_sp_multiplier_1_error),
  .o_debug(s_my_sp_multiplier_1_debug)
);

float_metadata_t unused_metadata_2;
logic [127:0] s_my_sp_multiplier_2_jedi;
logic s_my_sp_multiplier_2_valid128_jedi;
logic s_my_sp_multiplier_2_valid64a_jedi;
logic s_my_sp_multiplier_2_valid64b_jedi;
logic s_my_sp_multiplier_2_valid32a_jedi;
logic s_my_sp_multiplier_2_valid32b_jedi;
logic s_my_sp_multiplier_2_valid32c_jedi;
logic s_my_sp_multiplier_2_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_multiplier_2_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_2_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_2_debug;
logic unused_mul2_1, unused_mul2_2, unused_mul2_3, unused_mul2_4, unused_mul2_5, unused_mul2_6;
sp_multiplier #() my_sp_multiplier_2 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_2/*not like it is useful anyway*/),
  .i_in_anikin(s_my_fixed128_partitione_exp_d128),
  .i_in_force(s_my_fixed128_partitionf_ts_exp_f128),
  .o_out_jedi(s_my_sp_multiplier_2_jedi),
  .i_valid128_anikin(s_my_fixed128_partitione_o_valid),
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
  .o_valid128_jedi(s_my_sp_multiplier_2_valid128_jedi),
  .o_valid64a_jedi(unused_mul2_1),
  .o_valid64b_jedi(unused_mul2_2),
  .o_valid32a_jedi(unused_mul2_3),
  .o_valid32b_jedi(unused_mul2_4),
  .o_valid32c_jedi(unused_mul2_5),
  .o_valid32d_jedi(unused_mul2_6),
  .o_sanity_identifier(s_my_sp_multiplier_2_identifier),
  .o_error(s_my_sp_multiplier_2_error),
  .o_debug(s_my_sp_multiplier_2_debug)
);

logic [127:0] s_mux_4;
logic         s_mux_4_valid;
always_comb begin : mux_4
  case (`S)
    SINGLE_MODE: begin
      s_mux_4       = s_my_sp_multiplier_1_jedi;
      s_mux_4_valid = s_my_sp_multiplier_1_valid128_jedi;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_4       = s_my_sp_multiplier_1_jedi;
      s_mux_4_valid = s_my_sp_multiplier_2_valid64a_jedi &
                      s_my_sp_multiplier_2_valid64b_jedi;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_4       = {s_my_fixed_partition_sp_par_c_exp_a32a,
                       s_my_fixed_partition_sp_par_c_exp_a32b,
                       s_my_fixed_partition_sp_par_c_exp_a32c,
                       s_my_fixed_partition_sp_par_c_exp_a32d};
      s_mux_4_valid = s_my_fixed_partition_sp_par_c_o_valid32a &
                      s_my_fixed_partition_sp_par_c_o_valid32b &
                      s_my_fixed_partition_sp_par_c_o_valid32c &
                      s_my_fixed_partition_sp_par_c_o_valid32d;

    end

    default: begin
      s_mux_4       = '0;
      s_mux_4_valid = '0;
    end
  endcase
end

float_metadata_t unused_metadata_3;
logic [127:0] s_my_sp_multiplier_3_jedi;
logic s_my_sp_multiplier_3_valid128_jedi;
logic s_my_sp_multiplier_3_valid64a_jedi;
logic s_my_sp_multiplier_3_valid64b_jedi;
logic s_my_sp_multiplier_3_valid32a_jedi;
logic s_my_sp_multiplier_3_valid32b_jedi;
logic s_my_sp_multiplier_3_valid32c_jedi;
logic s_my_sp_multiplier_3_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_multiplier_3_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_3_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_3_debug;
sp_multiplier #() my_sp_multiplier_3 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_3/*not like it is useful anyway*/),
  .i_in_anikin(s_my_sp_multiplier_0_jedi),
  .i_in_force(s_mux_4),
  .o_out_jedi(s_my_sp_multiplier_3_jedi),
  .i_valid128_anikin(s_my_sp_multiplier_0_valid128_jedi),
  .i_valid128_force(s_mux_4_valid),
  .i_valid64a_anikin(s_my_sp_multiplier_0_valid64a_jedi),
  .i_valid64a_force(s_mux_4_valid),
  .i_valid64b_anikin(s_my_sp_multiplier_0_valid64b_jedi),
  .i_valid64b_force(s_mux_4_valid),
  .i_valid32a_anikin(s_my_sp_multiplier_0_valid32a_jedi),
  .i_valid32a_force(s_mux_4_valid),
  .i_valid32b_anikin(s_my_sp_multiplier_0_valid32b_jedi),
  .i_valid32b_force(s_mux_4_valid),
  .i_valid32c_anikin(s_my_sp_multiplier_0_valid32c_jedi),
  .i_valid32c_force(s_mux_4_valid),
  .i_valid32d_anikin(s_my_sp_multiplier_0_valid32d_jedi),
  .i_valid32d_force(s_mux_4_valid),
  .o_valid128_jedi(s_my_sp_multiplier_3_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_multiplier_3_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_3_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_multiplier_3_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_multiplier_3_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_multiplier_3_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_multiplier_3_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_multiplier_3_identifier),
  .o_error(s_my_sp_multiplier_3_error),
  .o_debug(s_my_sp_multiplier_3_debug)
);

float_metadata_t unused_metadata_4;
logic [127:0] s_my_sp_multiplier_4_jedi;
logic s_my_sp_multiplier_4_valid128_jedi;
logic s_my_sp_multiplier_4_valid64a_jedi;
logic s_my_sp_multiplier_4_valid64b_jedi;
logic s_my_sp_multiplier_4_valid32a_jedi;
logic s_my_sp_multiplier_4_valid32b_jedi;
logic s_my_sp_multiplier_4_valid32c_jedi;
logic s_my_sp_multiplier_4_valid32d_jedi;
// Metadata
logic [3:0] s_my_sp_multiplier_4_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_4_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_sp_multiplier_4_debug;
logic unused_mul4_1, unused_mul4_2, unused_mul4_3, unused_mul4_4, unused_mul4_5, unused_mul4_6;
sp_multiplier #() my_sp_multiplier_4 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_level2_metadata),
  .o_metadata(unused_metadata_4/*not like it is useful anyway*/),
  .i_in_anikin(s_my_sp_multiplier_3_jedi),
  .i_in_force(s_my_sp_multiplier_2_jedi),
  .o_out_jedi(s_my_sp_multiplier_4_jedi),
  .i_valid128_anikin(s_my_sp_multiplier_3_valid128_jedi),
  .i_valid128_force(s_my_sp_multiplier_2_valid128_jedi),
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
  .o_valid128_jedi(s_my_sp_multiplier_4_valid128_jedi),
  .o_valid64a_jedi(unused_mul4_1),
  .o_valid64b_jedi(unused_mul4_2),
  .o_valid32a_jedi(unused_mul4_3),
  .o_valid32b_jedi(unused_mul4_4),
  .o_valid32c_jedi(unused_mul4_5),
  .o_valid32d_jedi(unused_mul4_6),
  .o_sanity_identifier(s_my_sp_multiplier_4_identifier),
  .o_error(s_my_sp_multiplier_4_error),
  .o_debug(s_my_sp_multiplier_4_debug)
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
                                  s_my_sp_multiplier_3_jedi[127:64];
      s_mul3_final_out[63:0]   =  (`SB === ZERO)          ? `BINARY64_ONE     :
                                  (`SB === POS_INF)       ? `BINARY64_POSINF  :
                                  (`SB === NEG_INF)       ? `BINARY64_POSZERO :
                                  (`SB === NAN)           ? `BINARY64_NAN_POS :
                                  (`SB === POS_DENORMAL)  ? `BINARY64_ONE     :
                                  (`SB === NEG_DENORMAL)  ? `BINARY64_ONE     :
                                  s_my_sp_multiplier_3_jedi[63:0];
    end

    FOUR_SP_MODE: begin
      s_mul3_final_out[127:96] =  (`SA === ZERO)          ? `BINARY32_ONE     :
                                  (`SA === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SA === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SA === NAN)           ? `BINARY32_NAN_POS :
                                  (`SA === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SA === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_multiplier_3_jedi[127:96];

      s_mul3_final_out[95:64] =   (`SB === ZERO)          ? `BINARY32_ONE     :
                                  (`SB === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SB === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SB === NAN)           ? `BINARY32_NAN_POS :
                                  (`SB === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SB === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_multiplier_3_jedi[95:64];

      s_mul3_final_out[63:32] =   (`SC === ZERO)          ? `BINARY32_ONE     :
                                  (`SC === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SC === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SC === NAN)           ? `BINARY32_NAN_POS :
                                  (`SC === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SC === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_multiplier_3_jedi[63:32];

      s_mul3_final_out[31:0] =    (`SD === ZERO)          ? `BINARY32_ONE     :
                                  (`SD === POS_INF)       ? `BINARY32_POSINF  :
                                  (`SD === NEG_INF)       ? `BINARY32_POSZERO :
                                  (`SD === NAN)           ? `BINARY32_NAN_POS :
                                  (`SD === POS_DENORMAL)  ? `BINARY32_ONE     :
                                  (`SD === NEG_DENORMAL)  ? `BINARY32_ONE     :
                                  s_my_sp_multiplier_3_jedi[31:0];
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
                          s_my_sp_multiplier_4_jedi;
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
assign o_valid              = `S === SINGLE_MODE  ?  s_my_sp_multiplier_4_valid128_jedi     :
                              `S === TWO_SP_MODE  ?  s_my_sp_multiplier_3_valid64a_jedi &
                                                     s_my_sp_multiplier_3_valid64b_jedi     :
                              `S === FOUR_SP_MODE ?  s_my_sp_multiplier_3_valid32a_jedi &
                                                     s_my_sp_multiplier_3_valid32b_jedi &
                                                     s_my_sp_multiplier_3_valid32c_jedi &
                                                     s_my_sp_multiplier_3_valid32d_jedi     :
                              '0;
assign o_sanity_identifier  = MODULE_IDENTIFIER;
assign o_error              = '0/*s_my_float_to_fixed_error |
                              s_my_fixed128_64_32_partitiona_0_error |
                              s_my_fixed128_64_partitionb_error |
                              s_my_fixed_partition_sp_par_b_error |
                              s_my_fixed128_partitiond_error |
                              s_my_fixed128_partitione_error |
                              s_my_fixed128_partitionf_ts_error |
                              s_my_fixed64_partitionf_ts_a_error |
                              s_my_fixed64_partitionf_ts_b_error |
                              // s_my_fixed32_partitiona_a_error |
                              // s_my_fixed32_partitiona_b_error |
                              // s_my_fixed32_partitiona_c_error |
                              // s_my_fixed32_partitiona_d_error |
                              s_my_fixed32_partitionb_a_error |
                              s_my_fixed32_partitionb_b_error |
                              s_my_fixed32_partitionb_c_error |
                              s_my_fixed32_partitionb_d_error |
                              s_my_fixed32_partitionc_a_error |
                              s_my_fixed32_partitionc_b_error |
                              s_my_fixed32_partitionc_c_error |
                              s_my_fixed32_partitionc_d_error |
                              s_my_sp_multiplier_0_error |
                              s_my_sp_multiplier_1_error |
                              s_my_sp_multiplier_2_error |
                              s_my_sp_multiplier_3_error |
                              s_my_sp_multiplier_4_error*/;
assign o_debug              = '0/*s_my_float_to_fixed_debug |
                              s_my_fixed128_64_32_partitiona_0_debug |
                              s_my_fixed_partition_sp_par_b_debug |
                              s_my_fixed128_64_partitionc_debug |
                              s_my_fixed128_partitiond_debug |
                              s_my_fixed128_partitione_debug |
                              s_my_fixed128_partitionf_ts_debug |
                              s_my_fixed64_partitionf_ts_a_debug |
                              s_my_fixed64_partitionf_ts_b_debug |
                              // s_my_fixed32_partitiona_a_debug |
                              // s_my_fixed32_partitiona_b_debug |
                              // s_my_fixed32_partitiona_c_debug |
                              // s_my_fixed32_partitiona_d_debug |
                              s_my_fixed32_partitionb_a_debug |
                              s_my_fixed32_partitionb_b_debug |
                              s_my_fixed32_partitionb_c_debug |
                              s_my_fixed32_partitionb_d_debug |
                              s_my_fixed32_partitionc_a_debug |
                              s_my_fixed32_partitionc_b_debug |
                              s_my_fixed32_partitionc_c_debug |
                              s_my_fixed32_partitionc_d_debug |
                              s_my_sp_multiplier_0_debug |
                              s_my_sp_multiplier_1_debug |
                              s_my_sp_multiplier_2_debug |
                              s_my_sp_multiplier_3_debug |
                              s_my_sp_multiplier_4_debug*/;

// Temp, maybe
assign os_my_float_to_fixed_fixed = s_my_float_to_fixed_fixed;
assign os_my_fixed128_64_partitiona_exp_a128 = s_my_fixed_partition_sp_par_a_exp_a128;
assign os_my_fixed128_64_partitionb_exp_a128 = s_my_fixed_partition_sp_par_b_exp_a128;
assign os_my_fixed128_64_partitionc_exp_a128 = s_my_fixed_partition_sp_par_c_exp_a128;
assign os_my_fixed128_partitiond_exp_d128 = s_my_fixed128_partitiond_exp_d128;
assign os_my_fixed128_partitione_exp_d128 = s_my_fixed128_partitione_exp_d128;
assign os_my_fixed128_partitionf_ts_exp_f128 = s_my_fixed128_partitionf_ts_exp_f128;
assign os_mux_0 = s_mux_0;
assign os_mux_1 = s_mux_1;
assign os_mux_2 = s_mux_2;
assign os_mux_3 = s_mux_3;
assign os_my_sp_multiplier_0_jedi = s_my_sp_multiplier_0_jedi;
assign os_my_sp_multiplier_1_jedi = s_my_sp_multiplier_1_jedi;
assign os_my_sp_multiplier_2_jedi = s_my_sp_multiplier_2_jedi;
assign os_mux_4 = s_mux_4;
assign os_my_sp_multiplier_3_jedi = s_my_sp_multiplier_3_jedi;
assign os_my_sp_multiplier_4_jedi = s_my_sp_multiplier_4_jedi;
assign os_my_float_to_fixed_metadata = s_my_float_to_fixed_metadata;
assign os_my_float_to_fixed_o_valid = s_my_float_to_fixed_o_valid;
assign os_my_fixed128_partitiond_o_valid = s_my_fixed128_partitiond_o_valid;
assign os_my_fixed128_partitione_o_valid = s_my_fixed128_partitione_o_valid;
assign os_my_fixed128_partitionf_ts_o_valid = s_my_fixed128_partitionf_ts_o_valid;
assign os_my_fixed64_partitionf_ts_a_o_valid = s_my_fixed64_partitionf_ts_a_o_valid;
assign os_my_fixed64_partitionf_ts_b_o_valid = s_my_fixed64_partitionf_ts_b_o_valid;
assign os_my_fixed32_partitiona_a_o_valid = s_my_fixed_partition_sp_par_a_exp_a32a; // todo rename lhs
assign os_my_fixed32_partitiona_b_o_valid = s_my_fixed_partition_sp_par_a_exp_a32b; // todo rename lhs
assign os_my_fixed32_partitiona_c_o_valid = s_my_fixed_partition_sp_par_a_exp_a32c; // todo rename lhs
assign os_my_fixed32_partitiona_d_o_valid = s_my_fixed_partition_sp_par_a_exp_a32d; // todo rename lhs
assign os_my_fixed32_partitionb_a_o_valid = s_my_fixed_partition_sp_par_b_o_valid32a; // todo rename lhs
assign os_my_fixed32_partitionb_b_o_valid = s_my_fixed_partition_sp_par_b_o_valid32b; // todo rename lhs
assign os_my_fixed32_partitionb_c_o_valid = s_my_fixed_partition_sp_par_b_o_valid32c; // todo rename lhs
assign os_my_fixed32_partitionb_d_o_valid = s_my_fixed_partition_sp_par_b_o_valid32d; // todo rename lhs
assign os_my_fixed32_partitionc_a_o_valid = s_my_fixed_partition_sp_par_c_o_valid32a; // todo rename lhs
assign os_my_fixed32_partitionc_b_o_valid = s_my_fixed_partition_sp_par_c_o_valid32b; // todo rename lhs
assign os_my_fixed32_partitionc_c_o_valid = s_my_fixed_partition_sp_par_c_o_valid32c; // todo rename lhs
assign os_my_fixed32_partitionc_d_o_valid = s_my_fixed_partition_sp_par_c_o_valid32d; // todo rename lhs

endmodule // module SPEX128_top #()
