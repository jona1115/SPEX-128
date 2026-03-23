/********************************************************************
 *
 * Originator   : Jonathan Tan feat. ChatGPT 5.2 Codex
 * Date         : 1/12/2026
 *
 ********************************************************************
 *
 * Description:
 * Parameterized LUT module for partitions across SINGLE/TWO/FOUR
 * sp_modes. Supports optional sign-bit handling for partition A and
 * optional 128->64/32 conversion when desired.
 * 
 * AI Use: This module is partially written by ChatGPT 5.4 and/or
 *         Codex 5.2/5.3/5.4.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  1/8/2026    |  Birth of this file
 *       1.01  |  Jonathan  |  3/23/2026    |  Split 128->64/32 pack stage for timing
 * 
 *******************************************************************/

`include "config.svh" // Here lives a bunch of macro flags...

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

module fixed_partition_sp #(
  parameter int CONVERSION_LATENCY      = 7,    // Must be the same as binary128_convert_pkg::CONVERSION_LATENCY

  // Behavior controls
  parameter bit HAS_SIGN                = 1'b0, // MSB is sign bit when set
  parameter bit USE_128_FOR_64          = 1'b0, // derive 64 outputs from 128 LUT
  parameter bit USE_128_FOR_32          = 1'b0, // derive 32 outputs from 128 LUT
  parameter bit USE_DEDICATED_32_FOR_CD = 1'b0, // when deriving 32b from 128 LUT, lanes c/d use dedicated 32b ROM
  parameter bit ENABLE_64               = 1'b1,
  parameter bit ENABLE_32               = 1'b1,

  parameter int MODULE_LATENCY_128      = 2,
  parameter int MODULE_LATENCY_64       = 2 + CONVERSION_LATENCY,
  parameter int MODULE_LATENCY_32       = USE_128_FOR_32 ? ((USE_DEDICATED_32_FOR_CD ? 2 : 3) + CONVERSION_LATENCY) : 3,

  // Address widths (excluding sign bit)
  parameter int ADDR_BITS_128           = 13,
  parameter int ADDR_BITS_64            = 13,
  parameter int ADDR_BITS_32            = 10,
  parameter int LANE_BITS_128           = ADDR_BITS_128 + (HAS_SIGN ? 1 : 0),
  parameter int LANE_BITS_64            = ADDR_BITS_64  + (HAS_SIGN ? 1 : 0),
  parameter int LANE_BITS_32            = ADDR_BITS_32  + (HAS_SIGN ? 1 : 0),

  // LUT files. For signed partitions, either provide *_POS/_NEG files or enable
  // USE_COMBINED_SIGNED_* and provide the combined *_FILE.
`ifndef RUNNING_GENUS_SYNTHESIS
  parameter string INIT_128_POS_FILE    = "",
  parameter string INIT_128_NEG_FILE    = "",
  parameter string INIT_128_FILE        = "",
  parameter string INIT_64_POS_FILE     = "",
  parameter string INIT_64_NEG_FILE     = "",
  parameter string INIT_64_FILE         = "",
  parameter string INIT_32_POS_FILE     = "",
  parameter string INIT_32_NEG_FILE     = "",
  parameter string INIT_32_FILE         = "",
`else
  parameter INIT_128_POS_FILE           = "",
  parameter INIT_128_NEG_FILE           = "",
  parameter INIT_128_FILE               = "",
  parameter INIT_64_POS_FILE            = "",
  parameter INIT_64_NEG_FILE            = "",
  parameter INIT_64_FILE                = "",
  parameter INIT_32_POS_FILE            = "",
  parameter INIT_32_NEG_FILE            = "",
  parameter INIT_32_FILE                = "",
`endif

  // Signed LUT file controls. When enabled, the sign bit becomes the MSB of the
  // ROM address and INIT_*_FILE is used instead of separate pos/neg files.
  parameter bit USE_COMBINED_SIGNED_128 = 1'b0,
  parameter bit USE_COMBINED_SIGNED_64  = 1'b0,
  parameter bit USE_COMBINED_SIGNED_32  = 1'b0,

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

  // Data inputs by mode
  input   logic [LANE_BITS_128-1:0]               i_lane_128,
  input   logic [LANE_BITS_64-1:0]                i_lane_64a,
  input   logic [LANE_BITS_64-1:0]                i_lane_64b,
  input   logic [LANE_BITS_32-1:0]                i_lane_32a,
  input   logic [LANE_BITS_32-1:0]                i_lane_32b,
  input   logic [LANE_BITS_32-1:0]                i_lane_32c,
  input   logic [LANE_BITS_32-1:0]                i_lane_32d,

  // Data outputs
  output  binary128_t                             o_exp_a128,
  output  binary64_t                              o_exp_64a,
  output  binary64_t                              o_exp_64b,
  output  binary32_t                              o_exp_32a,
  output  binary32_t                              o_exp_32b,
  output  binary32_t                              o_exp_32c,
  output  binary32_t                              o_exp_32d,

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

localparam int DEPTH_128 = (ADDR_BITS_128 > 0) ? (1 << ADDR_BITS_128) : 1;
localparam int DEPTH_64  = (ADDR_BITS_64  > 0) ? (1 << ADDR_BITS_64)  : 1;
localparam int DEPTH_32  = (ADDR_BITS_32  > 0) ? (1 << ADDR_BITS_32)  : 1;
localparam bit USE_COMBINED_SIGNED_128_L = HAS_SIGN && USE_COMBINED_SIGNED_128;
localparam bit USE_COMBINED_SIGNED_64_L  = HAS_SIGN && USE_COMBINED_SIGNED_64;
localparam bit USE_COMBINED_SIGNED_32_L  = HAS_SIGN && USE_COMBINED_SIGNED_32;
localparam int DEPTH_128_COMBINED = USE_COMBINED_SIGNED_128_L ? (1 << LANE_BITS_128) : 1;
localparam int DEPTH_64_COMBINED  = USE_COMBINED_SIGNED_64_L  ? (1 << LANE_BITS_64)  : 1;
localparam int DEPTH_32_COMBINED  = USE_COMBINED_SIGNED_32_L  ? (1 << LANE_BITS_32)  : 1;

function automatic logic [ADDR_BITS_128-1:0] addr128_from_64(
  input logic [ADDR_BITS_64-1:0] addr64
);
  addr128_from_64 = addr64;
endfunction

function automatic logic [ADDR_BITS_128-1:0] addr128_from_32(
  input logic [ADDR_BITS_32-1:0] addr32
);
  addr128_from_32 = addr32;
endfunction

