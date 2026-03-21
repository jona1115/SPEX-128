/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 1/27/2026
 * 
 ********************************************************************
 * 
 * Description:
 * This is a subword parallel int multiplier, intended to compute
 * the mantissa of sp_fpmultiplier. Performs the operation:
 *            int(anikin)*int(force)=int(jedi)
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	      |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  1/27/2026   |  Birth of this file
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
import unbiasing_pkg::*;

module ha (
  input  logic i_a,
  input  logic i_b,
  output logic o_sum,
  output logic o_carry
);
  assign o_sum   = i_a ^ i_b;
  assign o_carry = i_a & i_b;
endmodule

module fa (
  input  logic i_a,
  input  logic i_b,
  input  logic i_cin,
  output logic o_sum,
  output logic o_carry
);
  assign o_sum   = i_a ^ i_b ^ i_cin;
  assign o_carry = (i_a & i_b) | (i_a & i_cin) | (i_b & i_cin);
endmodule

module sp_intmultiplier #(
  parameter int NUM_BITS_128          = 128,
  parameter int NUM_BITS_64           = 64,
  parameter int NUM_BITS_32           = 32,

  parameter int EX_MAN_BITS_128       = 113,    // EXtended MANtissa number of BITS for fp128
  parameter int EX_MAN_BITS_64        = 53,     // EXtended MANtissa number of BITS for fp64
  parameter int EX_MAN_BITS_32        = 23,     // EXtended MANtissa number of BITS for fp32

  // Radix-4 PP matrix is widened by 2 columns so each row can encode 3X in parallel.
  parameter int RADIX4_PP_NBITS       = EX_MAN_BITS_128 + 2,
  parameter int RADIX4_ROWS           = (RADIX4_PP_NBITS + 1) / 2,
  parameter int RADIX4_DADDA_SC_NBITS = 6328,
  parameter int RADIX4_DADDA_Z_NBITS  = 230,
  parameter int RADIX2_DADDA_Z_NBITS  = 226,

`ifdef USE_DSP
  parameter int MODULE_LATENCY        = 12, // This has to match sp_fpmultiplier's INTMUL_LATENCY
`else
  parameter int MODULE_LATENCY        = 3, // This has to match sp_fpmultiplier's INTMUL_LATENCY
`endif

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

  // Data
  input   logic [EX_MAN_BITS_128-1 : 0]           i_anikin,
  input   logic [EX_MAN_BITS_128-1 : 0]           i_force,
  output  logic [EX_MAN_BITS_128*2-1 : 0]         o_jedi,

  // Upstream Handshake
  input   logic                                   i_valid_anikin,
  input   logic                                   i_valid_force,

  // Downstream Handshake
  output  logic                                   o_valid_jedi,

  // Module identifier
  output  logic [3 : 0]                           o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1 : 0]     o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1 : 0]     o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic [ERROR_SIGNAL_NUM_BITS-1:0]       s_o_error;

//=====================================================================================
// Module body
//=====================================================================================

`ifndef USE_DSP
/**
 * 
 * State transition control
 * 
 */
localparam int PIPE_DEPTH = MODULE_LATENCY;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid_next;

localparam int S2_OFFSET = 0;
localparam int S3_OFFSET = S2_OFFSET + 1;
// localparam int S4_OFFSET = S3_OFFSET + 1;

// Decode the input valid signals
logic s_fire;
assign s_fire = i_valid_anikin & i_valid_force;

assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};

logic s_S1_en, s_S2_en, s_S3_en, s_S4_en;
assign s_S1_en = s_fire;
assign s_S2_en = s_pipe_valid[S2_OFFSET];
assign s_S3_en = s_pipe_valid[S3_OFFSET];
// assign s_S4_en = s_pipe_valid[S4_OFFSET];

/**
 * FSM
 */
always_ff @( posedge i_clk ) begin : sp_intmultiplier_FSM
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end


