/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/7/2025
 * 
 ********************************************************************
 * 
 * Description:
 * See fixed128_partitionf_ts.sv. This module is the same but
 * different bit index.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  11/7/2025   |  Birth of this file
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

module fixed64_partitionf_ts #(
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32
) (
  // input   logic                                   i_clk,
  // input   logic                                   i_reset, // Synchronous

  // Metadata stuff
  // input   float_metadata_t                        i_metadata,
  // output  float_metadata_t                        o_metadata,

  // Data
  input   logic [26:0]                            i_f,
  output  binary64_t                              o_exp_f,

  // Handshake
  // input   logic                                   i_valid,
  // output  logic                                   o_ready, todo need?

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================

//=====================================================================================
// Final assignment
//=====================================================================================
// assign o_metadata = i_metadata;
assign o_exp_f = binary64_t'({1'b0, 15'h3FF/*1023*/, 26'b0, i_f[26:1]});
assign o_sanity_identifier = 4'b0000;
assign o_error = '0;
assign o_debug = '0;

endmodule // module fixed64_partitionf_ts #()