module float_to_fixed #() (
    input   logic [127:0]   i_float,
    input   logic [3:0]     i_ctrl,
    output  logic [127:0]   o_fixed
);

import float_flag_pkg::*;

/**
 * 
 * Specification:
 * 0. If i_ctrl[1:0] is 00:     1 x binary128 aka single_mode
 *    elif i_ctrl[1:0] is 01:   2 x binary64  aka two_subword_parallel_mode
 *    elif i_ctrl[1:0] is 10:   4 x binary32  aka four_subword_parallel_mode
 * 1. Do special type check:
 *    We assume that the input does not contain special types, so we need to assert
 *    a. Zero check:
 *       if single_mode:
 *           if i_float[126:0] all 0s:
 *               o_fixed = 128'0
 *    elif two_subword_parallel_mode:
 *           if i_float[126:64] all 0s:
 *               o_fixed[]
 *           if i_float[62:0] all 0s:
 *    elif four_subword_parallel_mode:
 * 2. We first calculate the "offset" of the exponent component
 *    if single_mode:
 *        shift_amount_a = i_float[126:112] - 16383
 *    elif two_subword_parallel_mode:
 *        shift_amount_a = i_float[126:116] - 1023
 *        shift_amount_b = i_float[62:52] - 1023
 *    elif four_subword_parallel_mode:
 *        shift_amount_a = i_float[126:119] - 127
 *        shift_amount_b = i_float[94:87] - 127
 *        shift_amount_c = i_float[62:55] - 127
 *        shift_amount_d = i_float[30:23] - 127
 * 
 */

// Passthrough (temp)
assign o_fixed = i_float;

endmodule