//=====================================================================================
// Stage 1
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [EX_MAN_BITS_128-1 : 0]     s_pp    [0 : EX_MAN_BITS_128-1]; // A 2D array of partial products
  `include "helper/pen_and_paper_pp_generator.svh"
  logic [EX_MAN_BITS_128-1 : 0]     s_S1_pp [0 : EX_MAN_BITS_128-1];
`else
  // Radix 4
  logic [RADIX4_PP_NBITS-1 : 0]     s_pp    [0 : RADIX4_ROWS-1];
  `include "helper/radix4_pp_generator.svh"
  logic [RADIX4_PP_NBITS-1 : 0]     s_S1_pp [0 : RADIX4_ROWS-1];
`endif

logic s_S1_valid;
int debug_col, debug_row, debug_num_rows, debug_num_cols;
always_ff @( posedge i_clk ) begin : stage1a
  if (!i_rst_n) begin
    s_S1_valid  <= '0;
    s_S1_pp     <= '{default:'0};
  end
  else begin
    if (s_S1_en) begin
      s_S1_valid <= '1;
      s_S1_pp <= s_pp;

`ifdef EN_DEBUG_PRINT
  `ifndef USE_RADIX4_RECODING
      debug_num_rows = EX_MAN_BITS_128;
      debug_num_cols = EX_MAN_BITS_128;
  `else
      debug_num_rows = RADIX4_ROWS;
      debug_num_cols = RADIX4_PP_NBITS;
  `endif
      for (debug_row = 0; debug_row < debug_num_rows; debug_row = debug_row + 1) begin : pp_row_debug_loop
        for (debug_col = debug_num_cols-1; debug_col >= 0; debug_col = debug_col - 1) begin : pp_col_debug_loop
          $write("%x", s_pp[debug_row][debug_col]);
        end // pp_col_debug_loop
        $display("");
      end // pp_row_debug_loop
`endif
    end // if (s_S1_en)
    else begin
      s_S1_valid <= '0;
    end // else begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Stage 2
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [12431 : 0] S;
  logic [12431 : 0] C;
  `include "helper/dadda_compressor_reduce_tree.svh"
  logic [12431 : 0] s_S2_S;
  logic [12431 : 0] s_S2_C;
`else
  // Radix 4
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] S;
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] C;
  `include "helper/radix4_dadda_compressor_reduce_tree.svh"
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] s_S2_S;
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] s_S2_C;
`endif
always_ff @( posedge i_clk ) begin : stage2a
  if (!i_rst_n) begin
    s_S2_S <= '0;
    s_S2_C <= '0;

  end
  else begin
    if (s_S2_en) begin
      s_S2_S <= S;
      s_S2_C <= C;
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

`ifndef USE_RADIX4_RECODING
  logic [EX_MAN_BITS_128-1:0]   s_S2_pp [0:EX_MAN_BITS_128-1];
`else
  logic [RADIX4_PP_NBITS-1 : 0] s_S2_pp [0 : RADIX4_ROWS-1];
`endif
always_ff @( posedge i_clk ) begin : stage2b_signal_passthrough
  if (!i_rst_n) begin
    s_S2_pp <= '{default:'0};
  end
  else begin
    if (s_S2_en) begin
      s_S2_pp <= s_S1_pp;
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Stage 3
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  z0;
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  z1;
  `include "helper/dadda_compressor_final_rows.svh"
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`else
  // Radix 4
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  z0;
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  z1;
  `include "helper/radix4_dadda_compressor_final_rows.svh"
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`endif
logic [EX_MAN_BITS_128*2-1 : 0]       s_S3_jedi;
logic                                 s_S3_valid;

always_ff @( posedge i_clk ) begin : stage3a
  if (!i_rst_n) begin
    s_S3_jedi     <= '0;
    s_S3_valid    <= '0;
  end
  else begin
    if (s_S3_en) begin
      s_S3_jedi   <= s_S3_jedi_full[EX_MAN_BITS_128*2-1:0];
      s_S3_valid  <= 1'b1;
    end // if (s_S3_en)
    else begin
      s_S3_valid  <= '0;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_jedi = s_S3_jedi;
assign o_valid_jedi = s_S3_valid;

