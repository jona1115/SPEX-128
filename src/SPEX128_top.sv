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
  output  logic                                   o_ready,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug,

  // These are temporary, probably
  output logic [127:0] os_my_float_to_fixed_fixed_out,
  output logic [127:0] os_mux_0,
  output logic [127:0] os_mux_1,
  output logic [127:0] os_mux_2,
  output logic [127:0] os_mux_3,
  output logic [127:0] os_my_sp_multiplier_0_jedi,
  output logic [127:0] os_my_sp_multiplier_1_jedi,
  output logic [127:0] os_my_sp_multiplier_2_jedi,
  output logic [127:0] os_mux_4,
  output logic [127:0] os_my_sp_multiplier_3_jedi,
  output logic [127:0] os_my_sp_multiplier_4_jedi
);


//=====================================================================================
// Module body
//=====================================================================================
/******************************************************************
 * 
 * Level 1
 * 
 *****************************************************************/
logic [127:0]     s_my_float_to_fixed_fixed_out;
float_metadata_t  s_my_float_to_fixed_metadata_out;
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
  .o_fixed(s_my_float_to_fixed_fixed_out),
  .o_metadata(s_my_float_to_fixed_metadata_out),
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
float_metadata_t  s_my_fixed128_64_partitiona_metadata;
binary64_t        s_my_fixed128_64_partitiona_exp_a64a;
binary64_t        s_my_fixed128_64_partitiona_exp_a64b;
binary128_t       s_my_fixed128_64_partitiona_exp_a128;
logic             s_my_fixed128_64_partitiona_o_valid64a;
logic             s_my_fixed128_64_partitiona_o_valid64b;
logic             s_my_fixed128_64_partitiona_o_valid128;
// Metadata
logic [3:0] s_my_fixed128_64_partitiona_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitiona_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitiona_debug;
fixed128_64_partitiona #() my_fixed128_64_partitiona (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_my_fixed128_64_partitiona_metadata),
  .i_a(s_my_float_to_fixed_fixed_out[127:117]),
  .i_a2(s_my_float_to_fixed_fixed_out[63:53]),
  .o_exp_a64a(s_my_fixed128_64_partitiona_exp_a64a),
  .o_exp_a64b(s_my_fixed128_64_partitiona_exp_a64b),
  .o_exp_a128(s_my_fixed128_64_partitiona_exp_a128),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .o_valid64a(s_my_fixed128_64_partitiona_o_valid64a),
  .o_valid64b(s_my_fixed128_64_partitiona_o_valid64b),
  .o_valid128(s_my_fixed128_64_partitiona_o_valid128),
  .o_sanity_identifier(s_my_fixed128_64_partitiona_identifier),
  .o_error(s_my_fixed128_64_partitiona_error),
  .o_debug(s_my_fixed128_64_partitiona_debug)
);

float_metadata_t  s_my_fixed128_64_partitionb_metadata;
binary64_t        s_my_fixed128_64_partitionb_exp_a64a;
binary64_t        s_my_fixed128_64_partitionb_exp_a64b;
binary128_t       s_my_fixed128_64_partitionb_exp_a128;
logic             s_my_fixed128_64_partitionb_o_valid64a;
logic             s_my_fixed128_64_partitionb_o_valid64b;
logic             s_my_fixed128_64_partitionb_o_valid128;
// Metadata
logic [3:0] s_my_fixed128_64_partitionb_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitionb_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitionb_debug;
fixed128_64_partitionb #() my_fixed128_64_partitionb (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_my_fixed128_64_partitionb_metadata),
  .i_a(s_my_float_to_fixed_fixed_out[116:104]),
  .i_a2(s_my_float_to_fixed_fixed_out[52:40]),
  .o_exp_a64a(s_my_fixed128_64_partitionb_exp_a64a),
  .o_exp_a64b(s_my_fixed128_64_partitionb_exp_a64b),
  .o_exp_a128(s_my_fixed128_64_partitionb_exp_a128),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .o_valid64a(s_my_fixed128_64_partitionb_o_valid64a),
  .o_valid64b(s_my_fixed128_64_partitionb_o_valid64b),
  .o_valid128(s_my_fixed128_64_partitionb_o_valid128),
  .o_sanity_identifier(s_my_fixed128_64_partitionb_identifier),
  .o_error(s_my_fixed128_64_partitionb_error),
  .o_debug(s_my_fixed128_64_partitionb_debug)
);

