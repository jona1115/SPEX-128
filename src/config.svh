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

// Mutex assert
`ifdef RUNNING_VIVADO_SYNTHESIS
  `ifdef RUNNING_GENUS_SYNTHESIS
    $fatal("Both RUNNING_VIVADO_SYNTHESIS and RUNNING_GENUS_SYNTHESIS flags are on! They are mutually exclusive. Fix it in config.svh!");
  `endif
`endif

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
 * When USE_STUB_FOR_MEM_RD is defined, fixed_partition_sp replaces LUT reads with a
 * deterministic, address-dependent dummy function (no memory inference). This
 * preserves the surrounding datapath for PPA studies when the ROM is off-chip.
 */
`ifdef RUNNING_GENUS_SYNTHESIS
  `define USE_STUB_FOR_MEM_RD
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
 * In fixed_partition_sp there are flags that forces Vivado to use BRAM or Distributed RAM etc.
 * These can be controlled by the below macros. The list of all available options on Xilinx
 * docs can be found here: https://docs.amd.com/r/en-US/ug901-vivado-synthesis/RAM_STYLE?tocId=zwm5O2Ah27nECzbaosBcJA
 *
 * Boolean define knobs in this section are on/off: comment or uncomment the whole line.
 *
 * Note: Only for Vivado flow, Cadence Genus will just ignore them.
 */
// `define FORCE_ALL_USE_BRAM    // knob
// `define FORCE_ALL_USE_LUTRAM  // knob
// `define FORCE_ALL_USE_MIXED   // knob
`define FORCE_ALL_USE_AUTO    // knob

`ifdef FORCE_ALL_USE_BRAM
  `define RAM_STYLE_WANTED (* ram_style = "block", rom_style = "block" *)
`elsif FORCE_ALL_USE_LUTRAM
  `define RAM_STYLE_WANTED (* ram_style = "distributed", rom_style = "distributed" *)
`elsif FORCE_ALL_USE_MIXED
  `define RAM_STYLE_WANTED (* ram_style = "mixed", rom_style = "mixed" *)
`elsif FORCE_ALL_USE_AUTO
  `define RAM_STYLE_WANTED (* ram_style = "auto", rom_style = "auto" *)
`endif

/**
 * Used in sp_intmultiplier
 */
// `define EN_DEBUG_PRINT
`define USE_DSP  // knob
`define USE_RADIX4_RECODING // knob

/**
 * Used in SPEX128_top.sv
 * 
 * As mentioned in the paper, a naive L2 is where each mode have its own lookup tables, and no conversion
 * logic is needed. If you want that, uncomment NAIVE_L2.
 */
// `define NAIVE_L2 // knob

/**
 * Used in SPEX128_top.sv
 * 
 * If this flag is turned off, the througput of 32-bit mode is 4 32-bit results per 2 cycles. With this turned
 * on, it is 4 32-bit results per cycle, at the cost of about 10 more RAMB36E2 slices or CLB_LUT if using LUR
 * which is controlled below RAM.
 */
`define USE_DEDICATED_LUT_FOR_LANE_CD // knob

/**
 * Boolean define knob for the hybrid FOUR_SP path.
 *
 * Uncomment this define to force the dedicated fixed32_* LUTs used for FOUR_SP_MODE
 * lanes c/d onto LUTRAM, while all other lookup tables continue to use RAM_STYLE_WANTED.
 */
// `define FORCE_DEDICATED_LANE_CD_32_USE_LUTRAM // knob

`ifdef FORCE_DEDICATED_LANE_CD_32_USE_LUTRAM
  `define DEDICATED_CD_32_RAM_STYLE_WANTED (* ram_style = "distributed", rom_style = "distributed" *)
`else
  `define DEDICATED_CD_32_RAM_STYLE_WANTED `RAM_STYLE_WANTED
`endif

/**
 * Sometimes, if code changed when Vivado is closed, it won't know something changed. In that case,
 * feel free to use this flag to trigger a "file changed" detection.
 * 
 * This flag should not be used in any where. It is... "for fun"!
 */
`define FOR_FUN_FLAG // knob

`endif // CONFIG_SVH
