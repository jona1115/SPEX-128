/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains struct for metadata
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

package float_metadata_pkg;

    import float_flag_pkg::*;
    import sp_mode_pkg::*;

    typedef struct packed {
        sp_mode_t       sp_mode;      // 2 bits
        float_flag_t    float_type_a, // 3 bits
                        float_type_b, // 3 bits
                        float_type_c, // 3 bits
                        float_type_d; // 3 bits
    } float_metadata_t;

endpackage : float_metadata_pkg
