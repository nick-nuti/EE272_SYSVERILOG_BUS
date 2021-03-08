// This is a memory model for the perm_blk
//

module m55(input clk, input rst, input reg [2:0] rx,input reg [2:0] ry, output reg [63:0] rd,
    input reg [2:0] wx,input reg [2:0] wy, input reg wr, input reg [63:0] wd);
    
    reg [4:0][4:0][63:0] mdata;
    
    always @(*) begin
        rd<=#1 mdata[ry][rx];
    end
    always @(posedge(clk) or posedge(rst)) begin
        if(rst) begin
            mdata <= 64'hdeaddeaddeaddead;
        end else begin
            if(wr) begin
                mdata[wy][wx]<=#1 wd;
            end
        end
    end
endmodule : m55
