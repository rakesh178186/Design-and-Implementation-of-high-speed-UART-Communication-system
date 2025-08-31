`timescale 1ns / 1ps

module Rs232_Tx_nbytes(clk,reset,tx_start_flag,data_in,tx_done_flag,Rs232_Txd);

  // Parameters
  parameter n = 8; // No of bytes
  parameter N = 8; // No of bits
  parameter mlb = 0; // mlb=0 MSB first, mlb=1 LSB first
  parameter BAUD_RATE = 16'h28B0; // Baud rate on which UART is working


  input clk;
  input reset;
  input [(N*n)-1:0] data_in;
  output reg tx_start_flag = 1'b0;
  output reg tx_done_flag = 1'b0;
  output wire Rs232_Txd;

  // Internal signals
  reg [15:0] clk_count = 0; // Clk_count to match baud rate
  reg [N-1:0] data_buffer = (n*N) - N; // Data buffer to send bit by bit
  reg [N-1:0] data[n-1:0]; // Array to store n bytes of data
  reg start = 1'b1; // To indicate start bit
  reg [3:0] state = 4'b0000; // No of states
  reg tx_data; // To store tx data
  reg [n-1:0] byte_counter = n-1; // To track index of data bytes
  reg [n-1:0] count; // To assign data_in into data by using count index

  always @(posedge clk) begin
    if (reset == 1'b0)
      begin
        tx_data <= 1'b1; // Initial tx_data
        state <= 4'b0000; // Initial IDLE state
        clk_count <= 0; // clk_count is 0
        start <= 1'b1; // start bit is 1
        count <= n-1; // Initial count is n-1 to send nth data
        tx_start_flag <= 1'b0;
        tx_done_flag <= 1'b0;
      end
    else
      begin
        case(state)
          4'b0000: // IDLE state
            begin
              if (start)
                begin
                  state <= 4'b0001; // START state
                  // Toggle tx_start_flag on every byte transmission start
                  data[count] <= data_in[(count*N) +: N]; // Assign data_in to data for transmission
                  if (count >= 0)
                    begin
                      count <= count-1; // Until count becomes 0 decrementing count
                    end
                end
              else
                begin
                  state <= 4'b0000; // IDLE state
                end
            end
          4'b0001: // START state
            begin
              start <= 1'b0; // Start is 0
              tx_data <= 0; // Start bit
               tx_start_flag <= 1'b1;
              if ((BAUD_RATE - 1) == clk_count) // If baud_rate and clk_count matches
                begin
                  state <= 4'b0010; // TRANSMIT state
                  clk_count <= 0;
                  if (mlb == 0) // mlb for selecting msb or lsb to transfer first
                    begin
                      data_buffer <= N-1; // bit_counter to get msb
                    end
                  else
                    begin
                      data_buffer <= 0; // bit_counter to get lsb
                    end
                end
              else
                begin
                  state <= 4'b0001; // START state
                  clk_count <= clk_count + 1; // If baud_rate is not matches with clk_count increment until it matches
                end
            end

          4'b0010: // TRANSMIT state
            begin
              tx_start_flag <= 1'b0;
              tx_data <= data[byte_counter][data_buffer]; // if mlb=0 sending MSB of nth byte data else if mlb=1 sending LSB of the nth byte
              if ((BAUD_RATE - 1) == clk_count) // if baud_rate and clk_count matches
                begin
                  if (mlb == 0)
                    begin
                      data_buffer <= data_buffer-1; // if MSB first data_buffer is decremented
                    end
                  else
                    begin
                      data_buffer <= data_buffer + 1; // if LSB first data_buffer is incremented
                    end
                  if (data_buffer == 0 && mlb == 0) // if data_buffer reaches to min length of data_in
                    begin
                      state <= 4'b0011; // state goes to stop
                    end
                  else if (data_buffer == N-1 && mlb == 1) // if data_buffer reaches to maxlength of data_in
                    begin
                      state <= 4'b0011; // state goes to stop
                    end
                  else
                    begin
                      state <= 4'b0010; // else state will remain in transmit
                    end
                  clk_count <= 0;
                end
              else
                begin
                  state <= 4'b0010; // TRANSMIT state // if baud_rate and clk_count not matches
                  clk_count <= clk_count + 1; // Increment clk_count until it matches with baud_rate
                end
            end

          4'b0011: // STOP state
            begin
              tx_start_flag <= 0;
              tx_data <= 1'b1; // Stop bit
              if ((BAUD_RATE - 1) == clk_count) // if baud_rate and clk_count matches
                begin
                  state <= 4'b0100; // REPEAT state for sending next byte of data
                  clk_count <= 0;
                  end
              else
                begin
                  state <= 4'b0011; // STOP state
                  clk_count <= clk_count + 1;
                end
            end

          4'b0100: // REPEAT state
            begin
              state <= 4'b0000; // IDLE state
              clk_count <= 0;
              start <= 1'b1; // Generate start bit for next byte
              byte_counter <= byte_counter - 1; // Move to next byte
              if (byte_counter == 0)
                begin
                  byte_counter <= n-1; // Reset counter after transmitting all bytes
                  state <= 4'b1101;
                end
            end

          4'b1101: // END state
            begin
            tx_done_flag <= 1'b1;
              clk_count <= 0; // After transmitting all bytes of data reset clk_count to 0
            end

          default:
            begin
              state <= 4'b1101; // Default state
            end
        endcase // end of the case statements
      end
  end

  assign Rs232_Txd = tx_data; // Assigning tx_data to output Rs232_Txd
endmodule // End of the Design
