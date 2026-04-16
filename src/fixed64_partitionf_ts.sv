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

module fixed64_partitionf_ts #(
  parameter int MODULE_LATENCY        = 9, // This should match MODULE_LATENCY_64 in fixed_partition_sp.sv
  parameter int DELAY_BUFFER_LATENCY  = MODULE_LATENCY - 1,
  
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
  // output  float_metadata_t                        o_metadata,

  // Data
  input   logic [19:0]                            i_m,
  output  binary64_t                              o_exp_m,

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
binary64_t s_o_exp_m;
always_ff @( posedge i_clk ) begin : blockhaha
  if (!i_rst_n) begin
    s_o_exp_m <= '0;
  end
  else begin
    if (i_valid) begin
      s_o_exp_m <= binary64_t'({1'b0, 11'h3FF/*1023*/, 33'b0, i_m[19:1]});
    end // if (i_valid) begin
  end // else begin
end // always_ff

/**
 * Register for the valid bit
 */
logic s_o_valid;
always_ff @( posedge i_clk ) begin : valid_cit_register
  if (!i_rst_n) begin
    s_o_valid <= '0;
  end
  else begin
    if (i_metadata.sp_mode == TWO_SP_MODE) begin
      s_o_valid <= i_valid;
    end
    else begin
      s_o_valid <= '0;
    end
  end
end // always_ff

/**
 * db = delay buffer
 * We are delaying things to match the latency from fixed_partition_sp.sv
 */
binary64_t  s_db_o_exp_m;
logic       s_db_o_valid;

generate
  if (DELAY_BUFFER_LATENCY == 0) begin : db_bypass
    always_comb begin
      s_db_o_exp_m = s_o_exp_m;
      s_db_o_valid = s_o_valid;
    end
  end
  else begin : db_shift
    binary64_t  s_db_o_exp_m_pipe [DELAY_BUFFER_LATENCY-1 : 0];
    logic       s_db_o_valid_pipe [DELAY_BUFFER_LATENCY-1 : 0];
    int i;

    always_ff @( posedge i_clk ) begin : delayyyyy
      if (!i_rst_n) begin
        s_db_o_exp_m_pipe <= '{default:'0};
        s_db_o_valid_pipe <= '{default:'0};
      end
      else begin
        s_db_o_exp_m_pipe[0] <= s_o_exp_m;
        s_db_o_valid_pipe[0] <= s_o_valid;

        for (i = 1; i < DELAY_BUFFER_LATENCY; i++) begin
          s_db_o_exp_m_pipe[i] <= s_db_o_exp_m_pipe[i-1];
          s_db_o_valid_pipe[i] <= s_db_o_valid_pipe[i-1];
        end
      end // !i_rst_n else begin
    end // delayyyyy

    always_comb begin
      s_db_o_exp_m = s_db_o_exp_m_pipe[DELAY_BUFFER_LATENCY-1];
      s_db_o_valid = s_db_o_valid_pipe[DELAY_BUFFER_LATENCY-1];
    end
  end
endgenerate

//=====================================================================================
// Final assignment
//=====================================================================================
// assign o_metadata = i_metadata;
assign o_exp_m = s_db_o_exp_m;
assign o_valid = s_db_o_valid;
assign o_sanity_identifier = 4'b0000;
assign o_error = '0;
assign o_debug = '0;

endmodule // module fixed64_partitionf_ts #()
