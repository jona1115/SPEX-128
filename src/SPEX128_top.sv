/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/?/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a wrapper for all the LUTs and Taylor Series.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/?/2025   |  Birth of this file
 * 
 *******************************************************************/

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;

module SPEX128_top #(
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32
) (
  input   logic                                   i_clk,
  input   logic                                   i_reset, // Synchronous

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
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic [127:0] s_level1_fixed_out;
logic [127:0] s_level1_metadata_out;
// Identifier signals
logic [3:0] s_my_float_to_fixed_identifier;
// Error signals
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_my_float_to_fixed_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_my_float_to_fixed_debug;

/******************************************************************
 * 
 * Level 1
 * 
 *****************************************************************/
float_to_fixed #(
  
) my_float_to_fixed (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .i_float(i_x),
  .i_ctrl(i_ctrl),
  .o_fixed(s_level1_out),
  .o_metadata(s_level1_metadata_out),
  .i_valid(?),
  .o_sanity_identifier(s_my_float_to_fixed_identifier),
  .o_error(?),
  .o_debug(?)
);

/******************************************************************
 * 
 * Level 2
 * 
 *****************************************************************/


 /******************************************************************
 * 
 * Level 3
 * 
 *****************************************************************/


//=====================================================================================
// Final assignment
//=====================================================================================


endmodule // module SPEX128_top #()