/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 2/8/2026
 * 
 ********************************************************************
 * 
 * Description:
 * Every module includes this file, and this file includes macro
 * flags combined into one file so it is easier to configure the
 * entire system.
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	    |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  2/8/2026    |  Birth of this file
 * 
 *******************************************************************/

`ifndef CONFIG_SVH
`define CONFIG_SVH

/**
 * This is the master swich for vivado (uncommented) or not vivado (commented)
 */
// `define RUNNING_VIVADO_SYNTHESIS

`ifdef RUNNING_VIVADO_SYNTHESIS
  /**
   * Turn this define ON (uncomment) when synthesizing using Vivado, as it only recognize .data binary files
   * Turn thie design OFF (comment) when simulating using non-Vivado, as the testing infrastructure is set up
   * to read .hex files.
   */
  `define USE_RAM_DATA
`endif

/**
 * Used in fixed_partition_sp.sv and SPEX128_top.sv
 */
`ifdef USE_RAM_DATA
  `define SPEX_RAM_EXT "data"
  `define SPEX_READMEM $readmemb
`else
  `define SPEX_RAM_EXT "hex"
  `define SPEX_READMEM $readmemh
`endif

/**
 * Some parts of fixed_partition_sp is written in a way that make this module highly reusable
 * whether you want to use 128 reusable LUT or not, and those parts are gated by parameters
 * which the synthesizer should be smart enough to exclude when compiling, as long as you
 * set the correct parameter flags. But to be safe this macro gates the compilation of those
 * parts if needed.
 * 
 * When this macro is set, those lines of code will be excluded by the compilation like a c
 * macro and will not be included in the synthesized hardware, hence "hardware" "blockout".
 */
`ifdef RUNNING_VIVADO_SYNTHESIS
  `define HARDWARE_BLOCKOUT
`endif

/**
 * Used in sp_intmultiplier
 */
// `define EN_DEBUG_PRINT
`define USE_RADIX4_RECODING

/**
 * Sometimes, if code changed when Vivado is closed, it won't know something changed. In that case,
 * feel free to use this flag to trigger a "file changed" detection.
 * 
 * This flag should not be used in any where. It is... "for fun"!
 */
`define FOR_FUN_FLAG

`endif // CONFIG_SVH
