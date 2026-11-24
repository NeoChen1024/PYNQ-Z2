// The smallest PL design for the PYNQ-Z2: the PS is not used. LD0 to LD3 count at 125 MHz / 2^24
// (about 7.5 Hz for LD0); SW0 makes them count four times slower, and SW1 inverts them. Each button
// lights one color of the RGB LEDs, so that a look at the board checks the clock, the switches, the
// buttons and the LEDs.
// SYSCLK comes from the Ethernet PHY (docs/clocks.md): if the LEDs do not count, the PHY is in reset.
module pynq_z2_blinky (
    input  logic       sysclk,
    input  logic [1:0] sw,
    input  logic [3:0] btn,
    output logic [3:0] led,
    output logic       led4_r, led4_g, led4_b,
    output logic       led5_r
);
    logic [29:0] count = '0;
    always_ff @(posedge sysclk) count <= count + 1'b1;
    assign led = (sw[0] ? count[29:26] : count[27:24]) ^ {4{sw[1]}};
    assign {led5_r, led4_b, led4_g, led4_r} = btn;

    // A PS7 cell with nothing connected. Without a PS7 cell, a load of this bitstream while Linux
    // runs stops the PS within about 20 s (docs/vivado.md). Vivado ties the inputs of the empty cell.
    PS7 ps7_i ();
endmodule
