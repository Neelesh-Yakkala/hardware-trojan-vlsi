module uart_tx (
    input wire  clk,
    input wire  rst_n,
    input wire  tx_start,
    input wire [7:0] tx_data,
    output reg  tx,
    output reg  tx_busy
);
// Parameter
parameter CLK_FREQ = 50000000;
parameter BAUD_RATE = 9600;
parameter BAUD_DIV = CLK_FREQ / BAUD_RATE;

// Internal signals
reg [15:0] baud_counter;
reg [3:0] bit_counter;
reg [9:0] shift_reg;

//States
parameter IDLE = 2'b00;
parameter START = 2'b01;
parameter TRANSMIT = 2'b10;
parameter STOP = 2'b11;

reg [1:0] state;
// State machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= IDLE;
        tx          <= 1'b1;
        tx_busy     <= 1'b0;
        baud_counter <= 0;
        bit_counter  <= 0;
        shift_reg    <= 0;
    end else begin
        case (state)
            IDLE: begin
                tx      <= 1'b1;
                tx_busy <= 1'b0;
                if (tx_start) begin
                    shift_reg    <= {1'b1, tx_data, 1'b0};
                    state        <= START;
                    tx_busy      <= 1'b1;
                    baud_counter <= 0;
                end
            end

            START: begin
                tx <= 1'b0;
                if (baud_counter == BAUD_DIV - 1) begin
                    baud_counter <= 0;
                    bit_counter  <= 0;
                    state        <= TRANSMIT;
                end else begin
                    baud_counter <= baud_counter + 1;
                end
            end

            TRANSMIT: begin
                tx <= shift_reg[0];
                if (baud_counter == BAUD_DIV - 1) begin
                    baud_counter <= 0;
                    shift_reg    <= shift_reg >> 1;
                    if (bit_counter == 8) begin
                        state <= STOP;
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end else begin
                    baud_counter <= baud_counter + 1;
                end
            end

            STOP: begin
                tx <= 1'b1;
                if (baud_counter == BAUD_DIV - 1) begin
                    baud_counter <= 0;
                    state        <= IDLE;
                    tx_busy      <= 1'b0;
                end else begin
                    baud_counter <= baud_counter + 1;
                end
            end
        endcase
    end
end
endmodule