float_metadata_t  s_my_fixed128_64_partitionc_metadata;
binary64_t        s_my_fixed128_64_partitionc_exp_a64a;
binary64_t        s_my_fixed128_64_partitionc_exp_a64b;
binary128_t       s_my_fixed128_64_partitionc_exp_a128;
logic             s_my_fixed128_64_partitionc_o_valid64a;
logic             s_my_fixed128_64_partitionc_o_valid64b;
logic             s_my_fixed128_64_partitionc_o_valid128;
// Metadata
logic [3:0] s_my_fixed128_64_partitionc_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitionc_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed128_64_partitionc_debug;
fixed128_64_partitionc #() my_fixed128_64_partitionc (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_my_fixed128_64_partitionc_metadata),
  .i_a(s_my_float_to_fixed_fixed_out[103:91]),
  .i_a2(s_my_float_to_fixed_fixed_out[39:27]),
  .o_exp_a64a(s_my_fixed128_64_partitionc_exp_a64a),
  .o_exp_a64b(s_my_fixed128_64_partitionc_exp_a64b),
  .o_exp_a128(s_my_fixed128_64_partitionc_exp_a128),
  .i_valid64a(s_my_float_to_fixed_o_valid),
  .i_valid64b(s_my_float_to_fixed_o_valid),
  .i_valid128(s_my_float_to_fixed_o_valid),
  .o_valid64a(s_my_fixed128_64_partitionc_o_valid64a),
  .o_valid64b(s_my_fixed128_64_partitionc_o_valid64b),
  .o_valid128(s_my_fixed128_64_partitionc_o_valid128),
  .o_sanity_identifier(s_my_fixed128_64_partitionc_identifier),
  .o_error(s_my_fixed128_64_partitionc_error),
  .o_debug(s_my_fixed128_64_partitionc_debug)
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
  .i_d(s_my_float_to_fixed_fixed_out[90:78]),
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
  .i_e(s_my_float_to_fixed_fixed_out[77:65]),
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
  .i_f(s_my_float_to_fixed_fixed_out[64:0]),
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
  .i_f(s_my_float_to_fixed_fixed_out[90:64]),
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
  .i_f(s_my_float_to_fixed_fixed_out[26:0]),
  .o_exp_f(s_my_fixed64_partitionf_ts_b_exp_f64b),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed64_partitionf_ts_b_o_valid),
  .o_sanity_identifier(s_my_fixed64_partitionf_ts_b_identifier),
  .o_error(s_my_fixed64_partitionf_ts_b_error),
  .o_debug(s_my_fixed64_partitionf_ts_b_debug)
);

/**
 * binary32_t
 */
// Partition a lane a, b, c, and d
binary32_t  s_my_fixed32_partitiona_a_exp_a32a;
logic       s_my_fixed32_partitiona_a_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitiona_a_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_a_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_a_debug;
fixed32_partitiona #() my_fixed32_partitiona_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_a(s_my_float_to_fixed_fixed_out[127:117]),
  .o_exp_a(s_my_fixed32_partitiona_a_exp_a32a),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitiona_a_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitiona_a_identifier),
  .o_error(s_my_fixed32_partitiona_a_error),
  .o_debug(s_my_fixed32_partitiona_a_debug)
);

