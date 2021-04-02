module perm_blk(
    input clk, 
    input rst, 
    input pushin, 
    output reg stopin,
    input firstin, 
    input [63:0] din,
    
    output reg [2:0] m1rx, output reg [2:0] m1ry,
    input [63:0] m1rd,
    output reg [2:0] m1wx, output reg [2:0] m1wy,output reg m1wr,
    output reg [63:0] m1wd,
    
    output reg [2:0] m2rx, output reg [2:0] m2ry,
    input [63:0] m2rd,
    output reg [2:0] m2wx, output reg [2:0] m2wy,output reg m2wr,
    output reg [63:0] m2wd,

    output reg [2:0] m3rx, output reg [2:0] m3ry,
    input [63:0] m3rd,
    output reg [2:0] m3wx, output reg [2:0] m3wy,output reg m3wr,
    output reg [63:0] m3wd,
    
    output reg [2:0] m4rx, output reg [2:0] m4ry,
    input [63:0] m4rd,
    output reg [2:0] m4wx, output reg [2:0] m4wy,output reg m4wr,
    output reg [63:0] m4wd,

    output reg pushout, input stopout, output reg firstout, output reg [63:0] dout
    );

    reg [2:0] mem1_rw = 0;
    reg [2:0] state_machine = 0;
    reg [3:0] prev_state_machine = 0;
    reg input_ready = 0;
    reg outgoing = 0;
    reg gogo = 0;
    logic [2:0] i_out = 0;
    logic [2:0] j_out = 0;
    reg [2:0] i = 3'd0; 
    reg [2:0] j = 3'd0;
    reg [4:0] around_n_around;

	initial begin
		dout = 64'd0;
		pushout = 1'b0;
		firstout = 1'b0;
		stopin = 1'b0;
	end	

    always@(posedge clk)
    begin
        gogo = 0;

        if(rst == 1'b1) // reset state continuously places case statement into state_machine = 0 or reset state 
	    begin		
		    state_machine = 1'd0;
            gogo = 0;
	    end 
        
        case(state_machine)
            3'd0: //rst
            begin
                dout = 64'd0;
		        stopin = 0;
                state_machine = 1'd1; // reset will automatically progress to input state, but will be overwritten to come back to this state if reset is still high
            end

            3'd1: //state for writing din into memory 1
            begin
                if((firstin == 1'b1)&&(stopin == 0))
                begin
                    around_n_around = 0;
                    stopin = 1'b0;
                    m1wx = 1'b0;
                    m1wy = 1'b0;
		            m1wd = din;
                    m1wr = 1'b1;
                    j = 1'b1;
                end

                else if((pushin == 1'b1)&&(m1wr == 1'b1)) 
                begin        
                    // memory writes are at the top with additions to index due to the need of write value to be a clock cycle behind the read values (Read being din this time)
                    // remember that din and other read operations are offset by 1 tick (#1) so writes needs to lag behind and operate the following clock cycle
                    m1wx = j;
                    m1wy = i;
		            m1wd = din;

                    if(j == 3'd4)
                    begin
                        j = 0;
                        
                        if(i == 3'd4) // as above, i is associated with y for m1wd
                        begin
			                stopin = #1 1'b1; // setting stopin to one when we've recieved 200 bytes
                            								
                            i = 0;
                    	    j = 0;
							j_out = 0;
                            //prepare for start of theta
                            m2wy = 0; 
                            m2wx = 0;
                            m2wd = 64'd0;
                            m1ry = 0;
                    	    m1rx = 0;
                            m2ry = 0;
                            m2rx = 0;
			                //
                            state_machine = 2'd2; // theta state
                            m2wr = 1'd1;
                            m3wr = 1'd1;
                        end

                        else i = i + 1'b1;
                    end

                    else j = j + 1'b1;
                end
            end

            3'd2: //theta
            begin
				if(outgoing == 0)
				begin

					// part C of theta
					if(mem1_rw == 1'b0)
					begin
						// again remember that write indexes need to update a clock cycle after read indexes due to the #1 lag in the read 
						//(aka read info is not accessible the clock cycle when it's asked for due to "setup time")
						m2wx = m2rx;
						m2wy = 0;

						m2ry = 0; 

						if(around_n_around < 6)
						begin
							// C[x] = A[x,0]^A[x,1]^A[x,2]^A[x,3]^A[x,4] -> written into m2wd
							if(m1ry == 0) m2wd = m1rd;
							else m2wd = m2wd^m1rd;
							//
							if(m1ry == 4) 
							begin
								m1ry = 0;

								if(m1rx == 4) 
								begin
									mem1_rw = 2;
									
									m2ry = 0;
									m2rx = 0; 

									m3wy = 0;
									m3wx = 4;

									m3ry = 0;
									m3rx = 0;
								end

								else
								begin
									m1rx = m1rx + 1;
									m2rx = m2rx + 1;
								end
							end

							else 
							begin
								m1ry = m1ry + 1;
							end
						end

						else
						begin
							// C[x] = A[x,0]^A[x,1]^A[x,2]^A[x,3]^A[x,4] -> written into m2wd
							if(m4ry == 0) m2wd = m4rd;
							else m2wd = m2wd^m4rd;
							//
							if(m4ry == 4) 
							begin
								m4ry = 0;

								if(m4rx == 4) 
								begin
									mem1_rw = 2;
									
									m2ry = 0;
									m2rx = 0; 

									m3wy = 0;
									m3wx = 4;

									m3ry = 0;
									m3rx = 0;
								end

								else
								begin
									m4rx = m4rx + 1;
									m2rx = m2rx + 1;
								end
							end

							else 
							begin
								m4ry = m4ry + 1;
							end
						end
					end       
					
					// part D of theta
					else if((mem1_rw == 2)||(mem1_rw == 4))
					begin

						case(mem1_rw)
							2: // rot(C[x+1],1)
							begin
								m3wx = (m2rx + 4) % 5;
						
								m3wd = {m2rd[62:0], m2rd[63]}; 
							end

							4:
							begin
								m3wx = m3rx;
						 
								m3wd = m3rd ^ m2rd; //D[x] = C[x-1] ^ rot(C[x+1],1) ; [ m2rd is C[x+1] ] and [ m3rd is rot(C[x+1],1) ]
							end
						endcase

						if((m3wx == 3)&&(mem1_rw == 2)) // all this is... is to prepare for transitioning into the next part of D where "mem1_rw = 4"
						begin
							m2ry = 0;
							m2rx = 0; 
							m3ry = 0;
							m3rx = 1;
							mem1_rw = 4;
						end

						else if((m3rx == 0)&&(mem1_rw == 4)) // all this is... is to prepare for transitioning into the next part of D where "mem1_rw = 5"
						begin
							mem1_rw = 5;

							if(around_n_around < 6)
							begin
								m1rx = 0;
								m1ry = 0;
							end

							else
							begin
								m4rx = 0;
								m4ry = 0;
							end

							m3rx = 0;
							m3ry = 0;
						end

						else 
						begin
							if(mem1_rw == 2)
							begin
								m2rx = m2rx + 1;
							end

							if(mem1_rw == 4)
							begin
								m3rx = (m3rx + 1) % 5;
								m2rx = m2rx + 1;
							end
						end
					end
					
					else if(mem1_rw == 5) // transition state... needed this to not overwrite the 0,0 index value
					begin
						mem1_rw = 6;
					end

					else if(mem1_rw == 6) // the last part of theta where you xor D with every value in A
					begin

						if(around_n_around < 6)
						begin
							m3rx = m3rx;
							m3ry = 0;
							m2wx = m1rx;
							m2wy = m1ry;
							m2wd = m3rd^m1rd; // A[x,y] = A[x,y] ^ D[x]

							if(m1ry == 4)
							begin
								m1ry = 0;

								if(m1rx == 4)
								begin
									state_machine = 3; 
									mem1_rw = 0;

									m2rx = 0;
									m2ry = 0;

									m3wx = 0;
									m3wy = 0;

									m1wx = 0;
									m1wy = 0;

									i = 0;
									j = 0;

									m1wr = 1'd1;
								end

								else
								begin
									m1rx = m1rx + 1'b1;
									m3rx = m3rx + 1'b1;
								end
							end

							else
							begin
								m1ry = m1ry + 1;
								m1rx = m1rx;
							end
						end

						else
						begin
							m3rx = m3rx;
							m3ry = 0;

							m2wx = m4rx;
							m2wy = m4ry;

							m2wd = m3rd^m4rd; // A[x,y] = A[x,y] ^ D[x]

							if(m4ry == 4)
							begin
								m4ry = 0;

								if(m4rx == 4)
								begin
									state_machine = 3; 

									mem1_rw = 0;

									m2rx = 0;
									m2ry = 0;

									m3wx = 0;
									m3wy = 0;

									m4wx = 0;
									m4wy = 0;

									i = 0;
									j = 0;

									m1wr = 1'd1;
									m4wr = 1'd1;
								end

								else
								begin
									m4rx = m4rx + 1'b1;
									m3rx = m3rx + 1'b1;
								end
							end

							else
							begin
								m4ry = m4ry + 1;
								m4rx = m4rx;
							end
						end
					end
				end  
            end

            3'd3: //rho and pi
            begin
                // B[y,2x+3y] = rot(A[x,y], r[x,y]) -> for B[y,2x+3y] -> B[m3wx,m3wy]
                m3wy = ((2 * m2rx) + (3 * m2ry)) % 5; 
                m3wx = m2ry % 5;

                if(around_n_around < 6)
                begin
                    m1wy = ((2 * m2rx) + (3 * m2ry)) % 5; 
                    m1wx = m2ry % 5;
                end

                else
                begin
                    m4wy = ((2 * m2rx) + (3 * m2ry)) % 5; 
                    m4wx = m2ry % 5;
                end

                case(m2rx) // essentially the lookup table for (rho and pi)
					3: 
					begin
						m3wd = ((m2ry == 2) ? {m2rd[38:0],m2rd[63:39]} : (m2ry == 1) ? {m2rd[8:0],m2rd[63:9]} : (m2ry == 0) ? {m2rd[35:0],m2rd[63:36]} : (m2ry == 4) ? {m2rd[7:0],m2rd[63:8]} : {m2rd[42:0],m2rd[63:43]});
						
						if(around_n_around < 6) m1wd = ((m2ry == 2) ? {m2rd[38:0],m2rd[63:39]} : (m2ry == 1) ? {m2rd[8:0],m2rd[63:9]} : (m2ry == 0) ? {m2rd[35:0],m2rd[63:36]} : (m2ry == 4) ? {m2rd[7:0],m2rd[63:8]} : {m2rd[42:0],m2rd[63:43]});
						else m4wd = ((m2ry == 2) ? {m2rd[38:0],m2rd[63:39]} : (m2ry == 1) ? {m2rd[8:0],m2rd[63:9]} : (m2ry == 0) ? {m2rd[35:0],m2rd[63:36]} : (m2ry == 4) ? {m2rd[7:0],m2rd[63:8]} : {m2rd[42:0],m2rd[63:43]});
					end
					4: 
					begin
						m3wd = ((m2ry == 2) ? {m2rd[24:0],m2rd[63:25]} : (m2ry == 1) ? {m2rd[43:0],m2rd[63:44]} : (m2ry == 0) ? {m2rd[36:0],m2rd[63:37]} : (m2ry == 4) ? {m2rd[49:0],m2rd[63:50]} : {m2rd[55:0],m2rd[63:56]});
						
						if(around_n_around < 6) m1wd = ((m2ry == 2) ? {m2rd[24:0],m2rd[63:25]} : (m2ry == 1) ? {m2rd[43:0],m2rd[63:44]} : (m2ry == 0) ? {m2rd[36:0],m2rd[63:37]} : (m2ry == 4) ? {m2rd[49:0],m2rd[63:50]} : {m2rd[55:0],m2rd[63:56]});
						else m4wd = ((m2ry == 2) ? {m2rd[24:0],m2rd[63:25]} : (m2ry == 1) ? {m2rd[43:0],m2rd[63:44]} : (m2ry == 0) ? {m2rd[36:0],m2rd[63:37]} : (m2ry == 4) ? {m2rd[49:0],m2rd[63:50]} : {m2rd[55:0],m2rd[63:56]});
					end
					0: 
					begin
						m3wd = ((m2ry == 2) ? {m2rd[60:0],m2rd[63:61]} : (m2ry == 1) ? {m2rd[27:0],m2rd[63:28]} : (m2ry == 0) ? m2rd : (m2ry == 4) ? {m2rd[45:0],m2rd[63:46]} : {m2rd[22:0],m2rd[63:23]});
						
						if(around_n_around < 6) m1wd = ((m2ry == 2) ? {m2rd[60:0],m2rd[63:61]} : (m2ry == 1) ? {m2rd[27:0],m2rd[63:28]} : (m2ry == 0) ? m2rd : (m2ry == 4) ? {m2rd[45:0],m2rd[63:46]} : {m2rd[22:0],m2rd[63:23]});
						else m4wd = ((m2ry == 2) ? {m2rd[60:0],m2rd[63:61]} : (m2ry == 1) ? {m2rd[27:0],m2rd[63:28]} : (m2ry == 0) ? m2rd : (m2ry == 4) ? {m2rd[45:0],m2rd[63:46]} : {m2rd[22:0],m2rd[63:23]});
					end
					1: 
					begin
						m3wd = ((m2ry == 2) ? {m2rd[53:0],m2rd[63:54]} : (m2ry == 1) ? {m2rd[19:0],m2rd[63:20]} : (m2ry == 0) ? {m2rd[62:0],m2rd[63]} : (m2ry == 4) ? {m2rd[61:0],m2rd[63:62]} : {m2rd[18:0],m2rd[63:19]});
						
						if(around_n_around < 6) m1wd = ((m2ry == 2) ? {m2rd[53:0],m2rd[63:54]} : (m2ry == 1) ? {m2rd[19:0],m2rd[63:20]} : (m2ry == 0) ? {m2rd[62:0],m2rd[63]} : (m2ry == 4) ? {m2rd[61:0],m2rd[63:62]} : {m2rd[18:0],m2rd[63:19]});
						else m4wd = ((m2ry == 2) ? {m2rd[53:0],m2rd[63:54]} : (m2ry == 1) ? {m2rd[19:0],m2rd[63:20]} : (m2ry == 0) ? {m2rd[62:0],m2rd[63]} : (m2ry == 4) ? {m2rd[61:0],m2rd[63:62]} : {m2rd[18:0],m2rd[63:19]});
					end
					2: 
					begin
						m3wd = ((m2ry == 2) ? {m2rd[20:0],m2rd[63:21]} : (m2ry == 1) ? {m2rd[57:0],m2rd[63:58]} : (m2ry == 0) ? {m2rd[1:0],m2rd[63:2]} : (m2ry == 4) ? {m2rd[2:0],m2rd[63:3]} : {m2rd[48:0],m2rd[63:49]});
						
						if(around_n_around < 6) m1wd = ((m2ry == 2) ? {m2rd[20:0],m2rd[63:21]} : (m2ry == 1) ? {m2rd[57:0],m2rd[63:58]} : (m2ry == 0) ? {m2rd[1:0],m2rd[63:2]} : (m2ry == 4) ? {m2rd[2:0],m2rd[63:3]} : {m2rd[48:0],m2rd[63:49]});
						else m4wd = ((m2ry == 2) ? {m2rd[20:0],m2rd[63:21]} : (m2ry == 1) ? {m2rd[57:0],m2rd[63:58]} : (m2ry == 0) ? {m2rd[1:0],m2rd[63:2]} : (m2ry == 4) ? {m2rd[2:0],m2rd[63:3]} : {m2rd[48:0],m2rd[63:49]});
					end
                endcase


                if(m2ry == 4)
                begin

                    m2ry = 0;

                    if(m2rx == 4)
                    begin
                        m2wy = 0; 
                        m2wx = 4;

                        m2rx = 0;
                        m2ry = 0;

                        m3ry = 0;
                        m3rx = 0;

                        if(around_n_around < 6)
                        begin
                            m1ry = 0;
                            m1rx = 1;
                        end

                        else
                        begin
                            m4ry = 0;
                            m4rx = 1;
                        end

                        i = 0;
                        state_machine = 4;
                    end

                    else m2rx = m2rx + 1'b1;
                end

                else
                begin
                    m2ry = m2ry + 1;
                    m2rx = m2rx;
                end
            end

            3'd4: //CHI
            begin
                
                if(i < 3)
                begin
                    m2wy = m3ry;

                    case(i)
						0:
						begin // ~B[x+1,y] & B[x+2,y]

							if(m3rx == 0) 
							begin
								m2wx = 4;
							end
							
							else 
							begin
								m2wx = m3rx - 1;
							end

							if(around_n_around < 6) m2wd = (~m3rd) & m1rd;
							else m2wd = (~m3rd) & m4rd;

						end

						2: // B[x,y] ^ ~B[x+1,y] & B[x+2,y]
						begin
							m2wx = m3rx;
							m2rx = m3rx;

							m2wd = m2rd ^ m3rd;

						end
                    endcase
                    
                    if(m2wy == 4)
                    begin
                        m3ry = 0;
			            m2ry = 0;
						
                        if(around_n_around < 6) m1ry = 0;
                        else m4ry = 0;

                        if(m3rx == 4) 
                        begin
 
                            if(i == 2) i = 3;
                            
                            if(i == 0)
                            begin
                                m2rx = 0;
                                m2ry = 0;

                                m3ry = 0;
                                m3rx = 0;

                                i = 2;
			                end
                        end

                        else
                        begin
                            m3rx = m3rx + 1'b1;
                        
                            if(i == 0)
                            begin
                                if(around_n_around < 6) m1rx = (m1rx + 1'b1)%5;
                                else m4rx = (m4rx + 1'b1)%5;
                            end

                            if(i == 2)
                            begin
                                m2rx = m2rx + 1'b1;
                            end        
                        end
                    end

                    else
                    begin
					
                        if(around_n_around < 6) m1ry = m1ry + 1;
                        else m4ry = m4ry + 1;
						
                        m2ry = m2ry + 1;
                        m3ry = m3ry + 1;
                        m3rx = m3rx;
                    end
                end

                else
                begin
                    state_machine = 5;

                    j = 0;
                    i = 0;

                    mem1_rw = 0;

                    if(around_n_around == 23)
                    begin 
                        m4wr = 1;

                        m2rx = 0;
                        m2ry = 0;

                        m4wy = 0;
                        m4wx = 0;
                    end

                    else
                    begin
                        m2rx = 0;
                        m2ry = 0;

                        if(around_n_around < 5)
                        begin
                            m1wr = 1;

                            m1wy = 0; 
                            m1wx = 0;
                        end

                        else
                        begin
                            m4wr = 1;

                            m4wy = 0; 
                            m4wx = 0;
                        end
                    end
                end
            end

            3'd5: //IOTA
            begin
                if(around_n_around < 5)
                begin
                    m1wy = m2ry; 
                    m1wx = m2rx;
                end

                else
                begin
                    m4wy = m2ry; 
                    m4wx = m2rx;
                end

                if((m1wx == 0) && (m1wy == 0)&&(around_n_around < 5))
                begin
                    case(around_n_around)
						0:  m1wd = m2rd ^ 64'h0000000000000001;
						1:  m1wd = m2rd ^ 64'h0000000000008082;
						2:  m1wd = m2rd ^ 64'h800000000000808A;
						3:  m1wd = m2rd ^ 64'h8000000080008000;
						4:  m1wd = m2rd ^ 64'h000000000000808B;
                    endcase
                end

                else if((m4wx == 0) && (m4wy == 0)&&(around_n_around > 4))
                begin
                    case(around_n_around)
						5:  m4wd = m2rd ^ 64'h0000000080000001;
						6:  m4wd = m2rd ^ 64'h8000000080008081;
						7:  m4wd = m2rd ^ 64'h8000000000008009;
						8:  m4wd = m2rd ^ 64'h000000000000008A;
						9:  m4wd = m2rd ^ 64'h0000000000000088;
						10: m4wd = m2rd ^ 64'h0000000080008009;
						11: m4wd = m2rd ^ 64'h000000008000000A;
						12: m4wd = m2rd ^ 64'h000000008000808B;
						13: m4wd = m2rd ^ 64'h800000000000008B;
						14: m4wd = m2rd ^ 64'h8000000000008089;
						15: m4wd = m2rd ^ 64'h8000000000008003;
						16: m4wd = m2rd ^ 64'h8000000000008002;
						17: m4wd = m2rd ^ 64'h8000000000000080;
						18: m4wd = m2rd ^ 64'h000000000000800A;
						19: m4wd = m2rd ^ 64'h800000008000000A;
						20: m4wd = m2rd ^ 64'h8000000080008081;
						21: m4wd = m2rd ^ 64'h8000000000008080;
						22: m4wd = m2rd ^ 64'h0000000080000001;
						23: m4wd = m2rd ^ 64'h8000000080008008;
                    endcase
                end

                else
                begin

                    if(around_n_around < 5)
                    begin
                        m1wd = m2rd;
                    end

                    else
                    begin
                        m4wd = m2rd;
                    end
                end

                if(i == 4)
                begin
                    i = 0;
                    m2ry = 0;

                    if(m2rx == 4)
                    begin
                        m2rx = 0;
                        m2ry = 0;

                        i = 0;

                        mem1_rw = 0;
			
                        if(around_n_around == 23) 
                        begin
                            state_machine = 6;

                            j = 0;
                            i = 0;

                            m1ry = 0;
                            m1rx = 0;

                            m2ry = 0;
                            m2rx = 0;

                            m3rx = 0;
                            m3ry = 0;
                        end
                        
                        else 
                        begin
                            i = 0;
                            j = 0;
                            //prepare for start of theta
                            m2wy = 0; 
                            m2wx = 0;
                            m2wd = 64'd0;
                            
                            m2ry = 0;
                            m2rx = 0;

                            state_machine = 2;

                            m2wr = 1'd1;
                            m3wr = 1'd1;

                            mem1_rw = 0; 

                            around_n_around = around_n_around + 1;

                            if(around_n_around < 6)
                            begin
                                m1ry = 0;
                                m1rx = 0;
                            end 
							
							else if(around_n_around == 7) 
							begin // getting ready for input process into mem1
                                m1wr = 0;
                                stopin = 0;
								input_ready = 1;
                            end

                            else
                            begin
                                m4ry = 0;
                                m4rx = 0;
                            end
                        end
                    end

                    else m2rx = m2rx + 1'b1;
                end

                else
                begin
                    i = i + 1;
            
                    m2ry = m2ry + 1;
                    m2rx = m2rx;
                end
            end

            6:
            begin
				i_out = 0;
				outgoing = 1;
                gogo = 1;
				
				if(input_ready ==1) state_machine = 1;
                else state_machine = 2;
                around_n_around = 0;

                i = 0;
                j = 0;
                //prepare for start of theta
                m2wy = 0; 
                m2wx = 0;
                m2wd = 64'd0;
                m1ry = 0;
                m1rx = 0;
                m2ry = 0;
                m2rx = 0;
                //
                m2wr = 1'd1;
                m3wr = 1'd1;
            end
	    endcase
	    
		// start input process in parallel at around_n_around == 7
        if((input_ready == 1)&&(stopin == 0)) 
        begin // In this parallel process we will used i_out and j for index because they are avaliable dring this period:
			
			if(firstin == 1'b1)
			begin
				stopin = 1'b0;
				m1wx = 1'b0;
				m1wy = 1'b0;
				m1wd = din;
				m1wr = 1'b1;
				j_out = #1 1'b1;
			end

			else if((pushin == 1'b1)&&(m1wr == 1'b1)) 
			begin        
				// memory writes are at the top with additions to index due to the need of write value to be a clock cycle behind the read values (Read being din this time)
				// remember that din and other read operations are offset by 1 tick (#1) so writes needs to lag behind and operate the following clock cycle
				m1wx = j_out;
				m1wy = i_out;
				m1wd = din;

				if(j_out == 3'd4) // as above, j is associated with x for m1wd
				begin
					j_out = 0;
					
					if(i_out == 3'd4) // as above, i is associated with y for m1wd
					begin
						stopin = #1 1'b1; // setting stopin to one when we've recieved 200 bytes
						input_ready = 0;                           
						i_out = 0;
						j_out = 0;
					end

					else i_out = i_out + 1'b1;
				end

				else j_out = #1 j_out + 1'b1;
			end
		end

		if(outgoing == 1)
		begin

			if(stopout == 0)
			begin
			
				if(i_out < 1)
				begin
				
					if(m4rx < 4)
					begin
					
						if((m4ry == 0)&&(m4rx == 0)) #1 firstout = 1;
						else #1 firstout = 0;
					
						pushout = 1;

						m4rx = (m4rx + 1)%5;
						m4ry = m4ry;
					
						dout = m4rd;
					end

					else
					begin
						#1 dout = m4rd;
			
						if(m4ry < 4) 
						begin			
							m4ry = m4ry + 1'b1;
							m4rx = 0;
						end

						else
						begin
							i_out = i_out + 1;
						end
					end
				end

				else if(i_out == 1)
				begin
					i_out = 0;
					#1 pushout = 0;
					m4rx = 0;
					m4ry = 0;
					outgoing = 0;
				end
			end
		end
    end

endmodule



