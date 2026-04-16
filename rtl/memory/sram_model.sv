// Synchronous SRAM Model with Bit-Wise Select (SystemVerilog)
// Port Descriptions:
// A - Address input
// D - Data input
// Q - Data output (synchronous)
// CLK - Clock input
// SRAM_ENZ - SRAM Enable (active low)
// SRAM_WRNZ - Write Enable (active low)
// SRAM_BIT_WISE_SELECTZ - Bit-wise select (active low, per bit)

module sram_model #(
    parameter int DATA_WIDTH = 16,           // Width of data bus
    parameter int ADDR_WIDTH = 10,          // Width of address bus
    parameter int DEPTH = 1024              // Memory depth (2^ADDR_WIDTH)
) (
    input  logic [ADDR_WIDTH-1:0]     A,                          // Address bus
    input  logic [DATA_WIDTH-1:0]     D,                          // Data input
    output logic [DATA_WIDTH-1:0]     Q,                          // Data output (synchronous)
    input  logic                      CLK,                        // Clock
    input  logic                      SRAM_ENZ,                   // SRAM Enable (active low)
    input  logic                      SRAM_WRNZ,                  // Write Enable (active low)
    input  logic [DATA_WIDTH-1:0]     SRAM_BIT_WISE_SELECTZ       // Bit-wise Select (active low)
);

    // Memory array
    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Internal signals
    logic write_enable;
    logic read_enable;

    // Decode control signals (active low logic)
    assign write_enable = ~SRAM_ENZ & ~SRAM_WRNZ;
    assign read_enable = ~SRAM_ENZ & SRAM_WRNZ;

    // Synchronous read and write operations on clock edge
    always_ff @(posedge CLK) begin
        if (write_enable) begin
            // Synchronous write: write only to selected bits (active low select)
            for (int i = 0; i < DATA_WIDTH; i++) begin
                if (~SRAM_BIT_WISE_SELECTZ[i]) begin
                    mem[A][i] <= D[i];
                end
            end
            // Q reflects actual written result: selected bits from D, unselected bits from mem
            Q <= (D & ~SRAM_BIT_WISE_SELECTZ) | (mem[A] & SRAM_BIT_WISE_SELECTZ);
        end else if (read_enable) begin
            // Synchronous read: output memory data on Q
            Q <= mem[A];
        end
    end

    // Optional: Initialize memory from file (uncomment if needed)
    // initial begin
    //     $readmemh("memory.hex", mem);
    // end

endmodule

// -----------------------------------------------------------------------------
// Instantiation Template:
//
// sram_model #(
//     .DATA_WIDTH (16  ),
//     .ADDR_WIDTH (10  ),
//     .DEPTH      (1024)
// ) u_sram_model (
//     .A                    (A                   ),  // input  [ADDR_WIDTH-1:0]
//     .D                    (D                   ),  // input  [DATA_WIDTH-1:0]
//     .Q                    (Q                   ),  // output [DATA_WIDTH-1:0]
//     .CLK                  (CLK                 ),  // input
//     .SRAM_ENZ             (SRAM_ENZ            ),  // input
//     .SRAM_WRNZ            (SRAM_WRNZ           ),  // input
//     .SRAM_BIT_WISE_SELECTZ(SRAM_BIT_WISE_SELECTZ)  // input  [DATA_WIDTH-1:0]
// );
// -----------------------------------------------------------------------------