binary32_t  s_my_fixed32_partitiona_b_exp_a32b;
logic       s_my_fixed32_partitiona_b_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitiona_b_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_b_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_b_debug;
fixed32_partitiona #() my_fixed32_partitiona_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_a(s_my_float_to_fixed_fixed_out[95:85]),
  .o_exp_a(s_my_fixed32_partitiona_b_exp_a32b),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitiona_b_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitiona_b_identifier),
  .o_error(s_my_fixed32_partitiona_b_error),
  .o_debug(s_my_fixed32_partitiona_b_debug)
);

binary32_t  s_my_fixed32_partitiona_c_exp_a32c;
logic       s_my_fixed32_partitiona_c_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitiona_c_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_c_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_c_debug;
fixed32_partitiona #() my_fixed32_partitiona_c (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_a(s_my_float_to_fixed_fixed_out[63:53]),
  .o_exp_a(s_my_fixed32_partitiona_c_exp_a32c),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitiona_c_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitiona_c_identifier),
  .o_error(s_my_fixed32_partitiona_c_error),
  .o_debug(s_my_fixed32_partitiona_c_debug)
);

binary32_t  s_my_fixed32_partitiona_d_exp_a32d;
logic       s_my_fixed32_partitiona_d_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitiona_d_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_d_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitiona_d_debug;
fixed32_partitiona #() my_fixed32_partitiona_d (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_a(s_my_float_to_fixed_fixed_out[31:21]),
  .o_exp_a(s_my_fixed32_partitiona_d_exp_a32d),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitiona_d_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitiona_d_identifier),
  .o_error(s_my_fixed32_partitiona_d_error),
  .o_debug(s_my_fixed32_partitiona_d_debug)
);

// Partition b lane a, b, c, and d
binary32_t  s_my_fixed32_partitionb_a_exp_d32a;
logic       s_my_fixed32_partitionb_a_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionb_a_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_a_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_a_debug;
fixed32_partitionb #() my_fixed32_partitionb_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_b(s_my_float_to_fixed_fixed_out[116:107]),
  .o_exp_b(s_my_fixed32_partitionb_a_exp_d32a),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionb_a_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionb_a_identifier),
  .o_error(s_my_fixed32_partitionb_a_error),
  .o_debug(s_my_fixed32_partitionb_a_debug)
);

binary32_t  s_my_fixed32_partitionb_b_exp_d32b;
logic       s_my_fixed32_partitionb_b_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionb_b_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_b_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_b_debug;
fixed32_partitionb #() my_fixed32_partitionb_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_b(s_my_float_to_fixed_fixed_out[84:75]),
  .o_exp_b(s_my_fixed32_partitionb_b_exp_d32b),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionb_b_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionb_b_identifier),
  .o_error(s_my_fixed32_partitionb_b_error),
  .o_debug(s_my_fixed32_partitionb_b_debug)
);

binary32_t  s_my_fixed32_partitionb_c_exp_d32c;
logic       s_my_fixed32_partitionb_c_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionb_c_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_c_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_c_debug;
fixed32_partitionb #() my_fixed32_partitionb_c (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_b(s_my_float_to_fixed_fixed_out[52:43]),
  .o_exp_b(s_my_fixed32_partitionb_c_exp_d32c),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionb_c_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionb_c_identifier),
  .o_error(s_my_fixed32_partitionb_c_error),
  .o_debug(s_my_fixed32_partitionb_c_debug)
);

binary32_t  s_my_fixed32_partitionb_d_exp_d32d;
logic       s_my_fixed32_partitionb_d_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionb_d_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_d_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionb_d_debug;
fixed32_partitionb #() my_fixed32_partitionb_d (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_b(s_my_float_to_fixed_fixed_out[20:11]),
  .o_exp_b(s_my_fixed32_partitionb_d_exp_d32d),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionb_d_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionb_d_identifier),
  .o_error(s_my_fixed32_partitionb_d_error),
  .o_debug(s_my_fixed32_partitionb_d_debug)
);

