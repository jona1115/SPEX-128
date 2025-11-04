/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for 64bit IEEE-754 floating point format
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package binary64_pkg;

    typedef struct packed {
        logic           sign;
        logic [10:0]    exp;
        logic [51:0]   mantissa;
    } binary64_t;

endpackage : binary64_pkg