//=====================================================================================
// LUTs
// 
// Here lives "real" and "fake" code. The "fake" stuff are stubs for Genus synthesis
// in which I don't want memory to be synthesized (because I don't have access to 
// memory macros/libraries). So for the stubs, they are a pseudo random deterministic
// function that will ensure that the datapaths won't get optimized away. They do not
// produce a valid result. This version is enabled if the RUNNING_GENUS_SYNTHESIS flag
// is set.
// 
// The "real" stuff are memory initialization code that will actually create lookup 
// tables and produce valid results. This version is enabled if the RUNNING_GENUS_SYNTHESIS
// flag is cleared (commented out).
//=====================================================================================
`ifndef USE_STUB_FOR_MEM_RD
`RAM_STYLE_WANTED logic [127:0] mem128_signed [0:DEPTH_128_COMBINED-1];
`RAM_STYLE_WANTED logic [127:0] mem128_pos    [0:DEPTH_128-1];
`RAM_STYLE_WANTED logic [127:0] mem128_neg    [0:DEPTH_128-1];
`RAM_STYLE_WANTED logic [63:0]  mem64_signed  [0:DEPTH_64_COMBINED-1];
`RAM_STYLE_WANTED logic [63:0]  mem64_pos     [0:DEPTH_64-1];
`RAM_STYLE_WANTED logic [63:0]  mem64_neg     [0:DEPTH_64-1];
`RAM_STYLE_WANTED logic [31:0]  mem32_signed  [0:DEPTH_32_COMBINED-1];
`RAM_STYLE_WANTED logic [31:0]  mem32_pos     [0:DEPTH_32-1];
`RAM_STYLE_WANTED logic [31:0]  mem32_neg     [0:DEPTH_32-1];
`DEDICATED_CD_32_RAM_STYLE_WANTED logic [31:0] mem32_cd_signed [0:DEPTH_32_COMBINED-1];
`DEDICATED_CD_32_RAM_STYLE_WANTED logic [31:0] mem32_cd_pos    [0:DEPTH_32-1];
`DEDICATED_CD_32_RAM_STYLE_WANTED logic [31:0] mem32_cd_neg    [0:DEPTH_32-1];

initial begin
  if (USE_COMBINED_SIGNED_128_L) begin
    if (INIT_128_FILE != "") `SPEX_READMEM(INIT_128_FILE, mem128_signed);
  end
  else if (HAS_SIGN) begin
    if (INIT_128_POS_FILE != "") `SPEX_READMEM(INIT_128_POS_FILE, mem128_pos);
    if (INIT_128_NEG_FILE != "") `SPEX_READMEM(INIT_128_NEG_FILE, mem128_neg);
  end
  else begin
    if (INIT_128_FILE != "") `SPEX_READMEM(INIT_128_FILE, mem128_pos);
  end
end

initial begin
  if (ENABLE_64 && !USE_128_FOR_64) begin
    if (USE_COMBINED_SIGNED_64_L) begin
      if (INIT_64_FILE != "") `SPEX_READMEM(INIT_64_FILE, mem64_signed);
    end
    else if (HAS_SIGN) begin
      if (INIT_64_POS_FILE != "") `SPEX_READMEM(INIT_64_POS_FILE, mem64_pos);
      if (INIT_64_NEG_FILE != "") `SPEX_READMEM(INIT_64_NEG_FILE, mem64_neg);
    end
    else begin
      if (INIT_64_FILE != "") `SPEX_READMEM(INIT_64_FILE, mem64_pos);
    end
  end

  if (ENABLE_32 && (!USE_128_FOR_32 || USE_DEDICATED_32_FOR_CD)) begin
    if (USE_COMBINED_SIGNED_32_L) begin
      if (INIT_32_FILE != "") `SPEX_READMEM(INIT_32_FILE, mem32_signed);
    end
    else if (HAS_SIGN) begin
      if (INIT_32_POS_FILE != "") `SPEX_READMEM(INIT_32_POS_FILE, mem32_pos);
      if (INIT_32_NEG_FILE != "") `SPEX_READMEM(INIT_32_NEG_FILE, mem32_neg);
    end
    else begin
      if (INIT_32_FILE != "") `SPEX_READMEM(INIT_32_FILE, mem32_pos);
    end
  end

  if (ENABLE_32 && USE_128_FOR_32 && USE_DEDICATED_32_FOR_CD) begin
    if (USE_COMBINED_SIGNED_32_L) begin
      if (INIT_32_FILE != "") `SPEX_READMEM(INIT_32_FILE, mem32_cd_signed);
    end
    else if (HAS_SIGN) begin
      if (INIT_32_POS_FILE != "") `SPEX_READMEM(INIT_32_POS_FILE, mem32_cd_pos);
      if (INIT_32_NEG_FILE != "") `SPEX_READMEM(INIT_32_NEG_FILE, mem32_cd_neg);
    end
    else begin
      if (INIT_32_FILE != "") `SPEX_READMEM(INIT_32_FILE, mem32_cd_pos);
    end
  end
end
`endif

`ifdef USE_STUB_FOR_MEM_RD
// Part of the stub
function automatic logic [31:0] USE_STUB_FOR_MEM_RD_xorshift32(
  input logic [31:0] i_state
);
  logic [31:0] state;
  state = i_state;
  state ^= (state << 13);
  state ^= (state >> 17);
  state ^= (state << 5);
  return state;
endfunction

// Part of the stub
function automatic logic [127:0] spex_lut128_read_stub(
  input logic                   i_use_neg,
  input logic [ADDR_BITS_128-1:0] i_addr
);
  logic [31:0] seed;
  logic [127:0] result;
  seed = 32'hc1f6_a09d ^ {28'h0, MODULE_IDENTIFIER} ^ {{(32-ADDR_BITS_128){1'b0}}, i_addr};
  if (HAS_SIGN && i_use_neg) begin
    seed ^= 32'h7f4a_7c15;
  end
  for (int word_idx = 0; word_idx < 4; word_idx++) begin
    seed = USE_STUB_FOR_MEM_RD_xorshift32(seed);
    result[word_idx*32 +: 32] = seed;
  end
  return result;
endfunction

// Part of the stub
function automatic logic [63:0] spex_lut64_read_stub(
  input logic                  i_use_neg,
  input logic [ADDR_BITS_64-1:0] i_addr
);
  logic [31:0] seed;
  logic [63:0] result;
  seed = 32'h4a2c_7d91 ^ {28'h0, MODULE_IDENTIFIER} ^ {{(32-ADDR_BITS_64){1'b0}}, i_addr};
  if (HAS_SIGN && i_use_neg) begin
    seed ^= 32'hb3f1_11c7;
  end
  for (int word_idx = 0; word_idx < 2; word_idx++) begin
    seed = USE_STUB_FOR_MEM_RD_xorshift32(seed);
    result[word_idx*32 +: 32] = seed;
  end
  return result;
endfunction

// Part of the stub
function automatic logic [31:0] spex_lut32_read(
  input logic                  i_use_neg,
  input logic [ADDR_BITS_32-1:0] i_addr
);
  logic [31:0] seed;
  seed = 32'h2f94_ae35 ^ {28'h0, MODULE_IDENTIFIER} ^ {{(32-ADDR_BITS_32){1'b0}}, i_addr};
  if (HAS_SIGN && i_use_neg) begin
    seed ^= 32'h1b56_c4e9;
  end
  return USE_STUB_FOR_MEM_RD_xorshift32(seed + 32'hbb67_ae85);
endfunction
`endif // `ifdef USE_STUB_FOR_MEM_RD

`ifdef USE_STUB_FOR_MEM_RD
  `define SPEX_LUT128_READ_MACRO(i_use_neg, i_addr) \
            spex_lut128_read_stub(i_use_neg, i_addr);
`else
  `define SPEX_LUT128_READ_MACRO(i_use_neg, i_addr) \
            USE_COMBINED_SIGNED_128_L ? mem128_signed[{i_use_neg, i_addr}] : \
            ((HAS_SIGN && i_use_neg) ? mem128_neg[i_addr] : mem128_pos[i_addr]);
`endif

`ifdef USE_STUB_FOR_MEM_RD
  `define SPEX_LUT64_READ_MACRO(i_use_neg, i_addr) \
            spex_lut64_read_stub(i_use_neg, i_addr);
`else
  `define SPEX_LUT64_READ_MACRO(i_use_neg, i_addr) \
            USE_COMBINED_SIGNED_64_L ? mem64_signed[{i_use_neg, i_addr}] : \
            ((HAS_SIGN && i_use_neg) ? mem64_neg[i_addr] : mem64_pos[i_addr]);
`endif