// Partition c lane a, b, c, and d
binary32_t  s_my_fixed32_partitionc_a_exp_c32a;
logic       s_my_fixed32_partitionc_a_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionc_a_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_a_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_a_debug;
fixed32_partitionc #() my_fixed32_partitionc_a (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_c(s_my_float_to_fixed_fixed_out[106:96]),
  .o_exp_c(s_my_fixed32_partitionc_a_exp_c32a),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionc_a_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionc_a_identifier),
  .o_error(s_my_fixed32_partitionc_a_error),
  .o_debug(s_my_fixed32_partitionc_a_debug)
);

binary32_t  s_my_fixed32_partitionc_b_exp_c32b;
logic       s_my_fixed32_partitionc_b_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionc_b_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_b_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_b_debug;
fixed32_partitionc #() my_fixed32_partitionc_b (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_c(s_my_float_to_fixed_fixed_out[74:64]),
  .o_exp_c(s_my_fixed32_partitionc_b_exp_c32b),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionc_b_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionc_b_identifier),
  .o_error(s_my_fixed32_partitionc_b_error),
  .o_debug(s_my_fixed32_partitionc_b_debug)
);

binary32_t  s_my_fixed32_partitionc_c_exp_c32c;
logic       s_my_fixed32_partitionc_c_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionc_c_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_c_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_c_debug;
fixed32_partitionc #() my_fixed32_partitionc_c (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_c(s_my_float_to_fixed_fixed_out[42:32]),
  .o_exp_c(s_my_fixed32_partitionc_c_exp_c32c),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionc_c_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionc_c_identifier),
  .o_error(s_my_fixed32_partitionc_c_error),
  .o_debug(s_my_fixed32_partitionc_c_debug)
);

binary32_t  s_my_fixed32_partitionc_d_exp_c32d;
logic       s_my_fixed32_partitionc_d_o_valid;
// Metadata
logic [3:0] s_my_fixed32_partitionc_d_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_d_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_fixed32_partitionc_d_debug;
fixed32_partitionc #() my_fixed32_partitionc_d (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_c(s_my_float_to_fixed_fixed_out[10:0]),
  .o_exp_c(s_my_fixed32_partitionc_d_exp_c32d),
  .i_valid(s_my_float_to_fixed_o_valid),
  .o_valid(s_my_fixed32_partitionc_d_o_valid),
  .o_sanity_identifier(s_my_fixed32_partitionc_d_identifier),
  .o_error(s_my_fixed32_partitionc_d_error),
  .o_debug(s_my_fixed32_partitionc_d_debug)
);

/******************************************************************
 * 
 * Level 3
 * 
 *****************************************************************/
logic [127:0] s_mux_0;
logic         s_mux_0_valid;
always_comb begin : mux_0
  case (s_my_float_to_fixed_metadata_out.sp_mode)
    SINGLE_MODE: begin
      s_mux_0       = s_my_fixed128_64_partitiona_exp_a128;
      s_mux_0_valid = s_my_fixed128_64_partitiona_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_0       = {s_my_fixed128_64_partitiona_exp_a64a, 
                       s_my_fixed128_64_partitiona_exp_a64b};
      s_mux_0_valid = s_my_fixed128_64_partitiona_o_valid64a &
                      s_my_fixed128_64_partitiona_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_0       = {s_my_fixed32_partitiona_a_exp_a32a,
                       s_my_fixed32_partitiona_b_exp_a32b,
                       s_my_fixed32_partitiona_c_exp_a32c,
                       s_my_fixed32_partitiona_d_exp_a32d};
      s_mux_0_valid = s_my_fixed32_partitiona_a_o_valid &
                      s_my_fixed32_partitiona_b_o_valid &
                      s_my_fixed32_partitiona_c_o_valid & 
                      s_my_fixed32_partitiona_d_o_valid;
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
  case (s_my_float_to_fixed_metadata_out.sp_mode)
    SINGLE_MODE: begin
      s_mux_1       = s_my_fixed128_64_partitionb_exp_a128;
      s_mux_1_valid = s_my_fixed128_64_partitionb_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_1       = {s_my_fixed128_64_partitionb_exp_a64a, 
                       s_my_fixed128_64_partitionb_exp_a64b};
      s_mux_1_valid = s_my_fixed128_64_partitionb_o_valid64a &
                      s_my_fixed128_64_partitionb_o_valid64b;
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      s_mux_1       = {s_my_fixed32_partitionb_a_exp_d32a,
                       s_my_fixed32_partitionb_b_exp_d32b,
                       s_my_fixed32_partitionb_c_exp_d32c,
                       s_my_fixed32_partitionb_d_exp_d32d};
      s_mux_1_valid = s_my_fixed32_partitionb_a_o_valid &
                      s_my_fixed32_partitionb_b_o_valid &
                      s_my_fixed32_partitionb_c_o_valid &
                      s_my_fixed32_partitionb_d_o_valid;
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
  case (s_my_float_to_fixed_metadata_out.sp_mode)
    SINGLE_MODE: begin
      s_mux_2       = s_my_fixed128_64_partitionc_exp_a128;
      s_mux_2_valid = s_my_fixed128_64_partitionc_o_valid128;
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      s_mux_2       = {s_my_fixed128_64_partitionc_exp_a64a, 
                       s_my_fixed128_64_partitionc_exp_a64b};
      s_mux_2_valid = s_my_fixed128_64_partitionc_o_valid64a &
                      s_my_fixed128_64_partitionc_o_valid64b;
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
  case (s_my_float_to_fixed_metadata_out.sp_mode)
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

