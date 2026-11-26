// SPDX-License-Identifier: MIT
//
// The test design of the PS/PL interface of docs/pl-interface.md. It connects the PS7 cell directly:
//   M_AXI_GP0   a block of 32-bit registers, in each 128-byte step of the GP0 window
//   S_AXI_HP0   a 64-bit AXI3 master that writes a pattern to memory, or reads memory and counts the
//               words that differ from the pattern
//   IRQF2P[0]   high while STATUS.DONE or CTRL.SWIRQ is 1 (GIC ID 61, level high)
//   FCLK0       the clock of all three, with FCLKRESETN[0] as the reset
// pltest.c is the program for the PS. The register map is in docs/pl-interface.md and below.
//
// The LEDs are for a check over JTAG (SAMPLE of the boundary register), which works when the GP0 bus
// cannot: LD0 is bit 26 of a counter on FCLK0, LD1 bit 26 of a counter on SYSCLK, LD2 BUSY, LD3 the IRQ.

module pynq_z2_pl_interface (
    input  logic       sysclk,      // 125 MHz from the Ethernet PHY, H16 (docs/clocks.md)
    output logic [3:0] led
);
    localparam logic [31:0] ID = 32'h504C_4931;     // "PLI1"

    // ---- PS7 cell -------------------------------------------------------------------------------
    logic [3:0]  fclk, fclk_resetn;
    logic        clk;
    BUFG fclk0_bufg (.I(fclk[0]), .O(clk));

    // M_AXI_GP0 (the PS is the master)
    logic [31:0] gp_awaddr, gp_araddr, gp_wdata, gp_rdata;
    logic [11:0] gp_awid, gp_arid, gp_bid, gp_rid;
    logic [3:0]  gp_awlen, gp_arlen, gp_wstrb;
    logic        gp_awvalid, gp_awready, gp_wvalid, gp_wready, gp_wlast;
    logic        gp_bvalid, gp_bready, gp_arvalid, gp_arready, gp_rvalid, gp_rready, gp_rlast;

    // S_AXI_HP0 (the PL is the master)
    logic [31:0] hp_awaddr, hp_araddr;
    logic [63:0] hp_wdata, hp_rdata;
    logic [1:0]  hp_bresp, hp_rresp;
    logic        hp_awvalid, hp_awready, hp_wvalid, hp_wready, hp_wlast;
    logic        hp_bvalid, hp_bready, hp_arvalid, hp_arready, hp_rvalid, hp_rready, hp_rlast;

    logic        irq;

    PS7 ps7_i (
        .FCLKCLK(fclk), .FCLKRESETN(fclk_resetn), .FCLKCLKTRIGN(4'b0),
        // IRQF2P[19:16] are the nFIQ and nIRQ lines of the CPUs: they stay 0 (docs/vivado.md).
        .IRQF2P({19'b0, irq}),

        .MAXIGP0ACLK(clk),
        .MAXIGP0AWADDR(gp_awaddr), .MAXIGP0AWID(gp_awid), .MAXIGP0AWLEN(gp_awlen),
        .MAXIGP0AWVALID(gp_awvalid), .MAXIGP0AWREADY(gp_awready),
        .MAXIGP0WDATA(gp_wdata), .MAXIGP0WSTRB(gp_wstrb), .MAXIGP0WLAST(gp_wlast),
        .MAXIGP0WVALID(gp_wvalid), .MAXIGP0WREADY(gp_wready),
        .MAXIGP0BID(gp_bid), .MAXIGP0BRESP(2'b00), .MAXIGP0BVALID(gp_bvalid), .MAXIGP0BREADY(gp_bready),
        .MAXIGP0ARADDR(gp_araddr), .MAXIGP0ARID(gp_arid), .MAXIGP0ARLEN(gp_arlen),
        .MAXIGP0ARVALID(gp_arvalid), .MAXIGP0ARREADY(gp_arready),
        .MAXIGP0RDATA(gp_rdata), .MAXIGP0RID(gp_rid), .MAXIGP0RRESP(2'b00), .MAXIGP0RLAST(gp_rlast),
        .MAXIGP0RVALID(gp_rvalid), .MAXIGP0RREADY(gp_rready),

        .SAXIHP0ACLK(clk),
        .SAXIHP0AWADDR(hp_awaddr), .SAXIHP0AWID(6'd0), .SAXIHP0AWLEN(4'd15), .SAXIHP0AWSIZE(2'b11),
        .SAXIHP0AWBURST(2'b01), .SAXIHP0AWCACHE(4'b0011), .SAXIHP0AWPROT(3'b000), .SAXIHP0AWLOCK(2'b00),
        .SAXIHP0AWQOS(4'd0), .SAXIHP0AWVALID(hp_awvalid), .SAXIHP0AWREADY(hp_awready),
        .SAXIHP0WDATA(hp_wdata), .SAXIHP0WID(6'd0), .SAXIHP0WSTRB(8'hFF), .SAXIHP0WLAST(hp_wlast),
        .SAXIHP0WVALID(hp_wvalid), .SAXIHP0WREADY(hp_wready),
        .SAXIHP0BRESP(hp_bresp), .SAXIHP0BVALID(hp_bvalid), .SAXIHP0BREADY(hp_bready),
        .SAXIHP0ARADDR(hp_araddr), .SAXIHP0ARID(6'd0), .SAXIHP0ARLEN(4'd15), .SAXIHP0ARSIZE(2'b11),
        .SAXIHP0ARBURST(2'b01), .SAXIHP0ARCACHE(4'b0011), .SAXIHP0ARPROT(3'b000), .SAXIHP0ARLOCK(2'b00),
        .SAXIHP0ARQOS(4'd0), .SAXIHP0ARVALID(hp_arvalid), .SAXIHP0ARREADY(hp_arready),
        .SAXIHP0RDATA(hp_rdata), .SAXIHP0RRESP(hp_rresp), .SAXIHP0RLAST(hp_rlast),
        .SAXIHP0RVALID(hp_rvalid), .SAXIHP0RREADY(hp_rready),
        .SAXIHP0RDISSUECAP1EN(1'b0), .SAXIHP0WRISSUECAP1EN(1'b0)
    );

    // FCLKRESETN[0] is 0 while FPGA_RST_CTRL[0] is 1. It is released here on the clock.
    logic [1:0] rst_sync;
    always_ff @(posedge clk or negedge fclk_resetn[0])
        if (!fclk_resetn[0]) rst_sync <= '0;
        else                 rst_sync <= {rst_sync[0], 1'b1};
    wire rst_n = rst_sync[1];

    // ---- Counters ---------------------------------------------------------------------------------
    logic [31:0] fclk_cnt;
    always_ff @(posedge clk) fclk_cnt <= fclk_cnt + 1;

    // SYSCLK counter, sent to the FCLK0 domain in Gray code: one bit changes at each step, so a
    // sample in the middle of a change is the old or the new value.
    logic [31:0] sys_cnt, sys_gray;
    always_ff @(posedge sysclk) begin
        sys_cnt  <= sys_cnt + 1;
        sys_gray <= sys_cnt ^ (sys_cnt >> 1);
    end
    (* ASYNC_REG = "TRUE" *) logic [31:0] sys_gray_s1, sys_gray_s2;
    logic [31:0] sys_cnt_f;
    always_ff @(posedge clk) begin
        sys_gray_s1 <= sys_gray;
        sys_gray_s2 <= sys_gray_s1;
        for (int i = 0; i < 32; i++) sys_cnt_f[i] <= ^(sys_gray_s2 >> i);     // Gray to binary
    end

    // ---- Registers ------------------------------------------------------------------------------
    // 0x00 ID       "PLI1"                                    ro
    // 0x04 SCRATCH  any value                                 rw
    // 0x08 CTRL     [0] START (write 1), [1] READ, [2] SWIRQ  rw ([0] reads 0)
    // 0x0C STATUS   [0] BUSY, [1] DONE, [2] RESP_ERR, [3] IRQ ro, [1] and [2] write 1 to clear
    // 0x10 ADDR     start address of the transfer; bits 6:0 are ignored (128-byte bursts)
    // 0x14 LEN      bytes; bits 6:0 are ignored
    // 0x18 SEED     the pattern: word i (64 bits) is {SEED ^ i, i}
    // 0x1C ERRORS   READ: the words that differed from the pattern
    // 0x20 CYCLES   FCLK0 cycles of the last transfer
    // 0x24 FCLKCNT  free-running counter on FCLK0
    // 0x28 SYSCNT   free-running counter on SYSCLK
    logic [31:0] scratch, addr, len, seed, errors, cycles;
    logic        mode_read, swirq, done, resp_err, busy, start;

    assign irq = done | swirq;

    function automatic logic [31:0] reg_read(input logic [4:0] a);
        case (a)
            5'h00:   reg_read = ID;
            5'h01:   reg_read = scratch;
            5'h02:   reg_read = {29'b0, swirq, mode_read, 1'b0};
            5'h03:   reg_read = {28'b0, irq, resp_err, done, busy};
            5'h04:   reg_read = addr;
            5'h05:   reg_read = len;
            5'h06:   reg_read = seed;
            5'h07:   reg_read = errors;
            5'h08:   reg_read = cycles;
            5'h09:   reg_read = fclk_cnt;
            5'h0A:   reg_read = sys_cnt_f;
            default: reg_read = 32'b0;
        endcase
    endfunction

    function automatic logic [31:0] merge(input logic [31:0] old, input logic [31:0] d, input logic [3:0] s);
        for (int b = 0; b < 4; b++) merge[b*8 +: 8] = s[b] ? d[b*8 +: 8] : old[b*8 +: 8];
    endfunction

    // ---- GP0 slave (AXI3; bursts are taken word by word) ------------------------------------------
    typedef enum logic [1:0] {W_ADDR, W_DATA, W_RESP} wstate_t;
    wstate_t     ws;
    logic [4:0]  wa;
    logic        reg_we;
    assign gp_awready = (ws == W_ADDR);
    assign gp_wready  = (ws == W_DATA);
    assign gp_bvalid  = (ws == W_RESP);
    assign reg_we     = gp_wvalid && gp_wready;

    always_ff @(posedge clk)
        if (!rst_n) ws <= W_ADDR;
        else case (ws)
            W_ADDR: if (gp_awvalid) begin ws <= W_DATA; wa <= gp_awaddr[6:2]; gp_bid <= gp_awid; end
            W_DATA: if (gp_wvalid) begin wa <= wa + 1; if (gp_wlast) ws <= W_RESP; end
            W_RESP: if (gp_bready) ws <= W_ADDR;
            default: ws <= W_ADDR;
        endcase

    typedef enum logic {R_ADDR, R_DATA} rstate_t;
    rstate_t     rs;
    logic [4:0]  ra;
    logic [3:0]  rleft;
    assign gp_arready = (rs == R_ADDR);
    assign gp_rvalid  = (rs == R_DATA);
    assign gp_rlast   = (rleft == 0);
    assign gp_rdata   = reg_read(ra);

    always_ff @(posedge clk)
        if (!rst_n) rs <= R_ADDR;
        else case (rs)
            R_ADDR: if (gp_arvalid) begin rs <= R_DATA; ra <= gp_araddr[6:2]; rleft <= gp_arlen; gp_rid <= gp_arid; end
            R_DATA: if (gp_rready) begin ra <= ra + 1; rleft <= rleft - 1; if (rleft == 0) rs <= R_ADDR; end
        endcase

    // ---- HP0 master --------------------------------------------------------------------------------
    typedef enum logic [2:0] {D_IDLE, D_AW, D_W, D_B, D_AR, D_R} dstate_t;
    dstate_t     ds;
    logic [31:0] cur, idx;
    logic [24:0] bursts;            // 128-byte bursts still to do
    logic [3:0]  beat;
    wire  [63:0] pattern = {seed ^ idx, idx};

    assign hp_awaddr  = cur;
    assign hp_araddr  = cur;
    assign hp_awvalid = (ds == D_AW);
    assign hp_wvalid  = (ds == D_W);
    assign hp_wdata   = pattern;
    assign hp_wlast   = (beat == 4'd15);
    assign hp_bready  = (ds == D_B);
    assign hp_arvalid = (ds == D_AR);
    assign hp_rready  = (ds == D_R);
    assign busy       = (ds != D_IDLE);

    always_ff @(posedge clk)
        if (!rst_n) begin
            ds <= D_IDLE;
            {scratch, addr, len, seed, errors, cycles} <= '0;
            {mode_read, swirq, done, resp_err, start} <= '0;
        end else begin
            start <= 1'b0;
            if (reg_we) case (wa)
                5'h01: scratch <= merge(scratch, gp_wdata, gp_wstrb);
                5'h02: if (gp_wstrb[0]) begin
                           start     <= gp_wdata[0];
                           mode_read <= gp_wdata[1];
                           swirq     <= gp_wdata[2];
                       end
                5'h03: if (gp_wstrb[0]) begin
                           if (gp_wdata[1]) done     <= 1'b0;
                           if (gp_wdata[2]) resp_err <= 1'b0;
                       end
                5'h04: addr <= merge(addr, gp_wdata, gp_wstrb);
                5'h05: len  <= merge(len,  gp_wdata, gp_wstrb);
                5'h06: seed <= merge(seed, gp_wdata, gp_wstrb);
                default: ;
            endcase

            if (busy) cycles <= cycles + 1;

            case (ds)
                D_IDLE: if (start && len[31:7] != 0) begin
                            cur    <= {addr[31:7], 7'b0};
                            bursts <= len[31:7];
                            idx    <= '0;
                            beat   <= '0;
                            errors <= '0;
                            cycles <= '0;
                            done   <= 1'b0;
                            ds     <= mode_read ? D_AR : D_AW;
                        end else if (start) done <= 1'b1;
                D_AW:   if (hp_awready) ds <= D_W;
                D_W:    if (hp_wready) begin
                            idx  <= idx + 1;
                            beat <= beat + 1;
                            if (hp_wlast) ds <= D_B;
                        end
                D_B:    if (hp_bvalid) begin
                            if (hp_bresp != 2'b00) resp_err <= 1'b1;
                            cur    <= cur + 128;
                            bursts <= bursts - 1;
                            if (bursts == 1) begin ds <= D_IDLE; done <= 1'b1; end
                            else ds <= D_AW;
                        end
                D_AR:   if (hp_arready) ds <= D_R;
                D_R:    if (hp_rvalid) begin
                            if (hp_rdata != pattern) errors <= errors + 1;
                            if (hp_rresp != 2'b00) resp_err <= 1'b1;
                            idx <= idx + 1;
                            if (hp_rlast) begin
                                cur    <= cur + 128;
                                bursts <= bursts - 1;
                                if (bursts == 1) begin ds <= D_IDLE; done <= 1'b1; end
                                else ds <= D_AR;
                            end
                        end
                default: ds <= D_IDLE;
            endcase
        end

    // ---- LEDs ---------------------------------------------------------------------------------------
    logic led1;
    always_ff @(posedge sysclk) led1 <= sys_cnt[26];
    always_ff @(posedge clk) begin
        led[0] <= fclk_cnt[26];
        led[2] <= busy;
        led[3] <= irq;
    end
    assign led[1] = led1;
endmodule
