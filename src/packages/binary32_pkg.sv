/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for 32bit IEEE-754 floating point format
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package binary32_pkg;

    typedef struct packed {
        logic           sign;
        logic [7:0]     exp;
        logic [22:0]    mantissa;
    } binary32_t;

endpackage : binary32_pkg
