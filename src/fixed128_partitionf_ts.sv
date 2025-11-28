/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/6/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the f partition of fixed128 taylor
 * approximation. The high level idea is
 *                      output = 1 + f
 * But in reality, it is just a remapping operation of mapping 
 * o_fixed[26:0] and o_fixed[90:64] into the mantissa of a binary64
 * and forcing the sign of the binary64 to 0 and the exponent of
 * it to 1023.
 * 
 * What is the partitions? See the graph in:
 * https://github.com/jona1115/SPEX-128/issues/14
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  11/6/2025   |  Birth of this file
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

module fixed128_partitionf_ts #(
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  // Metadata stuff
  // input   float_metadata_t                        i_metadata,
  // output  float_metadata_t                        o_metadata,

  // Data
  input   logic [64:0]                            i_f,
  output  binary128_t                             o_exp_f,

  // Handshake
  input   logic                                   i_valid,
  output  logic                                   o_valid,

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
// Module Body
//=====================================================================================
binary128_t s_o_exp_f;
logic s_o_valid;
always_ff @( posedge i_clk ) begin : blockhaha
  if (!i_rst_n) begin
    s_o_exp_f <= '0;
    s_o_valid <= '0;
  end
  else begin
    if (i_valid) begin
      s_o_exp_f <= binary128_t'({1'b0, 15'h3FFF/*16383*/, 52'b0, i_f[64:5]});
      s_o_valid <= i_valid;
    end // if (i_valid) begin
  end // else begin
end // always_ff


//=====================================================================================
// Final assignment
//=====================================================================================
// assign o_metadata = i_metadata;
assign o_exp_f = s_o_exp_f;
assign o_valid = s_o_valid;
assign o_sanity_identifier = 4'b0000;
assign o_error = '0;
assign o_debug = '0;

endmodule // module fixed128_partitionf_ts #()