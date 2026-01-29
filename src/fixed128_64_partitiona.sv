/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/9/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the a partition of fixed128 and fixed64 
 * look-up-table (LUT).
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

module fixed128_64_partitiona #(
  parameter string INIT_128a_POS_FILE = {"fixed128_0a_partition.", `SPEX_RAM_EXT},
  parameter string INIT_128a_NEG_FILE = {"fixed128_1a_partition.", `SPEX_RAM_EXT},
  parameter string INIT_64a_POS_FILE = {"fixed64_0a_partition.", `SPEX_RAM_EXT},
  parameter string INIT_64a_NEG_FILE = {"fixed64_1a_partition.", `SPEX_RAM_EXT},
  
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
  input   var float_metadata_t                    i_metadata,
  output  var float_metadata_t                    o_metadata,

  // Data
  input   logic [10:0]                            i_a, // bit10 is the sign bit, bit[9:0] are the actual partition a
  input   logic [10:0]                            i_a2, // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  output  binary64_t                              o_exp_a64a,
  output  binary64_t                              o_exp_a64b,
  output  binary128_t                             o_exp_a128,

  // Upstream Handshake
  input   logic                                   i_valid64a, // This is the valid bit for i_a
  input   logic                                   i_valid64b, // This is the valid bit for i_a2
  input   logic                                   i_valid128,
  // output  logic                                   o_ready, todo need?

  // Downstream Handshake
  output  logic                                   o_valid64a,
  output  logic                                   o_valid64b,
  output  logic                                   o_valid128,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic                               s_o_valid64a;
logic                               s_o_valid64b;
logic                               s_o_valid128;
float_metadata_t                    s_o_metadata;
logic [ERROR_SIGNAL_NUM_BITS-1:0]   s_o_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0]   s_o_debug;
logic [127:0]                       s_o_exp_a128_bits;
logic [63:0]                        s_o_exp_a64a_bits;
logic [63:0]                        s_o_exp_a64b_bits;

//=====================================================================================
// Module body
//=====================================================================================

// Default stuff out
always_ff @( posedge i_clk ) begin : defaulter
  if (!i_rst_n) begin
    s_o_debug <= '0;
  end
end

/**
 * The LUT part of it
 */
(* rom_style = "block" *) logic [127:0] mempos128  [0:1023]; // Infer a BRAM
(* rom_style = "block" *) logic [127:0] memneg128  [0:1023]; // Infer a BRAM
(* rom_style = "block" *) logic [63:0]  mempos64   [0:1023]; // Infer a BRAM
(* rom_style = "block" *) logic [63:0]  memneg64   [0:1023]; // Infer a BRAM
initial begin
  `SPEX_READMEM(INIT_128a_POS_FILE, mempos128);
  `SPEX_READMEM(INIT_128a_NEG_FILE, memneg128);
  `SPEX_READMEM(INIT_64a_POS_FILE, mempos64);
  `SPEX_READMEM(INIT_64a_NEG_FILE, memneg64);
end

// Xilinx synchronous ROM template: one read port per output register.
always_ff @( posedge i_clk ) begin : lut128
  if (!i_rst_n) begin
    s_o_exp_a128_bits <= '0;
  end
  else if (i_metadata.sp_mode == SINGLE_MODE && i_valid128 === 1'b1) begin
    if (i_a[10] === 1'b0) begin
      // Positive input a
      s_o_exp_a128_bits <= mempos128[i_a[9:0]];
    end
    else begin
      // Negative input a
      s_o_exp_a128_bits <= memneg128[i_a[9:0]];
    end
  end
end // always_ff

always_ff @( posedge i_clk ) begin : lut64a
  if (!i_rst_n) begin
    s_o_exp_a64a_bits <= '0;
  end
  else if (i_metadata.sp_mode == TWO_SP_MODE && i_valid64a === 1'b1 && i_valid64b === 1'b1) begin
    if (i_a[10] === 1'b0) begin
      // Positive input a(a)
      s_o_exp_a64a_bits <= mempos64[i_a[9:0]];
    end
    else begin
      // Negative input a(a)
      s_o_exp_a64a_bits <= memneg64[i_a[9:0]];
    end
  end
end // always_ff

always_ff @( posedge i_clk ) begin : lut64b
  if (!i_rst_n) begin
    s_o_exp_a64b_bits <= '0;
  end
  else if (i_metadata.sp_mode == TWO_SP_MODE && i_valid64a === 1'b1 && i_valid64b === 1'b1) begin
    if (i_a2[10] === 1'b0) begin
      // Positive input a(b)
      s_o_exp_a64b_bits <= mempos64[i_a2[9:0]];
    end
    else begin
      // Negative input a(b)
      s_o_exp_a64b_bits <= memneg64[i_a2[9:0]];
    end
  end
end // always_ff

always_ff @( posedge i_clk ) begin : error_register
  if (!i_rst_n) begin
    s_o_error <= '0;
  end
  else begin
    case (i_metadata.sp_mode)
      SINGLE_MODE, TWO_SP_MODE, FOUR_SP_MODE: begin
        // No error
      end
      default: begin
        assert (0) else begin
          s_o_error[0] <= 1'b1;
          // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
        end
      end
    endcase
  end
end // always_ff

/**
 * Register for the valid bits, and metadata
 */
always_ff @( posedge i_clk ) begin : valid_bit_register
  if (!i_rst_n) begin
    s_o_valid64a  <= '0;
    s_o_valid64b  <= '0;
    s_o_valid128  <= '0;
    s_o_metadata  <= '0;
  end
  else begin
    if (i_valid64a === 1'b1 && i_valid64b === 1'b1) begin
      // We wait for both valid bits to be set before passing it into the output
      s_o_valid64a  <= i_valid64a;
      s_o_valid64b  <= i_valid64b;
    end
    else begin
      // If either bits are false, we set both outputs to be false
      s_o_valid64a  <= '0;
      s_o_valid64b  <= '0;
    end 
    
    s_o_valid128  <= i_valid128;
    s_o_metadata  <= i_metadata;
  end
end // always_ff

//=====================================================================================
// Final assignment
//=====================================================================================
// assign o_exp_a = s_o_exp_a;
// assign o_valid = s_o_valid; 
// assign o_sanity_identifier = 4'b0000;
// assign o_error = '0;
// assign o_debug = '0;
assign o_metadata = s_o_metadata;
assign o_exp_a64a = binary64_t'(s_o_exp_a64a_bits);
assign o_exp_a64b = binary64_t'(s_o_exp_a64b_bits);
assign o_exp_a128 = binary128_t'(s_o_exp_a128_bits);
assign o_valid64a = s_o_valid64a;
assign o_valid64b = s_o_valid64b;
assign o_valid128 = s_o_valid128;
assign o_sanity_identifier = 4'b0000;
assign o_error = s_o_error;
assign o_debug = s_o_debug;


endmodule // module fixed128_64_partitiona #()
