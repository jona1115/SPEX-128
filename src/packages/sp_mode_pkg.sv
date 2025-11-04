/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains enum for the operation types: SINGLE (1xbinary128), TWO (
 * 2xbinary64), and FOUR (4xbinary32) subword parallel (SP) modes.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package sp_mode_pkg;

    typedef enum logic [1:0] {
        SINGLE_MODE     = 2'b00, // This is for 1x binary128
        TWO_SP_MODE     = 2'b01, // This is for 2x binary64
        FOUR_SP_MODE    = 2'b10, // This is for 4x binary32
        INVALID_SP_MODE = 2'b11  // This is for all my... nvm, its for non of the above
    } sp_mode_t;

endpackage