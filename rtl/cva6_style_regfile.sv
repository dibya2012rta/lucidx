// =============================================================================
// CVA6-Style Register File (Flip-Flop Based)
// -----------------------------------------------------------------------------
// 32 x 32-bit General Purpose Registers (x0 - x31)
// - Configurable number of async read  ports (NR_READ_PORTS)
// - Configurable number of sync  write ports (NR_WRITE_PORTS)
// - x0 is hardwired to zero; writes to x0 are silently ignored
// - Multiple simultaneous writes: highest port index wins on same-address conflict
// - No internal forwarding; handled externally (scoreboard / forwarding unit)
// - Designed to scale from simple in-order pipelines to multi-commit OOO cores
// =============================================================================

module cva6_style_regfile #(
    parameter int unsigned DATA_WIDTH    = 32,  // register width (XLEN)
    parameter int unsigned NR_READ_PORTS = 2,   // number of async read ports
    parameter int unsigned NR_WRITE_PORTS= 1    // number of sync write ports
) (
    input  logic                                          clk_i,
    input  logic                                          rst_ni,  // active-low async reset

    // -------------------------------------------------------------------------
    // Read Ports — async, all driven typically by ID / issue stage
    // -------------------------------------------------------------------------
    input  logic [NR_READ_PORTS-1:0][4:0]                raddr_i,
    output logic [NR_READ_PORTS-1:0][DATA_WIDTH-1:0]     rdata_o,

    // -------------------------------------------------------------------------
    // Write Ports — sync, all driven by WB / commit stage
    // -------------------------------------------------------------------------
    input  logic [NR_WRITE_PORTS-1:0][4:0]               waddr_i,
    input  logic [NR_WRITE_PORTS-1:0][DATA_WIDTH-1:0]    wdata_i,
    input  logic [NR_WRITE_PORTS-1:0]                    we_i     // write enables
);

    // -------------------------------------------------------------------------
    // Register Array
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [32];

    // -------------------------------------------------------------------------
    // Synchronous Write (with asynchronous reset)
    // Priority: highest write port index wins when two ports target same address.
    // x0 writes are always ignored regardless of port.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 1; i < 32; i++) begin
                mem[i] <= '0;
            end
        end else begin
            // Iterate ports in ascending order so the highest index port
            // overwrites lower ones on address collision (last-write wins)
            for (int p = 0; p < NR_WRITE_PORTS; p++) begin
                if (we_i[p] && (waddr_i[p] != '0)) begin
                    mem[waddr_i[p]] <= wdata_i[p];
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // x0 Hardwired to Zero
    // -------------------------------------------------------------------------
    assign mem[0] = '0;

    // -------------------------------------------------------------------------
    // Asynchronous (Combinational) Reads
    // -------------------------------------------------------------------------
    for (genvar rp = 0; rp < NR_READ_PORTS; rp++) begin : gen_read_ports
        assign rdata_o[rp] = mem[raddr_i[rp]];
    end

endmodule