`else
// ifdef USE_DSP:
localparam int W            = 113;
localparam int OUT_W        = 226;
localparam int A_PAYLOAD_W  = 26;
localparam int B_PAYLOAD_W  = 17;
localparam int A_DSP_W      = 27;
localparam int B_DSP_W      = 18;
localparam int PROD_W       = 45;
localparam int NA           = (W + A_PAYLOAD_W - 1) / A_PAYLOAD_W;    // 5 rows of A tiles
localparam int NB           = (W + B_PAYLOAD_W - 1) / B_PAYLOAD_W;    // 7 columns of B tiles
localparam int A_PAD_W      = NA * A_PAYLOAD_W;                       // 130
localparam int B_PAD_W      = NB * B_PAYLOAD_W;                       // 119
localparam int DUP_TERM_A_IDX = 2;
localparam int DUP_TERM_B_IDX = 3;

localparam int ROW_CHAIN_STAGES    = 8;
localparam int ROW_LOW_DIGITS      = 6;
localparam int ROW_DIGITS_W        = ROW_LOW_DIGITS * B_PAYLOAD_W;
localparam int ROW_RESULT_W        = 48 + (ROW_LOW_DIGITS * B_PAYLOAD_W); // 150 bits
localparam int ROW_TREE_STAGES     = 3;
// DSP branch latency is fixed to 12 cycles from i_valid_* to o_valid_jedi:
// one operand capture stage, eight row-chain stages, and three final row-add stages.
localparam int DSP_TOTAL_LAT       = 1 + ROW_CHAIN_STAGES + ROW_TREE_STAGES;

localparam int ROW_STAGE_MUL_ONLY    = 0;
localparam int ROW_STAGE_MUL_SHR17   = 1;
localparam int ROW_STAGE_MUL_SAME    = 2;
localparam int ROW_STAGE_PASS        = 3;

logic s_fire;
logic [DSP_TOTAL_LAT-1 : 0] s_pipe_valid;
logic [DSP_TOTAL_LAT-1 : 0] s_pipe_valid_next;

logic [W-1 : 0] s_anikin_pipe [0 : ROW_CHAIN_STAGES-1];
logic [W-1 : 0] s_force_pipe  [0 : ROW_CHAIN_STAGES-1];
sp_mode_t       s_sp_mode_pipe [0 : ROW_CHAIN_STAGES-1];

(* use_dsp = "yes" *) logic [47 : 0] s_row_q [0 : NA-1][0 : ROW_CHAIN_STAGES-1];
logic [ROW_DIGITS_W-1 : 0]   s_row_digits [0 : NA-1][0 : ROW_CHAIN_STAGES-1];
logic [ROW_RESULT_W-1 : 0] s_row_full [0 : NA-1];
logic [OUT_W-1 : 0]        s_row_aligned [0 : NA-1];
logic [OUT_W-1 : 0]        s_row_sum_l1 [0 : 2];
logic [OUT_W-1 : 0]        s_row_sum_l2 [0 : 1];
logic [OUT_W-1 : 0]        s_row_sum_l3;

function automatic int fn_row_stage_mode(
  input sp_mode_t i_sp_mode,
  input int i_row_idx,
  input int i_stage_idx
);
  begin
    if (i_sp_mode == TWO_SP_MODE && i_row_idx == DUP_TERM_A_IDX) begin
      if (i_stage_idx == 0) begin
        fn_row_stage_mode = ROW_STAGE_MUL_ONLY;
      end
      else if (i_stage_idx == 4) begin
        fn_row_stage_mode = ROW_STAGE_MUL_SAME;
      end
      else begin
        fn_row_stage_mode = ROW_STAGE_MUL_SHR17;
      end
    end
    else begin
      if (i_stage_idx == 0) begin
        fn_row_stage_mode = ROW_STAGE_MUL_ONLY;
      end
      else if (i_stage_idx == ROW_CHAIN_STAGES-1) begin
        fn_row_stage_mode = ROW_STAGE_PASS;
      end
      else begin
        fn_row_stage_mode = ROW_STAGE_MUL_SHR17;
      end
    end
  end
endfunction

function automatic int fn_row_stage_b_idx(
  input sp_mode_t i_sp_mode,
  input int i_row_idx,
  input int i_stage_idx
);
  begin
    if (i_sp_mode == TWO_SP_MODE && i_row_idx == DUP_TERM_A_IDX && i_stage_idx >= 4) begin
      fn_row_stage_b_idx = i_stage_idx - 1;
    end
    else begin
      fn_row_stage_b_idx = i_stage_idx;
    end
  end
endfunction

function automatic logic fn_row_stage_use_hi_lane(
  input sp_mode_t i_sp_mode,
  input int i_row_idx,
  input int i_stage_idx
);
  begin
    fn_row_stage_use_hi_lane = (i_sp_mode == TWO_SP_MODE) &&
                               (i_row_idx == DUP_TERM_A_IDX) &&
                               (i_stage_idx == 4);
  end
endfunction

function automatic int fn_row_stage_digit_idx(
  input sp_mode_t i_sp_mode,
  input int       i_row_idx,
  input int       i_stage_idx
);
  begin
    fn_row_stage_digit_idx = -1;

    if (i_stage_idx == 0) begin
      fn_row_stage_digit_idx = 0;
    end
    else if (i_sp_mode == TWO_SP_MODE && i_row_idx == DUP_TERM_A_IDX) begin
      unique case (i_stage_idx)
        1: fn_row_stage_digit_idx = 1;
        2: fn_row_stage_digit_idx = 2;
        4: fn_row_stage_digit_idx = 3;
        5: fn_row_stage_digit_idx = 4;
        6: fn_row_stage_digit_idx = 5;
        default: begin
        end
      endcase
    end
    else begin
      if (i_stage_idx >= 1 && i_stage_idx <= 5) begin
        fn_row_stage_digit_idx = i_stage_idx;
      end
    end
  end
endfunction

function automatic logic [A_PAYLOAD_W-1 : 0] fn_row_a_payload(
  input logic [W-1 : 0] i_anikin,
  input sp_mode_t       i_sp_mode,
  input int             i_row_idx,
  input int             i_stage_idx
);
  logic [A_PAD_W-1 : 0] hs_a_pad;
  int                   hs_b_idx;
  logic                 hs_use_hi_lane;
  begin
    hs_a_pad       = {{(A_PAD_W-W){1'b0}}, i_anikin};
    hs_b_idx       = fn_row_stage_b_idx(i_sp_mode, i_row_idx, i_stage_idx);
    hs_use_hi_lane = fn_row_stage_use_hi_lane(i_sp_mode, i_row_idx, i_stage_idx);

    if (fn_row_stage_mode(i_sp_mode, i_row_idx, i_stage_idx) == ROW_STAGE_PASS) begin
      fn_row_a_payload = '0;
    end
    else begin
      fn_row_a_payload = fn_mask_a_payload(
        i_sp_mode,
        i_row_idx,
        hs_b_idx,
        hs_use_hi_lane,
        hs_a_pad[i_row_idx*A_PAYLOAD_W +: A_PAYLOAD_W]
      );
    end
  end
endfunction

function automatic logic [B_PAYLOAD_W-1 : 0] fn_row_b_payload(
  input logic [W-1 : 0] i_force,
  input sp_mode_t       i_sp_mode,
  input int             i_row_idx,
  input int             i_stage_idx
);
  logic [B_PAD_W-1 : 0] hs_b_pad;
  int                   hs_b_idx;
  logic                 hs_use_hi_lane;
  begin
    hs_b_pad       = {{(B_PAD_W-W){1'b0}}, i_force};
    hs_b_idx       = fn_row_stage_b_idx(i_sp_mode, i_row_idx, i_stage_idx);
    hs_use_hi_lane = fn_row_stage_use_hi_lane(i_sp_mode, i_row_idx, i_stage_idx);

    if (fn_row_stage_mode(i_sp_mode, i_row_idx, i_stage_idx) == ROW_STAGE_PASS) begin
      fn_row_b_payload = '0;
    end
    else begin
      fn_row_b_payload = fn_mask_b_payload(
        i_sp_mode,
        i_row_idx,
        hs_b_idx,
        hs_use_hi_lane,
        hs_b_pad[hs_b_idx*B_PAYLOAD_W +: B_PAYLOAD_W]
      );
    end
  end
endfunction

function automatic logic [A_PAYLOAD_W-1 : 0] fn_mask_a_payload(
  input sp_mode_t                 i_sp_mode,
  input int                       i_a_idx,
  input int                       i_b_idx,
  input logic                     i_use_hi_lane,
  input logic [A_PAYLOAD_W-1 : 0] i_payload
);
  logic [A_PAYLOAD_W-1 : 0] hs_masked;
  begin
    hs_masked = '0;

    unique case (i_sp_mode)
      SINGLE_MODE: begin
        hs_masked = i_payload;
      end

      TWO_SP_MODE: begin
        unique case (i_a_idx)
          0, 1: begin
            if (i_b_idx <= 3) begin
              hs_masked = i_payload;
            end
          end

          2: begin
            if (i_b_idx <= 2) begin
              hs_masked[0] = i_payload[0];
            end
            else if (i_b_idx == 3) begin
              if (i_use_hi_lane) begin
                hs_masked[25:3] = i_payload[25:3];
              end
              else begin
                hs_masked[0] = i_payload[0];
              end
            end
            else begin
              hs_masked[25:3] = i_payload[25:3];
            end
          end

          3, 4: begin
            if (i_b_idx >= 3) begin
              hs_masked = i_payload;
            end
          end

          default: begin
          end
        endcase
      end

      FOUR_SP_MODE: begin
        unique case (i_a_idx)
          0: begin
            if (i_b_idx <= 1) begin
              hs_masked[23:0] = i_payload[23:0];
            end
          end

          1: begin
            if (i_b_idx >= 1 && i_b_idx <= 2) begin
              hs_masked[23:0] = i_payload[23:0];
            end
          end

          2: begin
            if (i_b_idx >= 3 && i_b_idx <= 4) begin
              hs_masked[24:1] = i_payload[24:1];
            end
          end

          3: begin
            if (i_b_idx >= 4 && i_b_idx <= 6) begin
              hs_masked[24:1] = i_payload[24:1];
            end
          end

          default: begin
          end
        endcase
      end

      default: begin
      end
    endcase

    fn_mask_a_payload = hs_masked;
  end
endfunction

function automatic logic [B_PAYLOAD_W-1 : 0] fn_mask_b_payload(
  input sp_mode_t                 i_sp_mode,
  input int                       i_a_idx,
  input int                       i_b_idx,
  input logic                     i_use_hi_lane,
  input logic [B_PAYLOAD_W-1 : 0] i_payload
);
  logic [B_PAYLOAD_W-1 : 0] hs_masked;
  begin
    hs_masked = '0;

    unique case (i_sp_mode)
      SINGLE_MODE: begin
        hs_masked = i_payload;
      end

      TWO_SP_MODE: begin
        unique case (i_b_idx)
          0, 1, 2: begin
            if (i_a_idx <= 2) begin
              hs_masked = i_payload;
            end
          end

          3: begin
            if (i_a_idx <= 1) begin
              hs_masked[1:0] = i_payload[1:0];
            end
            else if (i_a_idx == 2) begin
              if (i_use_hi_lane) begin
                hs_masked[16:4] = i_payload[16:4];
              end
              else begin
                hs_masked[1:0] = i_payload[1:0];
              end
            end
            else begin
              hs_masked[16:4] = i_payload[16:4];
            end
          end

          4, 5, 6: begin
            if (i_a_idx >= 2) begin
              hs_masked = i_payload;
            end
          end

          default: begin
          end
        endcase
      end

      FOUR_SP_MODE: begin
        unique case (i_b_idx)
          0: begin
            if (i_a_idx == 0) begin
              hs_masked = i_payload;
            end
          end

          1: begin
            if (i_a_idx == 0) begin
              hs_masked[6:0] = i_payload[6:0];
            end
            else if (i_a_idx == 1) begin
              hs_masked[16:9] = i_payload[16:9];
            end
          end

          2: begin
            if (i_a_idx == 1) begin
              hs_masked = i_payload;
            end
          end

          3: begin
            if (i_a_idx == 2) begin
              hs_masked = i_payload;
            end
          end

          4: begin
            if (i_a_idx == 2) begin
              hs_masked[8:0] = i_payload[8:0];
            end
            else if (i_a_idx == 3) begin
              hs_masked[16:11] = i_payload[16:11];
            end
          end

          5, 6: begin
            if (i_a_idx == 3) begin
              hs_masked = i_payload;
            end
          end

          default: begin
          end
        endcase
      end

      default: begin
      end
    endcase

    fn_mask_b_payload = hs_masked;
  end
endfunction

assign s_fire = i_valid_anikin & i_valid_force;
assign s_pipe_valid_next = {s_pipe_valid[DSP_TOTAL_LAT-2 : 0], s_fire};

always_ff @( posedge i_clk ) begin : sp_intmultiplier_dsp_valid_pipe
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end

// Operand pipeline feeding the DSP-friendly row chains. Each row-chain stage consumes
// one cycle-delayed copy of the input mantissas so every sample carries its own future
// B-tile operands alongside the running 48-bit cascade state.
always_ff @( posedge i_clk ) begin : dsp_operand_pipe
  if (!i_rst_n) begin
    s_anikin_pipe  <= '{default:'0};
    s_force_pipe   <= '{default:'0};
    s_sp_mode_pipe <= '{default:SINGLE_MODE};
  end
  else begin
    s_anikin_pipe[0]  <= i_anikin;
    s_force_pipe[0]   <= i_force;
    s_sp_mode_pipe[0] <= i_metadata.sp_mode;

    for (int stage_idx = 1; stage_idx < ROW_CHAIN_STAGES; stage_idx++) begin
      s_anikin_pipe[stage_idx]  <= s_anikin_pipe[stage_idx-1];
      s_force_pipe[stage_idx]   <= s_force_pipe[stage_idx-1];
      s_sp_mode_pipe[stage_idx] <= s_sp_mode_pipe[stage_idx-1];
    end
  end
end

// Each row collapses its seven B tiles inside an 8-stage 48-bit cascade:
//   q_j = M_j + (q_{j-1} >> 17)
// The duplicated A2xB3 split tile in TWO_SP_MODE uses one same-shift stage so the two
// disjoint lane fragments are summed before the radix-2^17 carry propagation continues.
always_ff @( posedge i_clk ) begin : dsp_row_chain
  int                        hs_row_idx;
  int                        hs_stage_idx;
  int                        hs_stage_mode;
  int                        hs_digit_idx;
  logic [A_PAYLOAD_W-1 : 0]  hs_a_payload;
  logic [B_PAYLOAD_W-1 : 0]  hs_b_payload;
  logic [A_DSP_W-1 : 0]      hs_a_term;
  logic [B_DSP_W-1 : 0]      hs_b_term;
  logic [47 : 0]             hs_product;
  logic [47 : 0]             hs_prev_q;
  logic [47 : 0]             hs_cascade_q;
  logic [47 : 0]             hs_q_next;
  logic [ROW_DIGITS_W-1 : 0] hs_next_digits;

  if (!i_rst_n) begin
    for (hs_row_idx = 0; hs_row_idx < NA; hs_row_idx++) begin
      for (hs_stage_idx = 0; hs_stage_idx < ROW_CHAIN_STAGES; hs_stage_idx++) begin
        s_row_q[hs_row_idx][hs_stage_idx] <= '0;
        s_row_digits[hs_row_idx][hs_stage_idx] <= '0;
      end
    end
  end
  else begin
    for (hs_row_idx = 0; hs_row_idx < NA; hs_row_idx++) begin
      for (hs_stage_idx = 0; hs_stage_idx < ROW_CHAIN_STAGES; hs_stage_idx++) begin
        hs_stage_mode = fn_row_stage_mode(s_sp_mode_pipe[hs_stage_idx], hs_row_idx, hs_stage_idx);

        case (hs_stage_mode)
          ROW_STAGE_PASS: begin
            s_row_q[hs_row_idx][hs_stage_idx] <= s_row_q[hs_row_idx][hs_stage_idx-1];
            s_row_digits[hs_row_idx][hs_stage_idx] <= s_row_digits[hs_row_idx][hs_stage_idx-1];
          end

          default: begin
            hs_a_payload = fn_row_a_payload(
              s_anikin_pipe[hs_stage_idx],
              s_sp_mode_pipe[hs_stage_idx],
              hs_row_idx,
              hs_stage_idx
            );
            hs_b_payload = fn_row_b_payload(
              s_force_pipe[hs_stage_idx],
              s_sp_mode_pipe[hs_stage_idx],
              hs_row_idx,
              hs_stage_idx
            );
            hs_a_term    = {1'b0, hs_a_payload};
            hs_b_term    = {1'b0, hs_b_payload};
            hs_product   = hs_a_term * hs_b_term;
            hs_digit_idx = fn_row_stage_digit_idx(
              s_sp_mode_pipe[hs_stage_idx],
              hs_row_idx,
              hs_stage_idx
            );
            hs_next_digits = (hs_stage_idx == 0) ? '0 : s_row_digits[hs_row_idx][hs_stage_idx-1];

            if (hs_stage_idx == 0) begin
              hs_q_next = hs_product;
            end
            else begin
              hs_prev_q = s_row_q[hs_row_idx][hs_stage_idx-1];

              if (hs_stage_mode == ROW_STAGE_MUL_SAME) begin
                hs_cascade_q = hs_prev_q;
              end
              else begin
                hs_cascade_q = hs_prev_q >> B_PAYLOAD_W;
              end

              hs_q_next = hs_product + hs_cascade_q;
            end

            if (hs_digit_idx >= 0) begin
              hs_next_digits[hs_digit_idx*B_PAYLOAD_W +: B_PAYLOAD_W] = hs_q_next[B_PAYLOAD_W-1:0];
            end

            s_row_q[hs_row_idx][hs_stage_idx] <= hs_q_next;
            s_row_digits[hs_row_idx][hs_stage_idx] <= hs_next_digits;
          end
        endcase
      end
    end
  end
end

always_comb begin : dsp_row_reconstruct
  int hs_row_idx;

  s_row_full    = '{default:'0};
  s_row_aligned = '{default:'0};

  for (hs_row_idx = 0; hs_row_idx < NA; hs_row_idx++) begin
    s_row_full[hs_row_idx] = {s_row_q[hs_row_idx][7], s_row_digits[hs_row_idx][7]};
    s_row_aligned[hs_row_idx] = ({{(OUT_W-ROW_RESULT_W){1'b0}}, s_row_full[hs_row_idx]} << (hs_row_idx * A_PAYLOAD_W));
  end
end

always_ff @( posedge i_clk ) begin : dsp_row_tree_l1
  if (!i_rst_n) begin
    s_row_sum_l1 <= '{default:'0};
  end
  else begin
    s_row_sum_l1[0] <= s_row_aligned[0] + s_row_aligned[1];
    s_row_sum_l1[1] <= s_row_aligned[2] + s_row_aligned[3];
    s_row_sum_l1[2] <= s_row_aligned[4];
  end
end

always_ff @( posedge i_clk ) begin : dsp_row_tree_l2
  if (!i_rst_n) begin
    s_row_sum_l2 <= '{default:'0};
  end
  else begin
    s_row_sum_l2[0] <= s_row_sum_l1[0] + s_row_sum_l1[1];
    s_row_sum_l2[1] <= s_row_sum_l1[2];
  end
end

always_ff @( posedge i_clk ) begin : dsp_row_tree_l3
  if (!i_rst_n) begin
    s_row_sum_l3 <= '0;
  end
  else begin
    s_row_sum_l3 <= s_row_sum_l2[0] + s_row_sum_l2[1];
  end
end

assign o_jedi = s_row_sum_l3;
assign o_valid_jedi = s_pipe_valid[DSP_TOTAL_LAT-1];
assign s_o_error = '0;

`endif // end of `ifndef USE_DSP

assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = '0;

endmodule // module sp_intmultiplier #()
