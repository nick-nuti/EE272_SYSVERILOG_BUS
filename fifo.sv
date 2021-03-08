
module fifo(clk,rst,w_pin,r_pin,din,dout);

input clk;
input rst;
input w_pin;
input r_pin;
input [7:0] din;

output [7:0] dout;

logic full;
logic empty;

logic write;
logic read; 

logic [4:0] next_write;
logic [4:0] next_read;
logic [4:0] memory_write;
logic [4:0] memory_read; 

fifo_mem m (clk,write,memory_write,memory_read,din,dout);

always @ (posedge clk or posedge rst)
begin

  if(rst == 1) 
  begin
    memory_write <= 0;
  end 

  else 
  begin
    memory_write <= #1 next_write;
  end

end

always @ (posedge clk or posedge rst)
begin

  if(rst) 
  begin
    memory_read <= 0;
  end 

  else 
  begin
    memory_read <= #1 next_read;
  end

end

always@(*)
begin
  	
  if((memory_write + 1) == memory_read) full = 1;
  else full = 0; 

  if(memory_write == memory_read) empty = 1;
  else empty = 0; 

  write = w_pin & !full;
  read  = r_pin & !empty;

  if(write) next_write = memory_write + 1; 
  else next_write = memory_write;

  if(read) next_read = memory_read + 1; 
  else next_read = memory_read;

end

endmodule


module fifo_mem(clk,write,memory_write,memory_read,din,dout);

input clk;
input write;
input [4:0] memory_write;
input [7:0] din;
input [4:0] memory_read;
output reg [7:0] dout;

logic [7:0] mem[0:31];

always @(posedge(clk))
begin

  if(write) 
  begin
    mem[memory_write] <= din;
  end

end

always @(*) 
begin

  dout <= mem[memory_read];

end

endmodule



