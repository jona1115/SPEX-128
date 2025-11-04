/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for 32bit Qs10.21 fixed point format
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package fixed32_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [9:0]     int_portion;
        logic [20:0]   frac_portion;
    } fixed32_t;

endpackage : fixed32_pkg
