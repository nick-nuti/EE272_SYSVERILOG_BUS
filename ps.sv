`include "slave.sv"
`include "fifo.sv"
`include "pri_rr_arb.sv"

module ps(NOCI.TI ti, NOCI.FO fo);

    logic clocky;
    assign clocky = fo.clk;
    logic resety;
    assign resety = fo.reset;

    // pushin - output
    // firstin - output
    // stopin - input
    // din - DONT CARE
    // pushout - input
    // firstout - input
    // stopout - output
    // dout - DONT CARE

    // ti.noc_to_dev_ctl
    reg tod_ctl_0;
    reg tod_ctl_1;
    reg tod_ctl_2;
    reg tod_ctl_3;
    // ti.noc_to_dev_ctl
    reg [7:0] tod_data_0;
    reg [7:0] tod_data_1;
    reg [7:0] tod_data_2;
    reg [7:0] tod_data_3;
    // ti.noc_to_dev_ctl
    logic frm_ctl_0;
    logic frm_ctl_1;
    logic frm_ctl_2;
    logic frm_ctl_3;
    // ti.noc_to_dev_ctl
    logic [7:0] frm_data_0;
    logic [7:0] frm_data_1;
    logic [7:0] frm_data_2;
    logic [7:0] frm_data_3;

    logic [1:0][7:0] fifo_in = 0;

    logic frm_ctl_0_two;
    logic frm_ctl_1_two;
    logic frm_ctl_2_two;
    logic frm_ctl_3_two;

    logic fctl = 1;
    logic [7:0] fdata = 0;

    logic [2:0] stm = 0;
    logic [2:0] stm_out = 0;

    logic [7:0] address_in = 0;

    logic [7:0] input_countupto = 0;
    logic [7:0] input_counter = 0;

    logic [2:0] command = 0;

    logic stupid_signal_0;   
    logic stupid_signal_1;   
    logic stupid_signal_2;   
    logic stupid_signal_3;    

    logic [7:0] fifo_out_0;
    logic [7:0] fifo_out_1;
    logic [7:0] fifo_out_2;
    logic [7:0] fifo_out_3;

    logic slave_0_fifo_write = 0;
    logic slave_1_fifo_write = 0;
    logic slave_2_fifo_write = 0;
    logic slave_3_fifo_write = 0;

    logic slave_0_fifo_read = 0;
    logic slave_1_fifo_read = 0;
    logic slave_2_fifo_read = 0;
    logic slave_3_fifo_read = 0;

    logic slave_0_fifo_check;
    logic slave_1_fifo_check;
    logic slave_2_fifo_check;
    logic slave_3_fifo_check;

    logic [1:0] s_out_count_0 = 0;
    logic [1:0] s_out_count_1 = 0;
    logic [1:0] s_out_count_2 = 0;
    logic [1:0] s_out_count_3 = 0;

    logic arb_lock = 0;

    logic slave_0_req = 0;
    logic slave_1_req = 0;
    logic slave_2_req = 0;
    logic slave_3_req = 0;
    logic [3:0] arb_requests;
    assign arb_requests[0] = slave_0_req;
    assign arb_requests[1] = slave_1_req;
    assign arb_requests[2] = slave_2_req;
    assign arb_requests[3] = slave_3_req;  

    logic slave_0_gnt;
    logic slave_1_gnt;
    logic slave_2_gnt;
    logic slave_3_gnt;
    logic [3:0] arb_grants;
    assign slave_0_gnt = arb_grants[0];
    assign slave_1_gnt = arb_grants[1];
    assign slave_2_gnt = arb_grants[2];
    assign slave_3_gnt = arb_grants[3]; 

    logic [2:0] out_cmd = 0;
    logic [2:0] out_intermittent_counter = 0;
    logic [7:0] out_countupto = 0;
    logic [7:0] out_counter = 0;

    slave s0(clocky,resety,tod_ctl_0,tod_data_0,frm_ctl_0,frm_ctl_0_two,stupid_signal_0,frm_data_0);
    slave s1(clocky,resety,tod_ctl_1,tod_data_1,frm_ctl_1,frm_ctl_1_two,stupid_signal_1,frm_data_1);
    slave s2(clocky,resety,tod_ctl_2,tod_data_2,frm_ctl_2,frm_ctl_2_two,stupid_signal_2,frm_data_2);
    slave s3(clocky,resety,tod_ctl_3,tod_data_3,frm_ctl_3,frm_ctl_3_two,stupid_signal_3,frm_data_3);

    fifo ss0(clocky, resety, slave_0_fifo_write, slave_0_fifo_read, frm_data_0, fifo_out_0);
    fifo ss1(clocky, resety, slave_1_fifo_write, slave_1_fifo_read, frm_data_1, fifo_out_1);
    fifo ss2(clocky, resety, slave_2_fifo_write, slave_2_fifo_read, frm_data_2, fifo_out_2);
    fifo ss3(clocky, resety, slave_3_fifo_write, slave_3_fifo_read, frm_data_3, fifo_out_3);

    arb arb0(clocky, resety, arb_lock, arb_requests, arb_grants);

    always@(posedge clocky)
    begin

		if(resety == 1)
		begin
			tod_ctl_0 = 0;
			tod_data_0 = 8'd0;
			tod_ctl_1 = 0;
			tod_data_1 = 8'd0;
			stm = 0;
		end

		case(stm)
			0:
			begin

				if((ti.noc_to_dev_ctl == 1)&&(ti.noc_to_dev_data != 0))
				begin
					fifo_in[0] = ti.noc_to_dev_data;
					
					if(fifo_in[0][2:0] == 3'b010)
					begin			
						input_countupto = (2**fifo_in[0][5:3])+(2**fifo_in[0][7:6])+1;
						command = 3'b010;
					end

					if(fifo_in[0][2:0] == 3'b001)
					begin
						input_countupto = (2**fifo_in[0][7:6])+2;
						command = 3'b001;
					end
					stm = 1;
				end
			end

			1:
			begin
				fifo_in[1] = fifo_in[0];
				fifo_in[0] = ti.noc_to_dev_data;
				address_in = fifo_in[0][7:0];

				case(address_in)
				64:
				begin
					tod_ctl_0 = 1;
					tod_data_0 = fifo_in[1];
				end
				65:
				begin
					tod_ctl_1 = 1;
					tod_data_1 = fifo_in[1];
				end
				66:
				begin
					tod_ctl_2 = 1;
					tod_data_2 = fifo_in[1];
				end
				67:
				begin
					tod_ctl_3 = 1;
					tod_data_3 = fifo_in[1];
				end
				endcase

				stm = 2;
			end
			
			2:
			begin
				fifo_in[1] = fifo_in[0];
				fifo_in[0] = ti.noc_to_dev_data;

				case(address_in)
				64:
				begin
					tod_ctl_0 = 0;
					tod_data_0 = fifo_in[1];		
				end
				65:
				begin
					tod_ctl_1 = 0;
					tod_data_1 = fifo_in[1];
				end
				66:
				begin
					tod_ctl_2 = 0;
					tod_data_2 = fifo_in[1];
				end
				67:
				begin
					tod_ctl_3 = 0;
					tod_data_3 = fifo_in[1];
				end
				endcase
				
				if(input_counter < input_countupto)
				begin		
					input_counter = input_counter + 1;
					stm = 2;
				end

				else 
				begin	
					input_counter = 0;
					
					if(command == 3'b001)
					begin
					
						if(address_in == 64)tod_ctl_0 = 1;
						if(address_in == 65)tod_ctl_1 = 1;
						if(address_in == 66)tod_ctl_2 = 1;
						if(address_in == 67)tod_ctl_3 = 1;
					end

					if((ti.noc_to_dev_ctl == 1)&&(ti.noc_to_dev_data != 0))
					begin
						fifo_in[0] = ti.noc_to_dev_data;
						
						if(fifo_in[0][2:0] == 3'b010)
						begin			
							input_countupto = (2**fifo_in[0][5:3])+(2**fifo_in[0][7:6])+1;
							command = 3'b010;
						end

						if(fifo_in[0][2:0] == 3'b001)
						begin
							input_countupto = (2**fifo_in[0][7:6])+2;
							command = 3'b001;
						end

						stm = 1;
					end
					
					else stm = 0;
				end
			end
		endcase
    end

    always@(*)
    begin
		if((stupid_signal_0 == 1)&&(resety == 0))
		begin
			slave_0_fifo_write = 1;
			slave_0_req = 1;
		end

		if(((frm_ctl_0 == 1)&&(stupid_signal_0 == 0))&&(resety == 0))
		begin
			slave_0_fifo_write = 0;
		end

		if(slave_0_gnt == 1) slave_0_req = 0;
    end

    always@(*)
    begin
		if((stupid_signal_1 == 1)&&(resety == 0))
		begin
			slave_1_fifo_write = 1;
			slave_1_req = 1;
		end

		if(((frm_ctl_1 == 1)&&(stupid_signal_1 == 0))&&(resety == 0))
		begin
			slave_1_fifo_write = 0;
		end

		if(slave_1_gnt == 1) slave_1_req = 0;
    end

    always@(*)
    begin
		if((stupid_signal_2 == 1)&&(resety == 0))
		begin
			slave_2_fifo_write = 1;
			slave_2_req = 1;
		end

		if(((frm_ctl_2 == 1)&&(stupid_signal_2 == 0))&&(resety == 0))
		begin
			slave_2_fifo_write = 0;
		end

		if(slave_2_gnt == 1) slave_2_req = 0;
    end

    always@(*)
    begin
		if((stupid_signal_3 == 1)&&(resety == 0))
		begin
			slave_3_fifo_write = 1;
			slave_3_req = 1;
		end

		if(((frm_ctl_3 == 1)&&(stupid_signal_3 == 0))&&(resety == 0))
		begin
			slave_3_fifo_write = 0;
		end

		if(slave_3_gnt == 1) slave_3_req = 0;
    end

    always@(posedge clocky)
    begin

		if(resety == 1)
		begin
			fo.noc_from_dev_ctl = 1;
			stm_out = 0;
			out_cmd = 3'b000;
			fo.noc_from_dev_data = 0;
			
		end

		case(stm_out)
			0: // deal with response command
			begin
				fo.noc_from_dev_ctl = 1;
				fo.noc_from_dev_data = 0;

				if(arb_grants != 0)
				begin
					arb_lock = 1;

					case(arb_grants)
						4'b0001:
						begin
							fo.noc_from_dev_data = #1 fifo_out_0;
							slave_0_fifo_read = 1;
							out_cmd = fifo_out_0 [2:0];
						end
						
						4'b0010:
						begin
							fo.noc_from_dev_data = #1 fifo_out_1;
							slave_1_fifo_read = 1;
							out_cmd = fifo_out_1 [2:0];
						end
						
						4'b0100:
						begin
							fo.noc_from_dev_data = #1 fifo_out_2;
							slave_2_fifo_read = 1;
							out_cmd = fifo_out_2 [2:0];
						end
						
						4'b1000:
						begin
							fo.noc_from_dev_data = #1 fifo_out_3;
							//fo.noc_from_dev_data = fifo_out_3;
							slave_3_fifo_read = 1;
							out_cmd = fifo_out_3 [2:0];
						end			
					endcase	

					out_intermittent_counter = 0;
					
					stm_out = 1;
				end

				else
				begin
					slave_0_fifo_read = 0;
					slave_1_fifo_read = 0;
					slave_2_fifo_read = 0;
					slave_3_fifo_read = 0;		
				end
			end

			1: // to deal with setting frm ctl low, and destination id then source id
			begin
			
				if(out_intermittent_counter == 1) fo.noc_from_dev_ctl = 0;

				case(arb_grants)
					4'b0001:
					begin
						if(out_intermittent_counter > 0) fo.noc_from_dev_data = fifo_out_0;
					end
					
					4'b0010:
					begin
						if(out_intermittent_counter > 0) fo.noc_from_dev_data = fifo_out_1;
					end
					
					4'b0100:
					begin
						if(out_intermittent_counter > 0) fo.noc_from_dev_data = fifo_out_2;
					end
					
					4'b1000:
					begin
						if(out_intermittent_counter > 0) fo.noc_from_dev_data = fifo_out_3;
					end			
				endcase	
				
				if(out_intermittent_counter < 3)
				begin
					out_intermittent_counter = out_intermittent_counter + 1;			
					stm_out = 1;
				end

				else 
				begin
					if(out_cmd == 3'b011) out_countupto = fo.noc_from_dev_data;
					stm_out = 2;
				end
			end
			
			2:
			begin
			
				case(arb_grants)
				
					4'b0001:
					begin
						fo.noc_from_dev_data = fifo_out_0;
						
						if(out_cmd == 3'b100) slave_0_fifo_read = 0;
					end
					4'b0010:
					begin
						fo.noc_from_dev_data = fifo_out_1;
						
						if(out_cmd == 3'b100) slave_1_fifo_read = 0;
					end
					4'b0100:
					begin
						fo.noc_from_dev_data = fifo_out_2;
						
						if(out_cmd == 3'b100) slave_2_fifo_read = 0;
					end
					4'b1000:
					begin
						fo.noc_from_dev_data = fifo_out_3;
						
						if(out_cmd == 3'b100) slave_3_fifo_read = 0;
					end			
				endcase	
				
				if(out_cmd == 3'b101)
				begin
					slave_0_fifo_read = 0;
					slave_1_fifo_read = 0;
					slave_2_fifo_read = 0;
					slave_3_fifo_read = 0;	
					out_countupto = 0;
				end	

				if(out_cmd == 3'b100)
				begin
					fo.noc_from_dev_ctl = 1;
					fo.noc_from_dev_data = 0;
					slave_0_fifo_read = 0;
					slave_1_fifo_read = 0;
					slave_2_fifo_read = 0;
					slave_3_fifo_read = 0;		
					stm_out = 0;
					arb_lock = 0;	
				end

				else
				begin
					out_counter = 0;
					stm_out = 3;
				end
			end

			3:
			begin
			
				case(arb_grants)
					4'b0001:
					begin
						fo.noc_from_dev_data = fifo_out_0;	
					end
					4'b0010:
					begin
						fo.noc_from_dev_data = fifo_out_1;
					end
					4'b0100:
					begin
						fo.noc_from_dev_data = fifo_out_2;
					end
					4'b1000:
					begin
						fo.noc_from_dev_data = fifo_out_3;
					end			
				endcase	

				if(out_cmd == 3'b011)
				begin
				
					if(out_counter == (out_countupto-1))
					begin
						slave_0_fifo_read = 0;
						slave_1_fifo_read = 0;
						slave_2_fifo_read = 0;
						slave_3_fifo_read = 0;			

						fo.noc_from_dev_ctl = 1;
						fo.noc_from_dev_data = 0;
					end
				end

				if(out_counter < out_countupto)
				begin
					out_counter = out_counter + 1;
					stm_out = 3;
				end
			
				else
				begin
					slave_0_fifo_read = 0;
					slave_1_fifo_read = 0;
					slave_2_fifo_read = 0;
					slave_3_fifo_read = 0;			

					fo.noc_from_dev_ctl = 1;
					fo.noc_from_dev_data = 0;
					stm_out = 0;	

					arb_lock = 0;		
				end
			end
		endcase
    end

endmodule