float_metadata_t s_gnd_metadata_0;
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
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_gnd_metadata_0/*not like it is useful anyway*/),
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

float_metadata_t s_gnd_metadata_1;
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
sp_multiplier #() my_sp_multiplier_1 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_gnd_metadata_1/*not like it is useful anyway*/),
  .i_in_anikin(s_mux_2),
  .i_in_force(s_mux_3),
  .o_out_jedi(s_my_sp_multiplier_1_jedi),
  .i_valid128_anikin(s_mux_2_valid),
  .i_valid128_force(s_mux_3_valid),
  .i_valid64a_anikin(s_mux_2_valid),
  .i_valid64a_force(s_mux_3_valid),
  .i_valid64b_anikin(s_mux_2_valid),
  .i_valid64b_force(s_mux_3_valid),
  .i_valid32a_anikin(s_mux_2_valid),
  .i_valid32a_force(s_mux_3_valid),
  .i_valid32b_anikin(s_mux_2_valid),
  .i_valid32b_force(s_mux_3_valid),
  .i_valid32c_anikin(s_mux_2_valid),
  .i_valid32c_force(s_mux_3_valid),
  .i_valid32d_anikin(s_mux_2_valid),
  .i_valid32d_force(s_mux_3_valid),
  .o_valid128_jedi(s_my_sp_multiplier_1_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_multiplier_1_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_1_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_multiplier_1_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_multiplier_1_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_multiplier_1_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_multiplier_1_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_multiplier_1_identifier),
  .o_error(s_my_sp_multiplier_1_error),
  .o_debug(s_my_sp_multiplier_1_debug)
);

float_metadata_t s_gnd_metadata_2;
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
sp_multiplier #() my_sp_multiplier_2 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_gnd_metadata_2/*not like it is useful anyway*/),
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
  .o_valid64a_jedi(s_my_sp_multiplier_2_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_2_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_multiplier_2_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_multiplier_2_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_multiplier_2_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_multiplier_2_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_multiplier_2_identifier),
  .o_error(s_my_sp_multiplier_2_error),
  .o_debug(s_my_sp_multiplier_2_debug)
);

