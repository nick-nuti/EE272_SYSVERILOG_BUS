// 1. uni-directional inteface: carries data to device (from master) interface of 8 data bits, and a control bit
// 2. carries data from device (to the master) on a 9 bit interface
// multi-cycle packets; first byte of packet has the control bit high, control bit on all other data is low

// devices have 8 bit ID; ID = 0 and ID = 0xFF are reserved; 254 devices allowed

// packets are of variable length
    // all start with a common command contained in the low order 3 bits of the first byte (indicated by high control bit)
    // 7 6 5 4 3 2 1 0
    //----------|------
    //varies      command

module noc_intf(
    input clk,
    input reset,

    input tod_ctl,          // to device control
    input [7:0] tod_data,   // to device data

    output reg stupid_signal,
    output reg frm_ctl,         // indicates the command byte of device to test bench
    output reg from_ctl_two,
    output reg [7:0] frm_data,  //  noc data from device to test bench

    output reg pushin,  // push to perm_blk
    output reg firstin, // indicates first data of a set to perm_blk
    input stopin, // a stop on the perm_blk interface

    output reg [63:0] din, // data to perm_blk

    input pushout,  // push signal from perm_blk
    input firstout, // indicates first 8 byte data from perm_blk

    output stopout, //stops perm_blk output until a read is happening in noc_intf

    input [63:0] dout   // data from perm_blk to noc
    );

    reg stopout = 0;

    //logic in_message_started = 0;
    logic [1:0] in_alen;  // 2^(in_alen) = (1,2,4,8) -> in_alen = 0,1,2,3
    logic [2:0] in_dlen;  // 2^(in_dlen) = (1,2,4,8,16,32,64,128) -> in_dlen = 0,1,2,3,4,5,6,7
    logic [7:0] in_dest_id;   // destination id
    logic [7:0] last_dest_id;
    logic [7:0] in_source_id;   // source id
    logic [1:0] in_message_started = 0; // keeping track of whether it was a read or a write
    logic [2:0] in_message_rsp; // need this for the response message
    logic [63:0] in_address = 0; // addr
    logic [7:0] write_counter;
    
    logic [1599:0] read_buff;
    logic [1599:0] justincase_buff;
    logic [5:0] readin_counter = 0;
    logic [10:0] readin_byte_counter = 0;
    logic [7:0] readout_counter = 0;
    logic [10:0] readout_counter_full = 0;
    logic read_time = 0;
    logic [10:0] readin_byte_buff = 0;
    logic stupid_flag = 0;

    logic [1:0] frm_ctl_counter = 0;
    logic [7:0] write_resp_counter;
    logic start_mesg = 0;
    logic mesg_rsn = 0;
    logic [2:0] resp_counter = 0;
    logic [1:0] resp_code;
    logic [7:0] counter_data_length = 0;
    logic [7:0] read_resp_dest_id_buffer;

    logic [1:0] in_counter = 0; // counter for destination and source ID message gathering
    logic [3:0] in_counter_1 = 0; // counter for getting address messages
    logic [10:0] in_counter_2 = 0; // counter for getting write data messages (if it's a write)

    logic out_message_started = 0;
    logic [7:0] output_master_id;
    logic [7:0] output_device_id;

    logic stopin_d = 0;
    logic reset_d = 0;

    //assign stopin_d = stopin;

    int county;

    //reg from_ctl_two = 0;
    reg [7:0] error_reason;

    always@(posedge clk) // to device
    begin
        if(reset == 1)
        begin
            in_address <= 0;
            in_counter <= 0;
            in_counter_1 <= 0;
            in_counter_2 <= 0;
            pushin <= 0;
            firstin <= 0;
            in_message_started <= 0;
            
            //frm_ctl <= 0;
            //start_mesg <= 0;
            in_message_rsp <= 0;
            //resp_counter <= 0;
            frm_ctl_counter <= 0;

			in_address <= 0;
		
			from_ctl_two <= 0;

			error_reason <= 8'h00;
        end

		//else frm_ctl <= 1;

	if(stopin == 0) stopin_d <= stopin;
	else stopin_d <= 1;

        if(from_ctl_two == 1)
        begin
            frm_ctl_counter <= frm_ctl_counter + 1;
            if(frm_ctl_counter == 1) 
            begin
                from_ctl_two <= 0;
                frm_ctl_counter <= 0;
            end
        end

	if(pushin == 1) pushin <= #1 0;

        if((pushout == 1)&&(firstout == 1))
        begin
            from_ctl_two <= 1;
            //start_mesg <= 1;
	    mesg_rsn <= 0;
            in_message_rsp <= 5;
            stopout <= 1;
			county <= county + 1;
			$display("county=%0d",county);
			$display($time);
        end

		//if((readout_counter_full == 200)&&(in_message_rsp == 3))
        if((stopin_d == 1) && (stopin == 0))
	begin
		//$display("stopin went low....");
		from_ctl_two <= 1;
		//start_mesg <= 1;
		mesg_rsn <= 1;
		in_message_rsp <= 5;
		stopout <= 0;
	end

        else
        begin
		    firstin <= #1 0;
	    	//pushin <= #1 0; // in hw1, perm_blk always had pushin high except for during reset
            //if((tod_ctl) == 1 && (in_message_started == 0))
            #1 if(tod_ctl == 1)
            begin
                in_address <= 0;
                in_counter <= 0;
                in_counter_1 <= 0;
                write_counter <= 0;
                pushin <= 0;
				error_reason <= 8'h00;
                //frm_ctl <= #1 0;

                case(tod_data[2:0])
                0: // NOP
                    begin
                        in_message_started <= 0;
						//$display("idle");
                    end
                1: // READ
                    begin

						in_alen <= tod_data[7:6];
                        in_dlen <= tod_data[5:3];

                        if(pushout == 1)
                        begin
							resp_code <= 0;
                            in_message_started <= 1;
                        end

                        else // if pushout is 0 send an error ************************************************
						begin
							//$display("pushout = 0 error");
							resp_code <= 1;
							error_reason <= 8'h01;
						end
                    end
                2: // WRITE
                    begin

						in_alen <= tod_data[7:6];
									in_dlen <= tod_data[5:3];
						in_message_started <= 2;
						stopout <= 0;

                        if(stopin == 0)
                        begin
                            resp_code <= 0;
							//$display("write length = %d", 2**(tod_data[5:3]));
                        end

                        else // if stopin is 1 send an error ************************************************
						begin
							//$display("stopin = 1 error");
							resp_code <= 1;
							error_reason <= 8'h02;
						end
                    end
                default:
                    begin
                        in_message_started <= 0;
                    end
                endcase
            end

            if((tod_ctl) == 0 && (in_message_started > 0))
            begin
				//frm_ctl_counter <= 0;

				if(readin_byte_counter == (2**in_dlen)+8)stopout <= 1;
				else stopout <= 0;


                if(in_counter < 2) // to get destination ID and source ID
                begin
                    in_counter <= in_counter + 1;
                    if(in_counter == 0) in_dest_id <= tod_data;
                    else if(in_counter == 1) in_source_id <= tod_data;
		    
					if(readin_byte_counter == (2**in_dlen)+8)stopout <= 1;
					else stopout <= 0;
				end

                //else if(in_counter_1 < (in_alen + 1)) // addr
		        else if(in_counter_1 < (2**in_alen)) // addr
                begin
                    in_counter_1 <= in_counter_1 + 1;

					case(in_counter_1)
					0: in_address[7:0] <= tod_data;
					1: in_address[15:8] <= tod_data;
					2: in_address[23:16] <= tod_data;
					3: in_address[31:24] <= tod_data;
					4: in_address[39:32] <= tod_data;
					5: in_address[47:40] <= tod_data;
					6: in_address[55:48] <= tod_data;
					7: in_address[63:56] <= tod_data;
					endcase
				
					if(tod_data != 0) //if the address is not zero
					begin
						//$display("address error");
						resp_code <= 1;
						error_reason <= 8'h03;
					end

					if(readin_byte_counter == (2**in_dlen)+8)stopout <= 1;
					else stopout <= 0;

					if((in_counter_1 == ((2**in_alen)-1))&&(in_message_started == 1)) // read is initiated here, we ctl bit goes high very fast so we need to do it here
					begin
                        //resp_code <= 0;
						//frm_ctl <= 1;
                        //start_mesg <= 1;
                        in_message_rsp <= 3;
                        
						//stopout <= 0;
					end
                end

				else if(in_message_started == 2)
                begin
                    if(stopin == 0)
                    begin
                        
                        firstin <= 0;

                        case(in_counter_2 % 8)
                        0: 
                        begin
                            din[7:0] <= tod_data;
                            pushin <= 0;
                        end
                        1: din[15:8] <= tod_data;
                        2: din[23:16] <= tod_data;
                        3: din[31:24] <= tod_data;
                        4: din[39:32] <= tod_data;
                        5: din[47:40] <= tod_data;
                        6: din[55:48] <= tod_data;
                        7: 
                        begin 
                            din[63:56] <= tod_data;

                            if(in_counter_2 == 7) firstin <= 1;
                            
                            pushin <= 1;
                        end
                        endcase

                        if(write_counter == ((2**in_dlen)-1)) // if you've finished writing the write messages to din buffer
                        begin
                            // send write response -> here we check recieved length of data with dlen
                            from_ctl_two <= 1;
							//start_mesg <= 1;
                            in_message_rsp <= 4;
                            //resp_code <= 0; // write ok -> this is set initially
                            //write_resp_counter <= in_dlen;
							write_resp_counter <= write_counter + 1;
                            //
                            write_counter <= 0;
                            in_message_started <= 0;
                        end

                        else
                        begin
                            write_counter <= write_counter + 1;
                        end

                        if(in_counter_2 == (200 - 1)) // if you've reached the 200 byte limit, restart the counter
                        begin
                            in_counter_2 <= 0;
                            in_message_started <= 0;
			    

                            if(write_counter < (2**in_dlen)-1) // if 200 byte limit reached but write_counter wasn't finished... then send out a short write
                            begin
								//$display("shortwrite");
                                // need to setup messages -> short write
                                from_ctl_two <= 1;
								//start_mesg <= 1;
                                if(resp_code == 0) resp_code <= 2; // partial write!
                                in_message_rsp <= 4;
                                write_resp_counter <= write_counter + 1; 
                            end

                            write_counter <= 0;
                        end

						else 
						begin
							in_counter_2 <= in_counter_2 + 1;
							//$display("write counter = %d", in_counter_2);
						end
                    end
                end
            end

            if((readin_byte_counter == (2**in_dlen)+8)&&(in_message_rsp == 3))
            begin
                stopout <= 1;
                resp_code <= 0;
				from_ctl_two <= 1;
                //start_mesg <= 1;
				readin_byte_buff <= readin_byte_counter-8;
            end
        end
    end

    //for taking a read command and handling it in parallel

    always@(posedge clk)
    begin
        if(reset == 1)
        begin
            readin_counter <= 0;
            readin_byte_counter <= 8;
        end

        //if(pushout == 0)
        //begin
        //    readin_counter <= 0;
        //    readin_byte_counter <= 8;
        //end

		//if(readin_byte_counter >= (2**in_dlen)) 
		//begin
			//readin_counter <= 0;
		//	readin_byte_counter <= 0;
		//end

		if((stupid_flag == 1)&&(tod_ctl == 1)) 
		begin
			readin_byte_counter <= 8;
			readin_counter <= 0;
		end

        else if((stopout == 0)&&(pushout == 1))
        begin

            readin_counter <= readin_counter + 1;
            readin_byte_counter <= readin_byte_counter + 8;

	    //$display("dout = %64h", dout);

            case(readin_counter)
            0: read_buff[63:0] <= dout;
            1: read_buff[127:64] <= dout;
            2: read_buff[191:128] <= dout;
            3: read_buff[255:192] <= dout;
            4: read_buff[319:256] <= dout;
            5: read_buff[383:320] <= dout;
            6: read_buff[447:384] <= dout;
            7: read_buff[511:448] <= dout;
            8: read_buff[575:512] <= dout;
            9: read_buff[639:576] <= dout;
            10: read_buff[703:640] <= dout;
            11: read_buff[767:704] <= dout;
            12: read_buff[831:768] <= dout;
            13: read_buff[895:832] <= dout;
            14: read_buff[959:896] <= dout;
            15: read_buff[1023:960] <= dout;
            //16: read_buff[1087:1024] <= dout;
            //17: read_buff[1151:1088] <= dout;
            //18: read_buff[1215:1152] <= dout;
            //19: read_buff[1279:1216] <= dout;
            //20: read_buff[1343:1280] <= dout;
            //21: read_buff[1407:1344] <= dout;
            //22: read_buff[1471:1408] <= dout;
            //23: read_buff[1535:1472] <= dout;
            //24: read_buff[1599:1536] <= dout;
            endcase
	    
        end
    end


    //for handling output commands and such for messages
    always@(posedge clk) // to master
    begin
	reset_d <= reset;

        if(reset == 1)
        begin
            start_mesg <= 0;
            resp_counter <= 0;
            read_time <= 0;

            readout_counter <= 0;
            readout_counter_full <= 0;
	    stupid_flag <= 0;

	    frm_ctl <= 0;
        end

	if((reset_d == 1)&&(reset == 0))frm_ctl <= 1;

	if((start_mesg == 1) || from_ctl_two == 1)
        begin
            start_mesg <= 1;
            resp_counter <= resp_counter + 1;

	    //case(in_message_rsp)
	    //3: $display("read_resp");
	    //4: $display("write_rsp");
	    //5: $display("message");
	    //endcase

            case(resp_counter)
            0: 
			begin
				frm_ctl <= 1;
				//if(in_message_rsp == 5) frm_data <= #1 {in_alen,in_dlen,3'b101};
				if(in_message_rsp == 5) frm_data <= #1 {in_alen,3'b000,3'b101};
				else frm_data <= #1 {resp_code,3'b000,in_message_rsp};

				if(in_message_rsp == 3) stupid_flag <= 1;
			end
            1: 
            begin
				frm_ctl <= 0;
                if(in_message_rsp == 3)
                begin
                    frm_data <= #1 in_source_id;
                    read_resp_dest_id_buffer <= in_dest_id; //need to buffer this information just incase it gets overwritten with new info... cause read resp is opposite dest = source in response
                end
                //if((in_message_rsp == 4) || (in_message_rsp == 5))frm_data <= #1 in_dest_id;
		//if(in_message_rsp == 4)frm_data <= #1 in_dest_id;
		if(in_message_rsp == 4)frm_data <= #1 in_source_id;
		if(in_message_rsp == 5)frm_data <= #1 in_source_id; 
            end
            2:
            begin
		//frm_ctl <= 0;
                if(in_message_rsp == 3)frm_data <= #1 read_resp_dest_id_buffer;
                //if((in_message_rsp == 4) || (in_message_rsp == 5))frm_data <= #1 in_source_id; 
		//if(in_message_rsp == 4)frm_data <= #1 in_source_id;
		if(in_message_rsp == 4)frm_data <= #1 in_dest_id;  
		if(in_message_rsp == 5)frm_data <= #1 in_dest_id; 
            end
            3: 
            begin
                if(in_message_rsp == 3)// this is the read response actual data... need to fill this with the read counter number
                begin
		     //$display("READ RESPONSE!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                    frm_data <= #1 readin_byte_buff;
			if(resp_code == 0) 
			begin
				justincase_buff <= read_buff;
				read_time <= 1;
				start_mesg <= 0;
				resp_counter <= 0;
			end
                end

                if(in_message_rsp == 4)
                begin
                    if(resp_code == 0) frm_data <= #1 (write_resp_counter); // I need to add 1 because my write_counter starts at 0
					else frm_data <= #1 (error_reason);
                end

		if(in_message_rsp == 5)
                begin // there are going to be multiple of these
                    if(mesg_rsn == 0)
		    begin
			frm_data <= #1 8'h17; // this is message for push and firstout high
			//$display("pushout posedge..................");
		    end
		    
		    if(mesg_rsn == 1)
			begin
				frm_data <= #1 8'h42;
				//$display("stopin negedge...............");
			end
                end
            end
            4: 
            begin
			//frm_ctl <= #1 1;
				if(in_message_rsp == 3)// this is the read response actual data... need to fill this with the read counter number
                begin
					
					frm_data <= #1 error_reason;
					start_mesg <= 0;
					resp_counter <= 0;
					//frm_ctl <= #1 1;
				end

                if(in_message_rsp == 4)
                begin
                    start_mesg <= 0;
                    resp_counter <= 0;
		    frm_ctl <= #1 1;
                end
		
		if(in_message_rsp == 5)
                begin
                    if(mesg_rsn == 0)frm_data <= #1 8'h12; // I need to add 1 because my write_counter starts at 0
                    if(mesg_rsn == 1)frm_data <= #1 8'h78;    
					start_mesg <= 0;
					resp_counter <= 0;
					//frm_ctl <= #2 1;
                end
            end
            endcase
        end

	else
	begin
		frm_data <= #1 8'd0;
		if(read_time != 1)frm_ctl <= #1 1;
	end

        if(read_time == 1)
        begin
            if(readout_counter == (2**in_dlen))
            begin
		frm_ctl <= #1 1;
                readout_counter <= 0;
                read_time <= 0;
                //if(readout_counter_full != 192)stopout <= 0; 
				stupid_flag <= 0;
            end

            else
            begin
                readout_counter <= readout_counter + 1;
                readout_counter_full <= readout_counter_full + 1;

				//frm_data <= #1 read_buff;
				frm_data <= #1 justincase_buff;
				//$display("read_buff = %2h", justincase_buff[7:0]);
				justincase_buff <= justincase_buff >> 8;
				//$monitor("frm_data = %8h", frm_data);
            end

			//if(readout_counter == (2**in_dlen)-2) stupid_flag <= 0;
			//if(readout_counter == 1) stupid_flag <= 1;
        end

	

	if((mesg_rsn == 1)&&(pushout == 0))readout_counter_full <= 0;
    end

    always@(posedge clk)
    begin

	if(from_ctl_two == 1) stupid_signal = 1;
	else stupid_signal = 0;

    end
endmodule


