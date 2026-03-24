/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for the internal 64-bit Level-2 partition encoding
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package fixed64_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [10:0]     int_portion;
        logic [51:0]   frac_portion;
    } fixed64_t;

endpackage : fixed64_pkg