logic [127:0] s_mux_4;
logic         s_mux_4_valid;
always_comb begin : mux_4
  case (s_my_float_to_fixed_metadata_out.sp_mode)
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
      s_mux_4       = {s_my_fixed32_partitionc_a_exp_c32a,
                       s_my_fixed32_partitionc_b_exp_c32b,
                       s_my_fixed32_partitionc_c_exp_c32c,
                       s_my_fixed32_partitionc_d_exp_c32d};
      s_mux_4_valid = s_my_fixed32_partitionc_a_o_valid &
                      s_my_fixed32_partitionc_b_o_valid &
                      s_my_fixed32_partitionc_c_o_valid &
                      s_my_fixed32_partitionc_d_o_valid;

    end

    default: begin
      s_mux_4       = '0;
      s_mux_4_valid = '0;
    end
  endcase
end

float_metadata_t s_gnd_metadata_3;
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
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_gnd_metadata_3/*not like it is useful anyway*/),
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

float_metadata_t s_gnd_metadata_4;
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
sp_multiplier #() my_sp_multiplier_4 (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_my_float_to_fixed_metadata_out),
  .o_metadata(s_gnd_metadata_4/*not like it is useful anyway*/),
  .i_in_anikin(s_my_sp_multiplier_3_jedi),
  .i_in_force(s_my_sp_multiplier_2_jedi),
  .o_out_jedi(s_my_sp_multiplier_4_jedi),
  .i_valid128_anikin(s_my_sp_multiplier_3_valid128_jedi),
  .i_valid128_force(s_my_sp_multiplier_2_valid128_jedi),
  .i_valid64a_anikin(s_my_sp_multiplier_3_valid64a_jedi),
  .i_valid64a_force(s_my_sp_multiplier_2_valid64a_jedi),
  .i_valid64b_anikin(s_my_sp_multiplier_3_valid64b_jedi),
  .i_valid64b_force(s_my_sp_multiplier_2_valid64b_jedi),
  .i_valid32a_anikin(s_my_sp_multiplier_3_valid32a_jedi),
  .i_valid32a_force(s_my_sp_multiplier_2_valid32a_jedi),
  .i_valid32b_anikin(s_my_sp_multiplier_3_valid32b_jedi),
  .i_valid32b_force(s_my_sp_multiplier_2_valid32b_jedi),
  .i_valid32c_anikin(s_my_sp_multiplier_3_valid32c_jedi),
  .i_valid32c_force(s_my_sp_multiplier_2_valid32c_jedi),
  .i_valid32d_anikin(s_my_sp_multiplier_3_valid32d_jedi),
  .i_valid32d_force(s_my_sp_multiplier_2_valid32d_jedi),
  .o_valid128_jedi(s_my_sp_multiplier_4_valid128_jedi),
  .o_valid64a_jedi(s_my_sp_multiplier_4_valid64a_jedi),
  .o_valid64b_jedi(s_my_sp_multiplier_4_valid64b_jedi),
  .o_valid32a_jedi(s_my_sp_multiplier_4_valid32a_jedi),
  .o_valid32b_jedi(s_my_sp_multiplier_4_valid32b_jedi),
  .o_valid32c_jedi(s_my_sp_multiplier_4_valid32c_jedi),
  .o_valid32d_jedi(s_my_sp_multiplier_4_valid32d_jedi),
  .o_sanity_identifier(s_my_sp_multiplier_4_identifier),
  .o_error(s_my_sp_multiplier_4_error),
  .o_debug(s_my_sp_multiplier_4_debug)
);

//=====================================================================================
// Final assignment
//=====================================================================================
`define S (s_my_float_to_fixed_metadata_out.sp_mode)
assign o_exp_x              = `S === SINGLE_MODE  ?  s_my_sp_multiplier_4_jedi :
                              `S === TWO_SP_MODE  ?  s_my_sp_multiplier_3_jedi :
                              `S === FOUR_SP_MODE ?  s_my_sp_multiplier_3_jedi :
                              '0;
assign o_ready              = '1; //todo
assign o_sanity_identifier  = MODULE_IDENTIFIER;
assign o_error              = '0; //todo
assign o_debug              = '0; //todo

// Temp, maybe
assign os_my_float_to_fixed_fixed_out = s_my_float_to_fixed_fixed_out;
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

endmodule // module SPEX128_top #()