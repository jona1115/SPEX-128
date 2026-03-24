/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for the internal 128-bit Level-2 partition encoding
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package fixed128_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [9:0]     int_portion;
        logic [116:0]   frac_portion;
    } fixed128_t;

endpackage : fixed128_pkg
