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

// Turn this define ON (uncomment) when synthesizing using Vivado, as it only recognize .data binary files
// Turn thie design OFF (comment) when simulating using non-Vivado, as the testing infrastructure is set up
// to read .hex files.
// `define USE_RAM_DATA

// Used in fixed_partition_sp.sv and SPEX128_top.sv
`ifdef USE_RAM_DATA
  `define SPEX_RAM_EXT "data"
  `define SPEX_READMEM $readmemb
`else
  `define SPEX_RAM_EXT "hex"
  `define SPEX_READMEM $readmemh
`endif

// Used in sp_intmultiplier
// `define EN_DEBUG_PRINT
`define USE_RADIX4_RECODING

`endif // CONFIG_SVH