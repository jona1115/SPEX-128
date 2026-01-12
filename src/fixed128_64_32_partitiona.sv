/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 1/8/2026
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the a partition of fixed128, fixed64,
 * and fixed32 look-up-table (LUT).
 * 
 * What is the partitions? See the graph in:
 * https://github.com/jona1115/SPEX-128/issues/14
 * 
 * In milestone 1, we process the LUT for fixed128, fixed64, and 
 * fixed32 separately in my_fixed128_64_partitiona and 
 * my_fixed32_partitiona_a,b,c,d. The idea for this module now is to
 * combine them all into one module for all partitiona's computation.
 * 
 * The implementation is to optimize for the dual port property of 
 * BRAMs on FPGAs and SRAMs on ASICs.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  1/8/2026    |  Birth of this file
 * 
 *******************************************************************/

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import binary128_convert_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;

module fixed128_64_32_partitiona #(
  parameter string INIT_128a_POS_FILE = "fixed128_0a_partition.hex",
  parameter string INIT_128a_NEG_FILE = "fixed128_1a_partition.hex",
  
  parameter int NUM_BITS_128          = 128,
  parameter int NUM_BITS_64           = 64,
  parameter int NUM_BITS_32           = 32,

  parameter int PAR_A_BITS_ALL        = 11,
  parameter int PAR_B_BITS_128_64     = 13,
  parameter int PAR_B_BITS_32         = 10,
  parameter int PAR_C_BITS_128_64     = 13,
  parameter int PAR_C_BITS_32         = 11,
  parameter int PAR_D_BITS_128        = 13,
  parameter int PAR_E_BITS_128        = 13,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32,

  // Identifier const
  parameter logic [3:0] MODULE_IDENTIFIER = 4'b0000
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  // Metadata stuff
  input   var float_metadata_t                    i_metadata,
  output  var float_metadata_t                    o_metadata,

  // Data
  input   logic [PAR_A_BITS_ALL-1:0]              i_lane_a,   // bit10 is the sign bit, bit[9:0] are the actual partition a
  input   logic [PAR_A_BITS_ALL-1:0]              i_lane_b,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  input   logic [PAR_A_BITS_ALL-1:0]              i_lane_c,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  input   logic [PAR_A_BITS_ALL-1:0]              i_lane_d,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  output  binary128_t                             o_exp_a128,
  output  binary64_t                              o_exp_a64a,
  output  binary64_t                              o_exp_a64b,
  output  binary32_t                              o_exp_a32a,
  output  binary32_t                              o_exp_a32b,
  output  binary32_t                              o_exp_a32c,
  output  binary32_t                              o_exp_a32d,

  // Upstream Handshake
  input   logic                                   i_valid128,
  input   logic                                   i_valid64a,
  input   logic                                   i_valid64b,
  input   logic                                   i_valid32a,
  input   logic                                   i_valid32b,
  input   logic                                   i_valid32c,
  input   logic                                   i_valid32d,

  // Downstream Handshake
  output  logic                                   o_valid128,
  output  logic                                   o_valid64a,
  output  logic                                   o_valid64b,
  output  logic                                   o_valid32a,
  output  logic                                   o_valid32b,
  output  logic                                   o_valid32c,
  output  logic                                   o_valid32d,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

localparam int ADDR_BITS_A = PAR_A_BITS_ALL - 1;

fixed_partition_sp #(
  .HAS_SIGN(1'b1),
  .USE_128_FOR_64(1'b1),
  .USE_128_FOR_32(1'b1),
  .ENABLE_64(1'b1),
  .ENABLE_32(1'b1),
  .ADDR_BITS_128(ADDR_BITS_A),
  .ADDR_BITS_64(ADDR_BITS_A),
  .ADDR_BITS_32(ADDR_BITS_A),
  .INIT_128_POS_FILE(INIT_128a_POS_FILE),
  .INIT_128_NEG_FILE(INIT_128a_NEG_FILE),
  .ERROR_SIGNAL_NUM_BITS(ERROR_SIGNAL_NUM_BITS),
  .DEBUG_SIGNAL_NUM_BITS(DEBUG_SIGNAL_NUM_BITS),
  .MODULE_IDENTIFIER(MODULE_IDENTIFIER)
) u_fixed_partition_sp (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(i_metadata),
  .o_metadata(o_metadata),
  .i_lane_128(i_lane_a),
  .i_lane_64a(i_lane_a),
  .i_lane_64b(i_lane_b),
  .i_lane_32a(i_lane_a),
  .i_lane_32b(i_lane_b),
  .i_lane_32c(i_lane_c),
  .i_lane_32d(i_lane_d),
  .o_exp_a128(o_exp_a128),
  .o_exp_a64a(o_exp_a64a),
  .o_exp_a64b(o_exp_a64b),
  .o_exp_a32a(o_exp_a32a),
  .o_exp_a32b(o_exp_a32b),
  .o_exp_a32c(o_exp_a32c),
  .o_exp_a32d(o_exp_a32d),
  .i_valid128(i_valid128),
  .i_valid64a(i_valid64a),
  .i_valid64b(i_valid64b),
  .i_valid32a(i_valid32a),
  .i_valid32b(i_valid32b),
  .i_valid32c(i_valid32c),
  .i_valid32d(i_valid32d),
  .o_valid128(o_valid128),
  .o_valid64a(o_valid64a),
  .o_valid64b(o_valid64b),
  .o_valid32a(o_valid32a),
  .o_valid32b(o_valid32b),
  .o_valid32c(o_valid32c),
  .o_valid32d(o_valid32d),
  .o_sanity_identifier(o_sanity_identifier),
  .o_error(o_error),
  .o_debug(o_debug)
);

endmodule // module fixed128_64_32_partitiona #()
