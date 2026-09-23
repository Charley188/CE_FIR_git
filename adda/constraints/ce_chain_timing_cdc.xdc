# Clock periods and XPM FIFO CDC exceptions are supplied by the BD/IP XDCs.
# Keep this file narrow: it must not hide non-XPM data crossings.
set_property ASYNC_REG TRUE [get_cells -hier -regexp {^first_path_chain_inst/(adc|alg|dac)_reset_sync_inst/sync_ff_reg\[[0-2]\]$}]
