onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label s_i_clk /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_i_clk
add wave -noupdate -label s_i_reset /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_i_reset
add wave -noupdate -color Magenta -label s_i_float -radix hexadecimal /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_i_float
add wave -noupdate -label s_i_ctrl /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_i_ctrl
add wave -noupdate -color Gold -label s_i_valid /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_i_valid
add wave -noupdate -color Magenta -label s_o_fixed -radix hexadecimal /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_o_fixed
add wave -noupdate -label s_o_metadata -expand /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/s_o_metadata
add wave -noupdate -divider {New Divider}
add wave -noupdate -label s_shift_amount_a /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_shift_amount_a
add wave -noupdate -label s_shift_amount_b /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_shift_amount_b
add wave -noupdate -label s_shift_amount_c /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_shift_amount_c
add wave -noupdate -label s_shift_amount_d /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_shift_amount_d
add wave -noupdate -label s_current_sp /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_current_sp
add wave -noupdate -divider {New Divider}
add wave -noupdate -label s_stage1_en /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_stage1_en
add wave -noupdate -label s_stage2_en /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_stage2_en
add wave -noupdate -label s_curr_state /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_curr_state
add wave -noupdate -label s_next_state /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_next_state
add wave -noupdate -divider {New Divider}
add wave -noupdate -label o_error -radix hexadecimal /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/o_error
add wave -noupdate -label s_binary128 -expand /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_binary128
add wave -noupdate -label s_fixed128 -expand /testrunner/__float_to_fixed_correctness_ts_ts/float_to_fixed_correctness_ut/my_float_to_fixed/s_fixed128
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {32 ns}
