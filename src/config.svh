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
 * Everything labeled "knob" are defines you can comment/uncomment
 * that change the behavior of the code.
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
 * This is the master swich for vivado (uncommented) or not vivado (commented), this knob and the 
 * Genus knob should be mutually exclusive!
 */
// `define RUNNING_VIVADO_SYNTHESIS // knob

/**
 * This is the master swich for Cadence Genus (uncommented) or not Genus (commented), this knob and
 * the Vivado knob should be mutually exclusive!
 */
// `define RUNNING_GENUS_SYNTHESIS // knob

/**
  * Turn this define ON (uncomment) when synthesizing using Vivado, as it only recognize .data binary files
  * Turn thie design OFF (comment) when simulating using non-Vivado, as the testing infrastructure is set up
  * to read .hex files.
  */
`ifdef RUNNING_VIVADO_SYNTHESIS
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
 * LUT / ROM modeling
 *
 * In simulation, fixed_partition_sp uses $readmem* inside initial blocks to
 * initialize LUT contents.
 *
 * Vivado synthesis supports this style of ROM initialization, but many ASIC
 * synthesis tools (e.g. Genus) ignore initial blocks, which can cause the LUT
 * datapaths to be optimized away (since the ROM contents become "don't care").
 *
 * When SPEX_LUT_DUMMY is defined, fixed_partition_sp replaces LUT reads with a
 * deterministic, address-dependent dummy function (no memory inference). This
 * preserves the surrounding datapath for PPA studies when the ROM is off-chip.
 */
`ifdef RUNNING_GENUS_SYNTHESIS
  `define SPEX_LUT_DUMMY
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
// `define USE_DSP  // knob // DO NOT turn on in final product! Will cause output to be very wrong
`define USE_RADIX4_RECODING // knob

/**
 * Sometimes, if code changed when Vivado is closed, it won't know something changed. In that case,
 * feel free to use this flag to trigger a "file changed" detection.
 * 
 * This flag should not be used in any where. It is... "for fun"!
 */
`define FOR_FUN_FLAG // knob

`endif // CONFIG_SVH
