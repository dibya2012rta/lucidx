// =============================================================================
// LucidX Register File (Flip-Flop Based)
// -----------------------------------------------------------------------------
// 32 x 32-bit General Purpose Registers (x0 - x31)
// - 2 async read ports  (RS1, RS2) — data available same cycle as address
// - 1 sync  write port  (RD)       — data written on rising clock edge
// - x0 is hardwired to zero; writes to x0 are silently ignored
// - No internal forwarding; RAW hazards handled by pipeline forwarding unit
// =============================================================================

module lucidx_regfile #(
    parameter int unsigned DATA_WIDTH = 32   // register width (XLEN)
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,   // active-low asynchronous reset

    // -------------------------------------------------------------------------
    // Read Port A — RS1 (driven by ID stage)
    // -------------------------------------------------------------------------
    input  logic [4:0]            raddr_a_i,
    output logic [DATA_WIDTH-1:0] rdata_a_o,

    // -------------------------------------------------------------------------
    // Read Port B — RS2 (driven by ID stage)
    // -------------------------------------------------------------------------
    input  logic [4:0]            raddr_b_i,
    output logic [DATA_WIDTH-1:0] rdata_b_o,

    // -------------------------------------------------------------------------
    // Write Port — RD (driven by WB stage)
    // -------------------------------------------------------------------------
    input  logic [4:0]            waddr_i,
    input  logic [DATA_WIDTH-1:0] wdata_i,
    input  logic                  we_i      // write enable (active high)
);

    // -------------------------------------------------------------------------
    // Register Array
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [32];

    // -------------------------------------------------------------------------
    // Synchronous Write (with asynchronous reset)
    // x0 is excluded from the write path — its entry is never updated
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 1; i < 32; i++) begin
                mem[i] <= '0;
            end
        end else begin
            if (we_i && (waddr_i != '0)) begin
                mem[waddr_i] <= wdata_i;
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
    assign rdata_a_o = mem[raddr_a_i];
    assign rdata_b_o = mem[raddr_b_i];

endmodule
