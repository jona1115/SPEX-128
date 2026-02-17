/********************************************************************
 *
 * Originator   : Jonathan Tan
 * Date         : 01/11/2026
 *
 ********************************************************************
 *
 * Description:
 * Helpers to convert IEEE-754 binary128 to binary64/binary32 with
 * round-to-nearest, ties-to-even (RNE).
 *
 *******************************************************************/

package binary128_convert_pkg;
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

  /**
   * This is a huristics approach.
   * 
   * The mantissa is rounded using RNE
   * The exponent is rounded using huristics
   * 
   */
  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    binary128_t in;
    binary64_t  temp_out;
    binary64_t  out;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;

    logic MAN64_LSB;
    logic MAN128_G;
    logic MAN128_R;
    logic MAN128_S;

    sh_t shift_amount_128;
    logic [10 : 0] shift_amount_64;

    in = binary128_t'(in_bits);

    is_exp_all_ones = &in.exp;
    is_exp_zero     = ~|in.exp;
    is_frac_zero    = ~|in.mantissa;
    is_nan          = is_exp_all_ones && !is_frac_zero;
    is_inf          = is_exp_all_ones && is_frac_zero;
    is_zero         = is_exp_zero && is_frac_zero;

    // Initialize
    out = '0;

    // Handle IEEE-754 special types early.
    if (is_nan) begin
      out.sign     = in.sign;
      out.exp      = 11'h7ff;
      out.mantissa = {1'b1, in.mantissa[111:61]};
    end
    else if (is_inf) begin
      out.sign     = in.sign;
      out.exp      = 11'h7ff;
      out.mantissa = '0;
    end
    else if (is_zero) begin
      out.sign     = in.sign;
      out.exp      = '0;
      out.mantissa = '0;
    end
    else begin
      // Map 128 directly by truncation
      temp_out.sign      = in.sign;
      temp_out.exp       = in.exp;
      temp_out.mantissa  = in.mantissa[111:60];

      MAN64_LSB          = temp_out.mantissa[0];
      MAN128_G           = in.mantissa[59];
      MAN128_R           = in.mantissa[58];
      MAN128_S           = |in.mantissa[57:0]; // OR tree

      /**
       * Round the mantissa using RNE
       */
      if (MAN128_G === 1'b0) begin
        // Truncate
        out = temp_out;
      end // G=0
      else begin // G=1
        if (MAN128_R === 1'b1 || MAN128_S === 1'b1) begin
          // Round up
          out = temp_out + 1'b1;
        end
        else if (MAN128_R === 1'b0 || MAN128_S === 1'b0) begin
          // Even case
          if (MAN64_LSB === 1'b1) begin
            // Round up
            out = temp_out + 1'b1;
          end
          else begin
            // Truncate
            out = temp_out;
          end
        end
        else begin
          // this shouldn't logically happen, right?
          assert (0) else begin
            $error("Illegal case in binary128_convert_pkg.sv:binary128_to_binary64_rne");
          end
        end
      end

      shift_amount_128 = unbias_q128(in.exp);
      shift_amount_64  = rebias_q64(shift_amount_128);
      out.exp          = shift_amount_64;

      /**
       * Assign sign bit
       */
      out.sign = in.sign;
    end

    /**
     * Prepare output
     */
    binary128_to_binary64_rne = out;
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    binary128_t in;
    binary32_t  temp_out;
    binary32_t  out;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;

    logic MAN32_LSB;
    logic MAN128_G;
    logic MAN128_R;
    logic MAN128_S;

    in = binary128_t'(in_bits);

    is_exp_all_ones = &in.exp;
    is_exp_zero     = ~|in.exp;
    is_frac_zero    = ~|in.mantissa;
    is_nan          = is_exp_all_ones && !is_frac_zero;
    is_inf          = is_exp_all_ones && is_frac_zero;
    is_zero         = is_exp_zero && is_frac_zero;

    // Initialize
    out = '0;

    // Handle IEEE-754 special types early.
    if (is_nan) begin
      out.sign     = in.sign;
      out.exp      = 8'hff;
      out.mantissa = {1'b1, in.mantissa[111:90]};
    end
    else if (is_inf) begin
      out.sign     = in.sign;
      out.exp      = 8'hff;
      out.mantissa = '0;
    end
    else if (is_zero) begin
      out.sign     = in.sign;
      out.exp      = '0;
      out.mantissa = '0;
    end
    else begin
      // Map 128 directly by truncation
      temp_out.sign      = in.sign;
      temp_out.exp       = in.exp[7:0];
      temp_out.mantissa  = in.mantissa[111:89];

      MAN32_LSB          = temp_out.mantissa[0];
      MAN128_G           = in.mantissa[88];
      MAN128_R           = in.mantissa[87];
      MAN128_S           = |in.mantissa[86:0]; // OR tree

      /**
       * Round the mantissa using RNE
       */
      if (MAN128_G === 1'b0) begin
        // Truncate
        out = temp_out;
      end // G=0
      else begin // G=1
        if (MAN128_R === 1'b1 || MAN128_S === 1'b1) begin
          // Round up
          out = temp_out + 1'b1;
        end
        else if (MAN128_R === 1'b0 || MAN128_S === 1'b0) begin
          // Even case
          if (MAN32_LSB === 1'b1) begin
            // Round up
            out = temp_out + 1'b1;
          end
          else begin
            // Truncate
            out = temp_out;
          end
        end
        else begin
          // this shouldn't logically happen, right?
          assert (0) else begin
            $error("Illegal case in binary128_convert_pkg.sv:binary128_to_binary32_rne");
          end
        end
      end

      /**
       * Round the mantissa using huristics
       */
      // I realized that the lower 8 bits in 32b.exp is always the same as the lower 8 bits in 128.exp
      out.exp[7:0] = in.exp[7:0];

      /**
       * Assign sign bit
       */
      out.sign = in.sign;
    end

    /**
     * Prepare output
     */
    binary128_to_binary32_rne = out;
  endfunction

endpackage : binary128_convert_pkg
