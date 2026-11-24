// pinprobe: a JTAG instrument that reads every PL pin of the PYNQ-Z2, with no PS and no software
// on the board. All pins are inputs with the internal pull of the build (PULLUP or PULLDOWN), so a
// pin with an external pull or driver reads the same in both builds, and a floating pin follows
// the pull. The host reads and controls it through USER1 of the PL TAP (pinprobe.tcl, xsdb).
//
// Only these pins can be outputs: the I2C lines of the audio codec (open drain, by the scanner),
// its MCLK and ADR1, and the HPD of HDMI_IN. No header pin is ever driven. ADR0 stays an input: it is
// also CLATCH, and three low pulses on it put the ADAU1761 in SPI mode until a power cycle.
//
// USER1 data register, C bits, shifted LSB first:
//   capture: [7:0] 0xA5, [15:8] status, [16 +: N] pins, [16+N +: 128] I2C ACK map (bit = address)
//   update:  [7:0] control, taken only if [15:8] is 0xC3: hw_server shifts the USER registers when it
//            looks for debug cores, and must not change the control.
// status:  0 scan busy, 1 scan done, 2 SYSCLK alive (toggles at about 7.5 Hz), 3 MCLK on, 4 PULLUP build
// control: 0 start a scan (on each change), 1 MCLK on (12.5 MHz), 4/5 ADR1 drive/value,
//          6/7 HPD drive/value
`include "pinprobe_idx.svh"

module pinprobe (
    input  wire         sysclk,
    inout  wire [N-1:0] p
);
    localparam int C = 16 + N + 128;

    // ---- JTAG side ----
    wire capture, shift, update, sel, tck_raw, tdi, drck, reset, runtest, tms, tck;
    reg  tdo;
    BSCANE2 #(.JTAG_CHAIN(1)) bscan (
        .CAPTURE(capture), .DRCK(drck), .RESET(reset), .RUNTEST(runtest), .SEL(sel),
        .SHIFT(shift), .TCK(tck_raw), .TDI(tdi), .TMS(tms), .UPDATE(update), .TDO(tdo));
    BUFG tck_buf (.I(tck_raw), .O(tck));

    wire [N-1:0]   pin_in;
    reg  [127:0]   ack_map = '0;
    reg            busy = 0, done = 0, alive = 0;
    reg  [7:0]     ctrl = '0;
    reg  [C-1:0]   sr = '0;
    wire [7:0]     status = {3'b0, PULL_UP, ctrl[1], alive, done, busy};

    always @(posedge tck) begin
        if (sel && capture)      sr <= {ack_map, pin_in, status, 8'hA5};
        else if (sel && shift)   sr <= {tdi, sr[C-1:1]};
        if (sel && update && sr[15:8] == 8'hC3) ctrl <= sr[7:0];
    end
    always @(*) tdo = sr[0];

    // ---- SYSCLK side ----
    reg [23:0] div = '0;
    always @(posedge sysclk) begin
        div <= div + 1'b1;
        alive <= div[23];
    end

    // MCLK: 125 MHz / 10.
    reg [2:0] mdiv = '0;
    reg       mclk = 0;
    always @(posedge sysclk) begin
        if (mdiv == 3'd4) begin mdiv <= '0; mclk <= ~mclk; end
        else mdiv <= mdiv + 1'b1;
    end

    // I2C scanner: for each address 0x08 to 0x77, START, address + W, ACK bit, STOP. About 100 kHz.
    reg [2:0] go_sync = '0;
    always @(posedge sysclk) go_sync <= {go_sync[1:0], ctrl[0]};
    wire go = go_sync[2] ^ go_sync[1];

    localparam int Q = 312;              // a quarter of the SCL period, in SYSCLK cycles
    reg [8:0]  qcnt = '0;
    wire       tick = (qcnt == Q - 1);
    always @(posedge sysclk) qcnt <= tick ? '0 : qcnt + 1'b1;

    typedef enum logic [2:0] {IDLE, START, BITS, STOP, GAP} st_t;
    st_t       st = IDLE;
    reg [1:0]  ph = '0;
    reg [3:0]  bitn = '0;
    reg [6:0]  addr = '0;
    reg        scl_low = 0, sda_low = 0;
    wire       sda_in = pin_in[I_SDA];
    wire [7:0] byte_out = {addr, 1'b0};

    always @(posedge sysclk) begin
        if (go && st == IDLE) begin
            st <= START; ph <= '0; addr <= 7'h08; busy <= 1; done <= 0; ack_map <= '0;
        end else if (tick) begin
            ph <= ph + 1'b1;
            case (st)
                START: case (ph)
                    0: begin scl_low <= 0; sda_low <= 0; end
                    1: sda_low <= 1;                       // SDA falls while SCL is high
                    2: scl_low <= 1;
                    3: begin st <= BITS; bitn <= '0; end
                endcase
                BITS: case (ph)
                    0: begin scl_low <= 1; sda_low <= (bitn < 8) ? ~byte_out[7 - bitn[2:0]] : 1'b0; end
                    1: scl_low <= 0;
                    2: if (bitn == 8 && !sda_in) ack_map[addr] <= 1'b1;
                    3: begin
                        scl_low <= 1;
                        if (bitn == 8) st <= STOP; else bitn <= bitn + 1'b1;
                    end
                endcase
                STOP: case (ph)
                    0: begin scl_low <= 1; sda_low <= 1; end
                    1: scl_low <= 0;
                    2: sda_low <= 0;                       // SDA rises while SCL is high
                    3: st <= GAP;
                endcase
                GAP: if (ph == 3) begin
                    if (addr == 7'h77) begin st <= IDLE; busy <= 0; done <= 1; end
                    else begin addr <= addr + 1'b1; st <= START; end
                end
                default: ;
            endcase
        end
    end

    // ---- Pins ----
    genvar i;
    generate for (i = 0; i < N; i++) begin : io
        wire oe, val;
        if (i == I_SCL)       begin assign oe = scl_low; assign val = 1'b0; end
        else if (i == I_SDA)  begin assign oe = sda_low; assign val = 1'b0; end
        else if (i == I_MCLK) begin assign oe = ctrl[1]; assign val = mclk; end
        else if (i == I_ADR1) begin assign oe = ctrl[4]; assign val = ctrl[5]; end
        else if (i == I_HPD)  begin assign oe = ctrl[6]; assign val = ctrl[7]; end
        else                  begin assign oe = 1'b0;    assign val = 1'b0; end
        IOBUF b (.IO(p[i]), .I(val), .T(~oe), .O(pin_in[i]));
    end endgenerate

    // A PS7 cell with nothing connected: without it, a load while Linux runs stops the PS
    // (docs/vivado.md).
    PS7 ps7_i ();
endmodule
