`include "nochw2.sv"
`include "perm.sv"
`include "m55.sv"

module slave(input clk, input reset, input tod_ctl, input [7:0] tod_data, output frm_ctl, output frm_ctl_two, output stupid_signal, output [7:0] frm_data);

    reg pushin,stopin,firstin,firstout,firstoutH;
    reg [63:0] din;
    reg [5:0] dix;    // data index for 1600 bits
    reg [2:0] m1ax,m1ay,m1wx,m1wy,m2ax,m2ay,m2wx,m2wy,m3ax,m3ay,m3wx,m3wy,m4ax,m4ay,m4wx,m4wy;
    reg m1wr,m2wr,m3wr,m4wr;
    reg [63:0] m1rd,m1wd,m2rd,m2wd,m3rd,m3wd,m4rd,m4wd;
    reg errpos=0;

    wire pushout;
    reg stopout;
    reg pushoutH;
    wire [63:0] dout;
    reg [63:0] doutH;

    perm_blk p(clk,reset,pushin,stopin,firstin,din,
                m1ax,m1ay,m1rd,m1wx,m1wy,m1wr,m1wd,
                m2ax,m2ay,m2rd,m2wx,m2wy,m2wr,m2wd,
                m3ax,m3ay,m3rd,m3wx,m3wy,m3wr,m3wd,
                m4ax,m4ay,m4rd,m4wx,m4wy,m4wr,m4wd,
                pushout,stopout,firstout,dout);

    m55 m1(clk,reset,m1ax,m1ay,m1rd,m1wx,m1wy,m1wr,m1wd);
    m55 m2(clk,reset,m2ax,m2ay,m2rd,m2wx,m2wy,m2wr,m2wd);
    m55 m3(clk,reset,m3ax,m3ay,m3rd,m3wx,m3wy,m3wr,m3wd);
    m55 m4(clk,reset,m4ax,m4ay,m4rd,m4wx,m4wy,m4wr,m4wd);

    

    noc_intf n(clk,reset,tod_ctl,tod_data,stupid_signal,frm_ctl,frm_ctl_two,frm_data,pushin,firstin,stopin,din,pushout,firstout,stopout,dout);
	//noc_intf n(fo.clk,fo.reset,ti.noc_to_dev_ctl,ti.noc_to_dev_data,fo.noc_from_dev_ctl,fo.noc_from_dev_data,pushin,firstin,stopin,din,pushout,firstout,stopout,dout);

endmodule

