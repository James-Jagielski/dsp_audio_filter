# FPGA FIR Filter

audio filter part of the advanced computer architecture course at Olin

# Setup

The setup is designed for a
[Digilent CMOD A7](https://digilent.com/reference/programmable-logic/cmod-a7/start)
FPGA development board with a
[Digilent I2S PMOD](https://digilent.com/reference/pmod/pmodi2s2/start) board
attached to it. It should work with other Xilinx FPGA boards, but you will need
to provide your own XDC.

## Building a Bitstream with `sim.py`

Our `sim.py` tool does more than just run simulations; it also can synthesize
and flash a bitstream.

To build the bitstream for the full system

```
sim.py fpga/fir_system/ -s
```

This will use `vivado` to synthesize the FPGA. Note, you must set the
environment variable `FPGA_PART` to your particular fpga. In the case of the
digilent board: `FPGA_PART=xc7a35tcpg236-1`

To flash it to the board, you can use `vivado` or `djtgcfg`. You can do this
manually or use `sim.py`

```
sim.py fpga/fir_system -w vivado   # For vivado
sim.py fpga/fir_system -w digilent # For djtgcfg
```

The whole process can be combined together with

```
sim.py fpga/fir_system -s -w your-choice-of-programmer
```

`fir_system` should now synthesize and flash to a Cmod-A7 plugged into your
computer.

Button 0 resets the system, and button 1 switches between a loopback test and
the FIR filter.

The implemented filter is a band-pass filter with cutoffs of 50Hz and 8kHz.
