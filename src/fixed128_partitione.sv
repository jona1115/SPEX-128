/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/8/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the e partition of fixed128 look-up-
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
 *       1.00  |  Jonathan  |  11/8/2025   |  Birth of this file
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

// Turn this define ON (uncomment) when synthesizing using Vivado, as it only recognize .data binary files
// Turn thie design OFF (comment) when simulating using non-Vivado, as the testing infrastructure is set up
// to read .hex files.
// `define USE_RAM_DATA

`ifdef USE_RAM_DATA
  `define SPEX_RAM_EXT "data"
  `define SPEX_READMEM $readmemb
`else
  `define SPEX_RAM_EXT "hex"
  `define SPEX_READMEM $readmemh
`endif

module fixed128_partitione #(
  parameter string INIT_FILE = {"fixed128_e_partition.", `SPEX_RAM_EXT},
  
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
  input   logic [12:0]                            i_e,
  output  binary128_t                             o_exp_e,

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
logic [127:0] s_o_exp_e_bits;

//=====================================================================================
// Module body
//=====================================================================================

/**
 * The LUT part of it
 */
(* rom_style = "block" *) logic [127:0] mem [0:8191]; // Infer a BRAM
initial begin
  `SPEX_READMEM(INIT_FILE, mem);
end
always_ff @( posedge i_clk ) begin : LUT
  if (!i_rst_n) begin
    s_o_exp_e_bits <= '0;
  end
  else begin
    if (i_valid) begin // The hope is that this will infer a en signal into the BRAM
      s_o_exp_e_bits <= mem[i_e];
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
assign o_exp_e = binary128_t'(s_o_exp_e_bits);
assign o_valid = s_o_valid; 
assign o_sanity_identifier = 4'b0000;
assign o_error = '0;
assign o_debug = '0;


endmodule // module fixed128_partitione #()
