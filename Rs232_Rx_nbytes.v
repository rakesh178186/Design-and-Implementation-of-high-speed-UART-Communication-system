`timescale 1ns / 1ps

module Rs232_Rx_nbytes(clk,reset,Rs232_Rxd,data_out);

// parameters//
  parameter n = 8; // No of bytes
  parameter N = 8; // No of bits 
  parameter mlb=0; // mlb=0 MSB first, mlb=1 LSB first
  parameter BAUD_RATE = 16'h28B0;   // Baud rate on which UART is working  /*(100000000/9600)=10416 == 16'h28B0*/
  
//Inputs//
  input clk;  // input clock
  input reset;// input reset
  input Rs232_Rxd;  // input serial rxd coming from txd

  output reg [(N*n)-1:0] data_out = 0; // output parallel data_out
  
// Define the internal registers of the module
  reg [15:0] clk_count = 0;          // clock count to match baud rate
  reg [N+1:0] shift_reg[n-1:0];      // shift register for received data
  reg start_bit ;                    // start bit for UART
  reg [3:0] state = 4'b0000;         // states defining
  reg [(N*n)-1:0] bit_counter=0 ;    // counter for received bits
  reg [n-1:0] byte_counter = n-1;    // byte_counter to keep track of how many bytes are sent
  reg [n-1:0] count;                 // count to get byte by byte data 
  
  // Define the clocked logic for the module
  always @(posedge clk) 
    begin
         if (reset == 1'b0)     // during reset is 0, reception doesn't take place
              begin 
                 state <= 4'b0000;           // state is 0 means IDLE
                 clk_count <= 0;             // clock count to match baud rate is 0
                 start_bit <= 1;             // start bit is low
                 if(mlb==0)                  // if MSB first 
                    begin
                      count <= n-1;          // Count to get byte by byte data 
                    end
                 else                       // if LSB first 
                    begin
                     count<=n;              // Count to get byte by byte data 
                 end
             end 
        else
             begin
               case (state)                // starting of case statements
          4'b0000: // IDLE state
              begin
                 if (start_bit== 1)        // start bit detected
                   begin
                     state <= 4'b0001;  // START state
                   end
                else 
                  begin
                     state <= 4'b0000;     // IDLE state
                  end
              end
              
        4'b0001: // START state
            begin
              if ((BAUD_RATE - 1) == clk_count) // if baud_rate and clk_count matches 
                 begin
                     state <=  4'b0010;     // RECEIVE state
                     clk_count <= 0;        //reset clk_count
                    if(mlb==0)             // mlb for selecting msb or lsb  to transfer first 
                        begin
                           bit_counter<=N+1;      // bit _counter to get msb
                        end
                    else begin
                         bit_counter<=0;          // bit _counter to get lsb
                    end
                 end 
             else
                 begin
                    state <=4'b0001;   // START state
                    clk_count <= clk_count + 1;
                 end
          end
          
         4'b0010:  // RECEIVE state
             begin
                 if ((BAUD_RATE - 1) == clk_count)                 //if baud_rate and clk_count matches 
                    begin
                      shift_reg[byte_counter][bit_counter] <= Rs232_Rxd; //  if mlb=0 receiving MSB of nth byte data else if mlb=1 receiving LSB of the nth byte
                        if(mlb==0)
                            begin
                             bit_counter <= bit_counter -1;        // if MSB first data_buffer is decremented 
                            end
                        else begin
                             bit_counter <= bit_counter +1;        // if MSB first data_buffer is  incremented
                        end
                         if(mlb==0)
                            begin
                      data_out[(count*N) +: N]<= shift_reg[byte_counter][9:2];  // first assigning nth byte of data by removing start and stop bit
                      end
                      else begin
                        data_out[(count*N-1) -: N]<= shift_reg[byte_counter][7:0];  // first assigning nth byte of data by removing start and stop bit
                      end
                        if (bit_counter ==0 &&mlb==0)begin         // received all bits of one byte
                            state <=  4'b0100; // REPEAT  state
                          end 
                          else if( bit_counter==N+1 && mlb==1) begin  // received all bits of one byte
                                state <=  4'b0100; // REPEAT  
                          end
                       else 
                         begin
                            state <=  4'b0010; // RECEIVE state
                         end
                      clk_count <= 0;
                    end
                 else 
                    begin
                      state <= 4'b0010; // RECEIVE state
                      clk_count <= clk_count + 1; 
                     end
           end
          
          4'b0100: // REPEAT state
                begin
                 if(byte_counter>=0) // until byte_counter becomes 0
                
                     begin
                        if((count >= 0&& count<=n-1) &&mlb==0)     // if count is greater than zero and less than max 
                             begin
                                  byte_counter <= byte_counter - 1;// byte_counter is decremented to get next byte
                                  bit_counter<=N+1;               // bit _counter to get msb
                                  count <= count-1;               // count is decremented to get next byte
                             end
                        else if((count >= 0&& count<=n) && mlb==1)
                             begin
                                  byte_counter <= byte_counter - 1;//byte_counter is decremented to get next byte
                                  bit_counter<=0;                  // bit _counter to get lsb
                                  count <= count-1;                // count is decremented to get next byte
                             end
                         clk_count <= 0;
                         state<=4'b0010; // RECEIVE state
                    end
                 else 
                     begin
                         byte_counter <= n-1; // Reset counter after transmitting all bytes
                         state <= 4'b1101;    // STOP state
                    end
              end
        
         4'b0011:  // STOP state
              begin
                 state <= 2'b0011; // STOP state
                 clk_count <= 0;// After transmitting all bytes of data reset clk_count to 0
             end
      endcase// end of the case statements
    end
  end
endmodule // End of the Design











