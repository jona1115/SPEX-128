/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/9/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the a partition of fixed32 look-up-
 * table (LUT).
 * 
 * What is the partitions? See the graph in:
 * https://github.com/jona1115/SPEX-128/issues/14
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  11/9/2025   |  Birth of this file
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

module fixed32_partitiona #(
  parameter string INIT_POS_FILE = "fixed32_0a_partition.hex",
  parameter string INIT_NEG_FILE = "fixed32_1a_partition.hex",
  
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
  input   logic [10:0]                            i_a, // bit10 is the sign bit, bit[9:0] are the actual partition a
  output  binary32_t                              o_exp_a,

  // Upstream Handshake
  input   logic                                   i_valid,
  // output  logic                                   o_ready, todo need?

  // Downstream Handshake
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
logic s_o_valid;
binary32_t s_o_exp_a;

//=====================================================================================
// Module body
//=====================================================================================

/**
 * The LUT part of it
 */
(* rom_style = "block" *) logic [31:0] mempos [0:1023]; // Infer a BRAM
(* rom_style = "block" *) logic [31:0] memneg [0:1023]; // Infer a BRAM
initial $readmemh(INIT_POS_FILE, mempos);
initial $readmemh(INIT_NEG_FILE, memneg);
always_ff @( posedge i_clk ) begin : LUTs
  if (!i_rst_n) begin
    s_o_exp_a <= '0;
  end
  else begin
    if (i_valid) begin // The hope is that this will infer a en signal into the BRAM
      if (i_a[10] === 1'b0) begin
        // Positive input a
        s_o_exp_a <= binary32_t'(mempos[i_a[9:0]]);
      end
      else begin
        // Negative input a
        s_o_exp_a <= binary32_t'(memneg[i_a[9:0]]);
      end
    end // if (i_valid) begin
  end // else begin
end // always_ff

/**
 * Register for the valid bit
 */
always_ff @( posedge i_clk ) begin : valid_bit_register
  if (!i_rst_n) begin
    s_o_valid <= '0;
  end
  else begin
    s_o_valid <= i_valid;
  end
end // always_ff

//=====================================================================================
// Final assignment
//=====================================================================================
assign o_exp_a = s_o_exp_a;
assign o_valid = s_o_valid; 
assign o_sanity_identifier = 4'b0000;
assign o_error = '0;
assign o_debug = '0;


endmodule // module fixed32_partitiona #()