`ifdef USE_STUB_FOR_MEM_RD
  `define SPEX_LUT32_READ_MACRO(i_use_neg, i_addr) \
            spex_lut32_read(i_use_neg, i_addr);
  `define SPEX_LUT32_CD_READ_MACRO(i_use_neg, i_addr) \
            spex_lut32_read(i_use_neg, i_addr);
`else
  `define SPEX_LUT32_READ_MACRO(i_use_neg, i_addr) \
            USE_COMBINED_SIGNED_32_L ? mem32_signed[{i_use_neg, i_addr}] : \
            ((HAS_SIGN && i_use_neg) ? mem32_neg[i_addr] : mem32_pos[i_addr]);
  `define SPEX_LUT32_CD_READ_MACRO(i_use_neg, i_addr) \
            USE_COMBINED_SIGNED_32_L ? mem32_cd_signed[{i_use_neg, i_addr}] : \
            ((HAS_SIGN && i_use_neg) ? mem32_cd_neg[i_addr] : mem32_cd_pos[i_addr]);
`endif


//=====================================================================================
// Module body
//=====================================================================================
// Default stuff out
logic [DEBUG_SIGNAL_NUM_BITS-1:0]   s_o_debug;
logic [ERROR_SIGNAL_NUM_BITS-1:0]   s_o_error;
always_ff @( posedge i_clk ) begin : defaulter
  if (!i_rst_n) begin
    s_o_error <= '0;
    s_o_debug <= '0;
  end
end

/**
 * Stage 1b registers: Propogate valid bits and metadata across stages.
 *
 * Note: in FOUR_SP_MODE, lanes c/d may either be read one stage later from
 * the shared 128b BRAM (legacy path) or captured for the hybrid dedicated-32b
 * path, so we keep them buffered here.
 */
logic                     s_S1b_valid128;
logic                     s_S1b_valid64a;
logic                     s_S1b_valid64b;
logic                     s_S1b_valid32a;
logic                     s_S1b_valid32b;
logic                     s_S1b_valid32c;
logic                     s_S1b_valid32d;
logic [LANE_BITS_32-1:0]  s_S1b_lane_32c;
logic [LANE_BITS_32-1:0]  s_S1b_lane_32d;
float_metadata_t          s_S1b_metadata;

/**
 *
 * State transition control
 *
 */
localparam int PIPE_DEPTH = (MODULE_LATENCY_32 < 8) ? 8 : MODULE_LATENCY_32;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid_next;

localparam int S2_OFFSET = 0;
localparam int S3_OFFSET = S2_OFFSET + 1;
localparam int S4_OFFSET = S3_OFFSET + 1;
localparam int S5_OFFSET = S4_OFFSET + 1;
localparam int S6_OFFSET = S5_OFFSET + 1;
localparam int S7_OFFSET = S6_OFFSET + 1;
localparam int S8_OFFSET = S7_OFFSET + 1;
localparam int S9_OFFSET = S8_OFFSET + 1;
localparam bit USE_HYBRID_32_CD = ENABLE_32 && USE_128_FOR_32 && USE_DEDICATED_32_FOR_CD;
localparam bit USE_LEGACY_32_CD_READ = ENABLE_32 && USE_128_FOR_32 && !USE_DEDICATED_32_FOR_CD;
localparam int HYBRID_32_CD_ALIGN_REGS = CONVERSION_LATENCY - 1;

// Decode the input valid signals
logic s_fire_raw;
assign s_fire_raw = i_metadata.sp_mode == SINGLE_MODE  ? i_valid128 :
                    i_metadata.sp_mode == TWO_SP_MODE  ? (i_valid64a & i_valid64b) :
                    i_metadata.sp_mode == FOUR_SP_MODE ? (i_valid32a & i_valid32b & i_valid32c & i_valid32d) :
                    '0;

/**
 * Legacy FOUR_SP_MODE uses a second shared-128b read for lanes c/d. During that
 * cycle the BRAM ports are fully occupied, so we must not accept a new input.
 */
logic s_stage2_four_read;
assign s_stage2_four_read = s_pipe_valid[S2_OFFSET] &&
                            USE_LEGACY_32_CD_READ &&
                            (s_S1b_metadata.sp_mode == FOUR_SP_MODE);

logic s_mem_busy;
assign s_mem_busy = s_stage2_four_read;

logic s_fire;
assign s_fire = s_fire_raw & ~s_mem_busy;

assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};

logic s_S1_en, s_S2_en, s_S3_en, s_S4_en, s_S5_en, s_S6_en, s_S7_en, s_S8_en, s_S9_en;
assign s_S1_en = s_fire;
assign s_S2_en = s_pipe_valid[S2_OFFSET];
assign s_S3_en = s_pipe_valid[S3_OFFSET];
assign s_S4_en = s_pipe_valid[S4_OFFSET];
assign s_S5_en = s_pipe_valid[S5_OFFSET];
assign s_S6_en = s_pipe_valid[S6_OFFSET];
assign s_S7_en = s_pipe_valid[S7_OFFSET];
assign s_S8_en = s_pipe_valid[S8_OFFSET];
assign s_S9_en = s_pipe_valid[S9_OFFSET];

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
// Stage 1/2: Read LUTs
// - Shared 128-bit LUT read path for USE_128_FOR_* modes
// - Dedicated 64/32-bit LUT read path for native-width modes
//=====================================================================================
logic [63:0]  s_dlr_mem64_douta;
logic [63:0]  s_dlr_mem64_doutb;
logic [31:0]  s_dlr_mem32_douta;
logic [31:0]  s_dlr_mem32_doutb;
logic [31:0]  s_dlr_mem32_doutc;
logic [31:0]  s_dlr_mem32_doutd;
logic [31:0]  s_S2a_exp_32c_32_bits;
logic [31:0]  s_S2a_exp_32d_32_bits;

logic [ADDR_BITS_128-1:0] s_mem_addra;
logic [ADDR_BITS_128-1:0] s_mem_addrb;
logic                     s_mem_ena;
logic                     s_mem_enb;
logic                     s_mem_use_neg_a;
logic                     s_mem_use_neg_b;
logic [127:0]             s_slr_mem_douta;
logic [127:0]             s_slr_mem_doutb;

always_comb begin : shared_lut128_port_select
  s_mem_ena       = 1'b0;
  s_mem_enb       = 1'b0;
  s_mem_addra     = '0;
  s_mem_addrb     = '0;
  s_mem_use_neg_a = 1'b0;
  s_mem_use_neg_b = 1'b0;

  if (s_stage2_four_read) begin
    // Stage 2 FOUR_SP_MODE read: lanes c/d
    s_mem_ena   = 1'b1;
    s_mem_enb   = 1'b1;
    s_mem_addra = addr128_from_32(s_S1b_lane_32c[ADDR_BITS_32-1:0]);
    s_mem_addrb = addr128_from_32(s_S1b_lane_32d[ADDR_BITS_32-1:0]);
    if (HAS_SIGN) begin
      s_mem_use_neg_a = s_S1b_lane_32c[LANE_BITS_32-1];
      s_mem_use_neg_b = s_S1b_lane_32d[LANE_BITS_32-1];
    end
  end
  else if (s_S1_en) begin
    // Stage 1 read: SINGLE/TWO/FOUR (lanes a/b)
    case (i_metadata.sp_mode)
      SINGLE_MODE: begin
        s_mem_ena   = 1'b1;
        s_mem_addra = i_lane_128[ADDR_BITS_128-1:0];
        if (HAS_SIGN) begin
          s_mem_use_neg_a = i_lane_128[LANE_BITS_128-1];
        end
      end

      TWO_SP_MODE: begin
        if (ENABLE_64 && USE_128_FOR_64) begin
          s_mem_ena   = 1'b1;
          s_mem_enb   = 1'b1;
          s_mem_addra = addr128_from_64(i_lane_64a[ADDR_BITS_64-1:0]);
          s_mem_addrb = addr128_from_64(i_lane_64b[ADDR_BITS_64-1:0]);
          if (HAS_SIGN) begin
            s_mem_use_neg_a = i_lane_64a[LANE_BITS_64-1];
            s_mem_use_neg_b = i_lane_64b[LANE_BITS_64-1];
          end
        end
      end

      FOUR_SP_MODE: begin
        if (ENABLE_32 && USE_128_FOR_32) begin
          s_mem_ena   = 1'b1;
          s_mem_enb   = 1'b1;
          s_mem_addra = addr128_from_32(i_lane_32a[ADDR_BITS_32-1:0]);
          s_mem_addrb = addr128_from_32(i_lane_32b[ADDR_BITS_32-1:0]);
          if (HAS_SIGN) begin
            s_mem_use_neg_a = i_lane_32a[LANE_BITS_32-1];
            s_mem_use_neg_b = i_lane_32b[LANE_BITS_32-1];
          end
        end
      end

      default: begin
        // No-op
      end
    endcase
  end
end

always_ff @( posedge i_clk ) begin : shared_lut128_read // aka "slr"
  if (!i_rst_n) begin
    s_slr_mem_douta <= '0;
    s_slr_mem_doutb <= '0;
  end
  else begin
    if (s_mem_ena) begin
      s_slr_mem_douta <= `SPEX_LUT128_READ_MACRO(s_mem_use_neg_a, s_mem_addra);
    end
    if (s_mem_enb) begin
      s_slr_mem_doutb <= `SPEX_LUT128_READ_MACRO(s_mem_use_neg_b, s_mem_addrb);
    end
  end
end

always_ff @( posedge i_clk ) begin : dedicated_lut_read // aka "dlr"
  if (!i_rst_n) begin
    s_dlr_mem64_douta <= '0;
    s_dlr_mem64_doutb <= '0;
    s_dlr_mem32_douta <= '0;
    s_dlr_mem32_doutb <= '0;
    s_dlr_mem32_doutc <= '0;
    s_dlr_mem32_doutd <= '0;
  end
  else begin
    if (s_S1_en && ENABLE_64 && !USE_128_FOR_64 && i_metadata.sp_mode == TWO_SP_MODE) begin
      s_dlr_mem64_douta <= `SPEX_LUT64_READ_MACRO(i_lane_64a[LANE_BITS_64-1], i_lane_64a[ADDR_BITS_64-1:0]);
      s_dlr_mem64_doutb <= `SPEX_LUT64_READ_MACRO(i_lane_64b[LANE_BITS_64-1], i_lane_64b[ADDR_BITS_64-1:0]);
    end
    else begin
      s_dlr_mem64_douta <= '0;
      s_dlr_mem64_doutb <= '0;
    end

    if (s_S1_en && ENABLE_32 && i_metadata.sp_mode == FOUR_SP_MODE) begin
      if (!USE_128_FOR_32) begin
        s_dlr_mem32_douta <= `SPEX_LUT32_READ_MACRO(i_lane_32a[LANE_BITS_32-1], i_lane_32a[ADDR_BITS_32-1:0]);
        s_dlr_mem32_doutb <= `SPEX_LUT32_READ_MACRO(i_lane_32b[LANE_BITS_32-1], i_lane_32b[ADDR_BITS_32-1:0]);
        s_dlr_mem32_doutc <= '0;
        s_dlr_mem32_doutd <= '0;
      end
      else if (USE_HYBRID_32_CD) begin
        s_dlr_mem32_douta <= '0;
        s_dlr_mem32_doutb <= '0;
        s_dlr_mem32_doutc <= `SPEX_LUT32_CD_READ_MACRO(i_lane_32c[LANE_BITS_32-1], i_lane_32c[ADDR_BITS_32-1:0]);
        s_dlr_mem32_doutd <= `SPEX_LUT32_CD_READ_MACRO(i_lane_32d[LANE_BITS_32-1], i_lane_32d[ADDR_BITS_32-1:0]);
      end
      else begin
        s_dlr_mem32_douta <= '0;
        s_dlr_mem32_doutb <= '0;
        s_dlr_mem32_doutc <= '0;
        s_dlr_mem32_doutd <= '0;
      end
    end
    else begin
      s_dlr_mem32_douta <= '0;
      s_dlr_mem32_doutb <= '0;
      s_dlr_mem32_doutc <= '0;
      s_dlr_mem32_doutd <= '0;
    end
  end
end

/**
 * Stage 1b block: Propogate valid bit and metadata bits
 */
always_ff @( posedge i_clk ) begin : stage1b
  if (!i_rst_n) begin
    s_S1b_valid128 <= '0;
    s_S1b_valid64a <= '0;
    s_S1b_valid64b <= '0;
    s_S1b_valid32a <= '0;
    s_S1b_valid32b <= '0;
    s_S1b_valid32c <= '0;
    s_S1b_valid32d <= '0;
    s_S1b_lane_32c <= '0;
    s_S1b_lane_32d <= '0;
    s_S1b_metadata <= '0;
  end
  else begin
    s_S1b_valid128 <= s_S1_en & i_valid128;
    s_S1b_valid64a <= s_S1_en & i_valid64a;
    s_S1b_valid64b <= s_S1_en & i_valid64b;
    s_S1b_valid32a <= s_S1_en & i_valid32a;
    s_S1b_valid32b <= s_S1_en & i_valid32b;
    s_S1b_valid32c <= s_S1_en & i_valid32c;
    s_S1b_valid32d <= s_S1_en & i_valid32d;
    if (s_S1_en) begin
      s_S1b_lane_32c <= i_lane_32c;
      s_S1b_lane_32d <= i_lane_32d;
    end
    s_S1b_metadata <= i_metadata;
  end
end


//=====================================================================================
// Stage 2:
// - 128b, 64b "early exit"
// - feeds staged 128->64/32 conversion pipelines for conversion paths
// - direct 64/32 LUT pass-through for non-conversion paths
//=====================================================================================
always_ff @( posedge i_clk ) begin : dedicated_lut_read_cd
  if (!i_rst_n) begin
    s_S2a_exp_32c_32_bits <= '0;
    s_S2a_exp_32d_32_bits <= '0;
  end
  else begin
    if (s_S2_en && ENABLE_32 && s_S1b_metadata.sp_mode == FOUR_SP_MODE) begin
      if (!USE_128_FOR_32) begin
        s_S2a_exp_32c_32_bits <= `SPEX_LUT32_READ_MACRO(s_S1b_lane_32c[LANE_BITS_32-1], s_S1b_lane_32c[ADDR_BITS_32-1:0]);
        s_S2a_exp_32d_32_bits <= `SPEX_LUT32_READ_MACRO(s_S1b_lane_32d[LANE_BITS_32-1], s_S1b_lane_32d[ADDR_BITS_32-1:0]);
      end
      else if (USE_HYBRID_32_CD) begin
        s_S2a_exp_32c_32_bits <= s_dlr_mem32_doutc;
        s_S2a_exp_32d_32_bits <= s_dlr_mem32_doutd;
      end
      else begin
        s_S2a_exp_32c_32_bits <= `SPEX_LUT32_READ_MACRO(s_S1b_lane_32c[LANE_BITS_32-1], s_S1b_lane_32c[ADDR_BITS_32-1:0]);
        s_S2a_exp_32d_32_bits <= `SPEX_LUT32_READ_MACRO(s_S1b_lane_32d[LANE_BITS_32-1], s_S1b_lane_32d[ADDR_BITS_32-1:0]);
      end
    end
    else begin
      s_S2a_exp_32c_32_bits <= '0;
      s_S2a_exp_32d_32_bits <= '0;
    end
  end
end

/**
 * Stage 2b: Produce lane a/b outputs.
 *           128->64/32 conversion paths run fully in this stage.
 */
binary128_t  s_S2b_exp_a128;
binary64_t   s_S2b_exp_64a;
binary64_t   s_S2b_exp_64b;
binary32_t   s_S2b_exp_32a;
binary32_t   s_S2b_exp_32b;
always_ff @( posedge i_clk ) begin : stage2b
  if (!i_rst_n) begin
    s_S2b_exp_a128    <= '0;
    s_S2b_exp_64a    <= '0;
    s_S2b_exp_64b    <= '0;
    s_S2b_exp_32a    <= '0;
    s_S2b_exp_32b    <= '0;
  end
  else begin
	    if (s_S2_en) begin
	      case (s_S1b_metadata.sp_mode)
	        SINGLE_MODE: begin
	          s_S2b_exp_a128 <= binary128_t'(s_slr_mem_douta);
	        end
	
	        TWO_SP_MODE: begin
	          if (ENABLE_64) begin
	            if (USE_128_FOR_64) begin
	              // 128->64 conversion is handled by the staged conversion pipeline.
	              s_S2b_exp_64a <= '0;
	              s_S2b_exp_64b <= '0;
	            end
	            else begin
                s_S2b_exp_64a <= binary64_t'(s_dlr_mem64_douta);
                s_S2b_exp_64b <= binary64_t'(s_dlr_mem64_doutb);
              end
            end
            else begin
              s_S2b_exp_64a <= '0;
              s_S2b_exp_64b <= '0;
            end
          end

	        FOUR_SP_MODE: begin
	          if (ENABLE_32) begin
	            if (USE_128_FOR_32) begin
	              // 128->32 conversion is handled by the staged conversion pipeline.
	              s_S2b_exp_32a <= '0;
	              s_S2b_exp_32b <= '0;
	            end
	            else begin
                s_S2b_exp_32a <= binary32_t'(s_dlr_mem32_douta);
                s_S2b_exp_32b <= binary32_t'(s_dlr_mem32_doutb);
              end
            end
            else begin
              s_S2b_exp_32a <= '0;
              s_S2b_exp_32b <= '0;
            end
          end

        default: begin
          assert (0) else begin
            // s_o_error[1] <= 1'b1;
          end
        end
      endcase
    end
  end
end

/**
 * Stage 2c: Signals (valid and metadata bits) passthrough
 */
logic             s_S2c_valid128;
logic             s_S2c_valid64a;
logic             s_S2c_valid64b;
logic             s_S2c_valid32a;
logic             s_S2c_valid32b;
logic             s_S2c_valid32c;
logic             s_S2c_valid32d;
float_metadata_t  s_S2c_metadata;
always_ff @( posedge i_clk ) begin : stage2c_signal_passthrough
  if (!i_rst_n) begin
    s_S2c_valid128 <= '0;
    s_S2c_valid64a <= '0;
    s_S2c_valid64b <= '0;
    s_S2c_valid32a <= '0;
    s_S2c_valid32b <= '0;
    s_S2c_valid32c <= '0;
    s_S2c_valid32d <= '0;
    s_S2c_metadata <= '0;
  end
  else begin
    if (s_S2_en) begin
      s_S2c_valid128 <= s_S1b_valid128;
      s_S2c_valid64a <= s_S1b_valid64a;
      s_S2c_valid64b <= s_S1b_valid64b;
      s_S2c_valid32a <= s_S1b_valid32a;
      s_S2c_valid32b <= s_S1b_valid32b;
      s_S2c_valid32c <= s_S1b_valid32c;
      s_S2c_valid32d <= s_S1b_valid32d;
      s_S2c_metadata <= s_S1b_metadata;
    end // if (s_S2_en)
    else begin
      s_S2c_valid128 <= '0;
      s_S2c_valid64a <= '0;
      s_S2c_valid64b <= '0;
      s_S2c_valid32a <= '0;
      s_S2c_valid32b <= '0;
      s_S2c_valid32c <= '0;
      s_S2c_valid32d <= '0;
      s_S2c_metadata <= '0;
    end
  end // else begin
end // stage2c_signal_passthrough

//=====================================================================================
// binary128 -> binary64/binary32 conversion pipelines
// (7 stages: s0a unpack, s0b classify+prep, s1a lzc, s1b normalize+bookkeep, s2 shift+round, s3 rounding-add, s4 pack)
//=====================================================================================
localparam int CONV64_LANES = 2;
localparam int CONV32_LANES = 4;

logic [127:0] s_conv64_in_bits [CONV64_LANES];
logic [CONV64_LANES-1:0] s_conv64_in_valid;
binary128_to_binary64_rne_s0a_t s_conv64_s0a_q [CONV64_LANES];
binary128_to_binary64_rne_s0_t s_conv64_s0b_q [CONV64_LANES];
binary128_to_binary64_rne_s1a_t s_conv64_s1a_q [CONV64_LANES];
binary128_to_binary64_rne_s1_t s_conv64_s1b_q [CONV64_LANES];
binary128_to_binary64_rne_s2_t s_conv64_s2_q [CONV64_LANES];
binary128_to_binary64_rne_s3_t s_conv64_s3_q [CONV64_LANES];
binary128_to_binary64_rne_s0a_t s_conv64_s0a_d [CONV64_LANES];
binary128_to_binary64_rne_s0_t s_conv64_s0b_d [CONV64_LANES];
binary128_to_binary64_rne_s1a_t s_conv64_s1a_d [CONV64_LANES];
binary128_to_binary64_rne_s1_t s_conv64_s1b_d [CONV64_LANES];
binary128_to_binary64_rne_s2_t s_conv64_s2_d [CONV64_LANES];
binary128_to_binary64_rne_s3_t s_conv64_s3_d [CONV64_LANES];
binary64_t s_conv64_out_d [CONV64_LANES];
binary64_t s_conv64_out_q [CONV64_LANES];
logic [CONV64_LANES-1:0] s_conv64_v0_q;
logic [CONV64_LANES-1:0] s_conv64_v1_q;
logic [CONV64_LANES-1:0] s_conv64_v2_q;
logic [CONV64_LANES-1:0] s_conv64_v3_q;
logic [CONV64_LANES-1:0] s_conv64_v4_q;
logic [CONV64_LANES-1:0] s_conv64_v5_q;
logic [CONV64_LANES-1:0] s_conv64_v6_q;

logic [127:0] s_conv32_in_bits [CONV32_LANES];
logic [CONV32_LANES-1:0] s_conv32_in_valid;
binary128_to_binary32_rne_s0a_t s_conv32_s0a_q [CONV32_LANES];
binary128_to_binary32_rne_s0_t s_conv32_s0b_q [CONV32_LANES];
binary128_to_binary32_rne_s1a_t s_conv32_s1a_q [CONV32_LANES];
binary128_to_binary32_rne_s1_t s_conv32_s1b_q [CONV32_LANES];
binary128_to_binary32_rne_s2_t s_conv32_s2_q [CONV32_LANES];
binary128_to_binary32_rne_s3_t s_conv32_s3_q [CONV32_LANES];
binary128_to_binary32_rne_s0a_t s_conv32_s0a_d [CONV32_LANES];
binary128_to_binary32_rne_s0_t s_conv32_s0b_d [CONV32_LANES];
binary128_to_binary32_rne_s1a_t s_conv32_s1a_d [CONV32_LANES];
binary128_to_binary32_rne_s1_t s_conv32_s1b_d [CONV32_LANES];
binary128_to_binary32_rne_s2_t s_conv32_s2_d [CONV32_LANES];
binary128_to_binary32_rne_s3_t s_conv32_s3_d [CONV32_LANES];
binary32_t s_conv32_out_d [CONV32_LANES];
binary32_t s_conv32_out_q [CONV32_LANES];
logic [CONV32_LANES-1:0] s_conv32_v0_q;
logic [CONV32_LANES-1:0] s_conv32_v1_q;
logic [CONV32_LANES-1:0] s_conv32_v2_q;
logic [CONV32_LANES-1:0] s_conv32_v3_q;
logic [CONV32_LANES-1:0] s_conv32_v4_q;
logic [CONV32_LANES-1:0] s_conv32_v5_q;
logic [CONV32_LANES-1:0] s_conv32_v6_q;

binary32_t s_conv32_ab_align_q [2];
logic [1:0] s_conv32_ab_align_valid_q;
binary32_t s_hybrid32_cd_exp_32c_q [HYBRID_32_CD_ALIGN_REGS-1:0];
binary32_t s_hybrid32_cd_exp_32d_q [HYBRID_32_CD_ALIGN_REGS-1:0];
logic      s_hybrid32_cd_valid32c_q [HYBRID_32_CD_ALIGN_REGS-1:0];
logic      s_hybrid32_cd_valid32d_q [HYBRID_32_CD_ALIGN_REGS-1:0];

always_comb begin : conversion_input_select
  for (int lane = 0; lane < CONV64_LANES; lane++) begin
    s_conv64_in_bits[lane] = '0;
  end
  s_conv64_in_valid = '0;

  for (int lane = 0; lane < CONV32_LANES; lane++) begin
    s_conv32_in_bits[lane] = '0;
  end
  s_conv32_in_valid = '0;

  if (s_S2_en && ENABLE_64 && USE_128_FOR_64 && s_S1b_metadata.sp_mode == TWO_SP_MODE) begin
    s_conv64_in_bits[0] = s_slr_mem_douta;
    s_conv64_in_bits[1] = s_slr_mem_doutb;
    s_conv64_in_valid[0] = s_S1b_valid64a;
    s_conv64_in_valid[1] = s_S1b_valid64b;
  end

  if (s_S2_en && ENABLE_32 && USE_128_FOR_32 && s_S1b_metadata.sp_mode == FOUR_SP_MODE) begin
    s_conv32_in_bits[0] = s_slr_mem_douta;
    s_conv32_in_bits[1] = s_slr_mem_doutb;
    s_conv32_in_valid[0] = s_S1b_valid32a;
    s_conv32_in_valid[1] = s_S1b_valid32b;
  end

  if (s_S3_en && USE_LEGACY_32_CD_READ && s_S2c_metadata.sp_mode == FOUR_SP_MODE) begin
    s_conv32_in_bits[2] = s_slr_mem_douta;
    s_conv32_in_bits[3] = s_slr_mem_doutb;
    s_conv32_in_valid[2] = s_S2c_valid32c;
    s_conv32_in_valid[3] = s_S2c_valid32d;
  end
end

always_comb begin : conversion_pipeline_comb
  for (int lane = 0; lane < CONV64_LANES; lane++) begin
    s_conv64_s0a_d[lane] = binary128_to_binary64_rne_s0a(s_conv64_in_bits[lane]);
    s_conv64_s0b_d[lane] = binary128_to_binary64_rne_s0b(s_conv64_s0a_q[lane]);
    s_conv64_s1a_d[lane] = binary128_to_binary64_rne_s1a(s_conv64_s0b_q[lane]);
    s_conv64_s1b_d[lane] = binary128_to_binary64_rne_s1b(s_conv64_s1a_q[lane]);
    s_conv64_s2_d[lane] = binary128_to_binary64_rne_s2(s_conv64_s1b_q[lane]);
    s_conv64_s3_d[lane] = binary128_to_binary64_rne_s3a(s_conv64_s2_q[lane]);
    s_conv64_out_d[lane] = binary128_to_binary64_rne_s4(s_conv64_s3_q[lane]);
  end

  for (int lane = 0; lane < CONV32_LANES; lane++) begin
    s_conv32_s0a_d[lane] = binary128_to_binary32_rne_s0a(s_conv32_in_bits[lane]);
    s_conv32_s0b_d[lane] = binary128_to_binary32_rne_s0b(s_conv32_s0a_q[lane]);
    s_conv32_s1a_d[lane] = binary128_to_binary32_rne_s1a(s_conv32_s0b_q[lane]);
    s_conv32_s1b_d[lane] = binary128_to_binary32_rne_s1b(s_conv32_s1a_q[lane]);
    s_conv32_s2_d[lane] = binary128_to_binary32_rne_s2(s_conv32_s1b_q[lane]);
    s_conv32_s3_d[lane] = binary128_to_binary32_rne_s3a(s_conv32_s2_q[lane]);
    s_conv32_out_d[lane] = binary128_to_binary32_rne_s4(s_conv32_s3_q[lane]);
  end
end

always_ff @( posedge i_clk ) begin : conversion_pipeline_regs
  if (!i_rst_n) begin
    for (int lane = 0; lane < CONV64_LANES; lane++) begin
      s_conv64_s0a_q[lane] <= '0;
      s_conv64_s0b_q[lane] <= '0;
      s_conv64_s1a_q[lane] <= '0;
      s_conv64_s1b_q[lane] <= '0;
      s_conv64_s2_q[lane] <= '0;
      s_conv64_s3_q[lane] <= '0;
      s_conv64_out_q[lane] <= '0;
    end
    s_conv64_v0_q <= '0;
    s_conv64_v1_q <= '0;
    s_conv64_v2_q <= '0;
    s_conv64_v3_q <= '0;
    s_conv64_v4_q <= '0;
    s_conv64_v5_q <= '0;
    s_conv64_v6_q <= '0;

    for (int lane = 0; lane < CONV32_LANES; lane++) begin
      s_conv32_s0a_q[lane] <= '0;
      s_conv32_s0b_q[lane] <= '0;
      s_conv32_s1a_q[lane] <= '0;
      s_conv32_s1b_q[lane] <= '0;
      s_conv32_s2_q[lane] <= '0;
      s_conv32_s3_q[lane] <= '0;
      s_conv32_out_q[lane] <= '0;
    end
    s_conv32_v0_q <= '0;
    s_conv32_v1_q <= '0;
    s_conv32_v2_q <= '0;
    s_conv32_v3_q <= '0;
    s_conv32_v4_q <= '0;
    s_conv32_v5_q <= '0;
    s_conv32_v6_q <= '0;
    s_conv32_ab_align_q[0] <= '0;
    s_conv32_ab_align_q[1] <= '0;
    s_conv32_ab_align_valid_q <= '0;
  end
  else begin
    for (int lane = 0; lane < CONV64_LANES; lane++) begin
      s_conv64_s0a_q[lane] <= s_conv64_s0a_d[lane];
      s_conv64_s0b_q[lane] <= s_conv64_s0b_d[lane];
      s_conv64_s1a_q[lane] <= s_conv64_s1a_d[lane];
      s_conv64_s1b_q[lane] <= s_conv64_s1b_d[lane];
      s_conv64_s2_q[lane] <= s_conv64_s2_d[lane];
      s_conv64_s3_q[lane] <= s_conv64_s3_d[lane];
      s_conv64_out_q[lane] <= s_conv64_out_d[lane];
    end
    s_conv64_v0_q <= s_conv64_in_valid;
    s_conv64_v1_q <= s_conv64_v0_q;
    s_conv64_v2_q <= s_conv64_v1_q;
    s_conv64_v3_q <= s_conv64_v2_q;
    s_conv64_v4_q <= s_conv64_v3_q;
    s_conv64_v5_q <= s_conv64_v4_q;
    s_conv64_v6_q <= s_conv64_v5_q;

    for (int lane = 0; lane < CONV32_LANES; lane++) begin
      s_conv32_s0a_q[lane] <= s_conv32_s0a_d[lane];
      s_conv32_s0b_q[lane] <= s_conv32_s0b_d[lane];
      s_conv32_s1a_q[lane] <= s_conv32_s1a_d[lane];
      s_conv32_s1b_q[lane] <= s_conv32_s1b_d[lane];
      s_conv32_s2_q[lane] <= s_conv32_s2_d[lane];
      s_conv32_s3_q[lane] <= s_conv32_s3_d[lane];
      s_conv32_out_q[lane] <= s_conv32_out_d[lane];
    end
    s_conv32_v0_q <= s_conv32_in_valid;
    s_conv32_v1_q <= s_conv32_v0_q;
    s_conv32_v2_q <= s_conv32_v1_q;
    s_conv32_v3_q <= s_conv32_v2_q;
    s_conv32_v4_q <= s_conv32_v3_q;
    s_conv32_v5_q <= s_conv32_v4_q;
    s_conv32_v6_q <= s_conv32_v5_q;

    // Legacy FOUR_SP launches c/d one cycle later, so delay a/b once to match.
    s_conv32_ab_align_q[0] <= s_conv32_out_q[0];
    s_conv32_ab_align_q[1] <= s_conv32_out_q[1];
    s_conv32_ab_align_valid_q[0] <= s_conv32_v6_q[0];
    s_conv32_ab_align_valid_q[1] <= s_conv32_v6_q[1];
  end
end

always_ff @( posedge i_clk ) begin : hybrid_cd_alignment
  if (!i_rst_n) begin
    s_hybrid32_cd_exp_32c_q <= '{default:'0};
    s_hybrid32_cd_exp_32d_q <= '{default:'0};
    s_hybrid32_cd_valid32c_q <= '{default:'0};
    s_hybrid32_cd_valid32d_q <= '{default:'0};
  end
  else begin
    if (USE_HYBRID_32_CD && s_S3_en) begin
      s_hybrid32_cd_exp_32c_q[0] <= binary32_t'(s_S2a_exp_32c_32_bits);
      s_hybrid32_cd_exp_32d_q[0] <= binary32_t'(s_S2a_exp_32d_32_bits);
      s_hybrid32_cd_valid32c_q[0] <= s_S2c_valid32c;
      s_hybrid32_cd_valid32d_q[0] <= s_S2c_valid32d;
    end
    else begin
      s_hybrid32_cd_exp_32c_q[0] <= '0;
      s_hybrid32_cd_exp_32d_q[0] <= '0;
      s_hybrid32_cd_valid32c_q[0] <= '0;
      s_hybrid32_cd_valid32d_q[0] <= '0;
    end

    for (int align_stage = 1; align_stage < HYBRID_32_CD_ALIGN_REGS; align_stage++) begin
      if (USE_HYBRID_32_CD && s_pipe_valid[S3_OFFSET + align_stage]) begin
        s_hybrid32_cd_exp_32c_q[align_stage] <= s_hybrid32_cd_exp_32c_q[align_stage-1];
        s_hybrid32_cd_exp_32d_q[align_stage] <= s_hybrid32_cd_exp_32d_q[align_stage-1];
        s_hybrid32_cd_valid32c_q[align_stage] <= s_hybrid32_cd_valid32c_q[align_stage-1];
        s_hybrid32_cd_valid32d_q[align_stage] <= s_hybrid32_cd_valid32d_q[align_stage-1];
      end
      else begin
        s_hybrid32_cd_exp_32c_q[align_stage] <= '0;
        s_hybrid32_cd_exp_32d_q[align_stage] <= '0;
        s_hybrid32_cd_valid32c_q[align_stage] <= '0;
        s_hybrid32_cd_valid32d_q[align_stage] <= '0;
      end
    end
  end
end


//=====================================================================================
// Stage 3:
// - 64: pass-through of direct-LUT path results
// - 32: pass-through of direct-LUT path results
//=====================================================================================
logic             s_S3_valid64a;
logic             s_S3_valid64b;
logic             s_S3_valid32a;
logic             s_S3_valid32b;
logic             s_S3_valid32c;
logic             s_S3_valid32d;
logic             s_S3_valid32_quad;
float_metadata_t  s_S3_metadata;
binary32_t        s_S3_exp_32a;
binary32_t        s_S3_exp_32b;
binary32_t        s_S3_exp_32c;
binary32_t        s_S3_exp_32d;
always_ff @( posedge i_clk ) begin : stage3_lane_cd_conversion_and_passthrough
  if (!i_rst_n) begin
    s_S3_valid64a      <= '0;
    s_S3_valid64b      <= '0;
    s_S3_valid32a      <= '0;
    s_S3_valid32b      <= '0;
    s_S3_valid32c      <= '0;
    s_S3_valid32d      <= '0;
    s_S3_valid32_quad  <= '0;
    s_S3_metadata      <= '0;
    s_S3_exp_32a      <= '0;
    s_S3_exp_32b      <= '0;
    s_S3_exp_32c      <= '0;
    s_S3_exp_32d      <= '0;
  end
  else begin
    if (s_S3_en) begin
      s_S3_valid64a  <= s_S2c_valid64a;
      s_S3_valid64b  <= s_S2c_valid64b;
      s_S3_metadata  <= s_S2c_metadata;

      if (ENABLE_32 && USE_128_FOR_32 && s_S2c_metadata.sp_mode == FOUR_SP_MODE) begin
        // 128->32 conversion is handled by the staged conversion pipeline.
        s_S3_exp_32a       <= '0;
        s_S3_exp_32b       <= '0;
        s_S3_exp_32c       <= '0;
        s_S3_exp_32d       <= '0;
        s_S3_valid32a       <= '0;
        s_S3_valid32b       <= '0;
        s_S3_valid32c       <= '0;
        s_S3_valid32d       <= '0;
        s_S3_valid32_quad   <= '0;
      end
      else begin
        s_S3_exp_32a       <= s_S2b_exp_32a;
        s_S3_exp_32b       <= s_S2b_exp_32b;
        s_S3_exp_32c       <= binary32_t'(s_S2a_exp_32c_32_bits);
        s_S3_exp_32d       <= binary32_t'(s_S2a_exp_32d_32_bits);
        s_S3_valid32a       <= s_S2c_valid32a;
        s_S3_valid32b       <= s_S2c_valid32b;
        s_S3_valid32c       <= s_S2c_valid32c;
        s_S3_valid32d       <= s_S2c_valid32d;
        s_S3_valid32_quad   <= '0;
      end
    end
    else begin
      s_S3_valid64a      <= '0;
      s_S3_valid64b      <= '0;
      s_S3_valid32a      <= '0;
      s_S3_valid32b      <= '0;
      s_S3_valid32c      <= '0;
      s_S3_valid32d      <= '0;
      s_S3_valid32_quad  <= '0;
      s_S3_metadata      <= '0;
      s_S3_exp_32a      <= '0;
      s_S3_exp_32b      <= '0;
      s_S3_exp_32c      <= '0;
      s_S3_exp_32d      <= '0;
    end
  end
end


//=====================================================================================
// Stage 4:
// - align 64b outputs
// - keep FOUR_SP_MODE quad-valid bundling for 32b lanes
//=====================================================================================
logic             s_S4_valid64a;
logic             s_S4_valid64b;
logic             s_S4_valid32a;
logic             s_S4_valid32b;
logic             s_S4_valid32c;
logic             s_S4_valid32d;
logic             s_S4_valid32_quad;
float_metadata_t  s_S4_metadata;

always_ff @( posedge i_clk ) begin : stage4_output_alignment
  if (!i_rst_n) begin
    s_S4_valid64a <= '0;
    s_S4_valid64b <= '0;
    s_S4_valid32a <= '0;
    s_S4_valid32b <= '0;
    s_S4_valid32c <= '0;
    s_S4_valid32d <= '0;
    s_S4_valid32_quad <= '0;
    s_S4_metadata <= '0;
  end
  else begin
    if (s_S4_en) begin
      s_S4_metadata <= s_S3_metadata;
      s_S4_valid64a <= s_S3_valid64a;
      s_S4_valid64b <= s_S3_valid64b;

      if (ENABLE_32 && USE_128_FOR_32 && s_S3_metadata.sp_mode == FOUR_SP_MODE) begin
        s_S4_valid32a <= '0;
        s_S4_valid32b <= '0;
        s_S4_valid32c <= '0;
        s_S4_valid32d <= '0;
        s_S4_valid32_quad <= s_S3_valid32_quad;
      end
      else begin
        s_S4_valid32a <= s_S3_valid32a;
        s_S4_valid32b <= s_S3_valid32b;
        s_S4_valid32c <= s_S3_valid32c;
        s_S4_valid32d <= s_S3_valid32d;
        s_S4_valid32_quad <= '0;
      end
    end
    else begin
      s_S4_valid64a <= '0;
      s_S4_valid64b <= '0;
      s_S4_valid32a <= '0;
      s_S4_valid32b <= '0;
      s_S4_valid32c <= '0;
      s_S4_valid32d <= '0;
      s_S4_valid32_quad <= '0;
      s_S4_metadata <= '0;
    end
  end
end


//=====================================================================================
// Stage 5:
// - 32: final alignment of all four lane outputs
//=====================================================================================
logic             s_S5_valid32a;
logic             s_S5_valid32b;
logic             s_S5_valid32c;
logic             s_S5_valid32d;
float_metadata_t  s_S5_metadata;

always_ff @( posedge i_clk ) begin : stage5_lane_alignment
  if (!i_rst_n) begin
    s_S5_valid32a <= '0;
    s_S5_valid32b <= '0;
    s_S5_valid32c <= '0;
    s_S5_valid32d <= '0;
    s_S5_metadata <= '0;
  end
  else begin
    if (s_S5_en) begin
      s_S5_metadata <= s_S4_metadata;
      if (ENABLE_32 && USE_128_FOR_32 && s_S4_metadata.sp_mode == FOUR_SP_MODE) begin
        s_S5_valid32a <= s_S4_valid32_quad;
        s_S5_valid32b <= s_S4_valid32_quad;
        s_S5_valid32c <= s_S4_valid32_quad;
        s_S5_valid32d <= s_S4_valid32_quad;
      end
      else begin
        s_S5_valid32a <= s_S4_valid32a;
        s_S5_valid32b <= s_S4_valid32b;
        s_S5_valid32c <= s_S4_valid32c;
        s_S5_valid32d <= s_S4_valid32d;
      end
    end
    else begin
      s_S5_valid32a <= '0;
      s_S5_valid32b <= '0;
      s_S5_valid32c <= '0;
      s_S5_valid32d <= '0;
      s_S5_metadata <= '0;
    end
  end
end

//=====================================================================================
// Stage 6/7/8/9:
// - metadata alignment for 7-cycle 128->64/32 conversion paths
//=====================================================================================
float_metadata_t  s_S6_metadata;
float_metadata_t  s_S7_metadata;
float_metadata_t  s_S8_metadata;
float_metadata_t  s_S9_metadata;
always_ff @( posedge i_clk ) begin : stage6_metadata_alignment
  if (!i_rst_n) begin
    s_S6_metadata <= '0;
  end
  else begin
    if (s_S6_en) begin
      s_S6_metadata <= s_S5_metadata;
    end
    else begin
      s_S6_metadata <= '0;
    end
  end
end

always_ff @( posedge i_clk ) begin : stage7_metadata_alignment
  if (!i_rst_n) begin
    s_S7_metadata <= '0;
  end
  else begin
    if (s_S7_en) begin
      s_S7_metadata <= s_S6_metadata;
    end
    else begin
      s_S7_metadata <= '0;
    end
  end
end

always_ff @( posedge i_clk ) begin : stage8_metadata_alignment
  if (!i_rst_n) begin
    s_S8_metadata <= '0;
  end
  else begin
    if (s_S8_en) begin
      s_S8_metadata <= s_S7_metadata;
    end
    else begin
      s_S8_metadata <= '0;
    end
  end
end

always_ff @( posedge i_clk ) begin : stage9_metadata_alignment
  if (!i_rst_n) begin
    s_S9_metadata <= '0;
  end
  else begin
    if (s_S9_en) begin
      s_S9_metadata <= s_S8_metadata;
    end
    else begin
      s_S9_metadata <= '0;
    end
  end
end


//=====================================================================================
// Final assignment
//=====================================================================================
always_comb begin : output_metadata_select
  logic valid64_now;
  logic valid32_now;

  valid64_now = USE_128_FOR_64 ? (s_conv64_v6_q[0] | s_conv64_v6_q[1])
                               : (s_S2c_valid64a | s_S2c_valid64b);
  valid32_now = USE_128_FOR_32 ? (USE_HYBRID_32_CD ? (s_conv32_v6_q[0] |
                                                      s_conv32_v6_q[1] |
                                                      s_hybrid32_cd_valid32c_q[HYBRID_32_CD_ALIGN_REGS-1] |
                                                      s_hybrid32_cd_valid32d_q[HYBRID_32_CD_ALIGN_REGS-1]) :
                                                      (s_conv32_ab_align_valid_q[0] |
                                                       s_conv32_ab_align_valid_q[1] |
                                                       s_conv32_v6_q[2] |
                                                       s_conv32_v6_q[3]))
                               : (s_S3_valid32a |
                                  s_S3_valid32b |
                                  s_S3_valid32c |
                                  s_S3_valid32d);

  if (s_S2c_valid128) begin
    o_metadata = s_S2c_metadata;
  end
  else if (ENABLE_64 && valid64_now) begin
    o_metadata = USE_128_FOR_64 ? s_S8_metadata : s_S2c_metadata;
  end
  else if (ENABLE_32 && valid32_now) begin
    o_metadata = USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_S8_metadata : s_S9_metadata) : s_S3_metadata;
  end
  else begin
    o_metadata = USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_S8_metadata : s_S9_metadata) : s_S3_metadata;
  end
end

assign o_exp_a128 = s_S2b_exp_a128;
assign o_exp_64a = ENABLE_64 ? (USE_128_FOR_64 ? s_conv64_out_q[0]      : s_S2b_exp_64a) : '0;
assign o_exp_64b = ENABLE_64 ? (USE_128_FOR_64 ? s_conv64_out_q[1]      : s_S2b_exp_64b) : '0;
assign o_exp_32a = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_conv32_out_q[0] : s_conv32_ab_align_q[0]) : s_S3_exp_32a)  : '0;
assign o_exp_32b = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_conv32_out_q[1] : s_conv32_ab_align_q[1]) : s_S3_exp_32b)  : '0;
assign o_exp_32c = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_hybrid32_cd_exp_32c_q[HYBRID_32_CD_ALIGN_REGS-1] : s_conv32_out_q[2]) : s_S3_exp_32c)  : '0;
assign o_exp_32d = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_hybrid32_cd_exp_32d_q[HYBRID_32_CD_ALIGN_REGS-1] : s_conv32_out_q[3]) : s_S3_exp_32d)  : '0;

assign o_valid128 = s_S2c_valid128;
assign o_valid64a = ENABLE_64 ? (USE_128_FOR_64 ? s_conv64_v6_q[0]              : s_S2c_valid64a) : 1'b0;
assign o_valid64b = ENABLE_64 ? (USE_128_FOR_64 ? s_conv64_v6_q[1]              : s_S2c_valid64b) : 1'b0;
assign o_valid32a = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_conv32_v6_q[0] : s_conv32_ab_align_valid_q[0]) : s_S3_valid32a)  : 1'b0;
assign o_valid32b = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_conv32_v6_q[1] : s_conv32_ab_align_valid_q[1]) : s_S3_valid32b)  : 1'b0;
assign o_valid32c = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_hybrid32_cd_valid32c_q[HYBRID_32_CD_ALIGN_REGS-1] : s_conv32_v6_q[2]) : s_S3_valid32c)  : 1'b0;
assign o_valid32d = ENABLE_32 ? (USE_128_FOR_32 ? (USE_HYBRID_32_CD ? s_hybrid32_cd_valid32d_q[HYBRID_32_CD_ALIGN_REGS-1] : s_conv32_v6_q[3]) : s_S3_valid32d)  : 1'b0;

assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = s_o_debug;

endmodule
