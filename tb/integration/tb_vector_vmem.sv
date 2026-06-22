`timescale 1ns/1ps
// MODE 0 directed/order/dependency; 1 command stall; 2 completion stall;
// 3 reset-store, 4 deterministic randomized transfers, 5 misaligned load,
// 6 wrong-path suppression, 7 range-store, 8 reset-load, 9 reset while
// completion is stalled, 10 misaligned store, 11 below-range load, 12 range-load.
module tb_vector_vmem #(parameter integer MODE=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=0,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,eng_cmd_ready,vec_cpl_valid,vec_cpl_ready,eng_cpl_valid,eng_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we,dbg_spad_we,dbg_vreg_write_valid,dbg_spad_write_valid; logic [4:0] dbg_waddr,dbg_raddr,dbg_vreg_write_addr; logic [31:0] dbg_wdata,dbg_rdata,dbg_vreg_write_data,dbg_spad_addr,dbg_spad_wdata,dbg_spad_raddr,dbg_spad_rdata,dbg_spad_write_addr,dbg_spad_write_data;
  logic allow_cmd=1; logic [31:0] mem[0:255], gold_v[0:31], gold_spad[0:63],cancel_v4,cancel_spad4; integer i,cmds,cpls,retires,vwrites,mwrites,scalar_writes,traps,expected_ops,expected_vwrites,expected_mwrites,random_state,random_addr,random_imm,random_base,random_index,random_is_store;
  assign vec_cmd_ready=eng_cmd_ready&&allow_cmd; assign eng_cpl_ready=vec_cpl_ready; assign vec_cpl_valid=eng_cpl_valid;
  rv32_core_pipe #(.VEC_CPL_READY_STALL((MODE==2||MODE==9)?5:0)) dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(.clk,.rst_n,.vec_cmd_valid(vec_cmd_valid&&allow_cmd),.vec_cmd_ready(eng_cmd_ready),.vec_cmd_op_class,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_rs1_data,.vec_cmd_imm,.vec_cmd_id,.vec_cpl_ready(eng_cpl_ready),.vec_cpl_valid(eng_cpl_valid),.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),.dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data,.dbg_spad_we,.dbg_spad_addr,.dbg_spad_wdata,.dbg_spad_raddr,.dbg_spad_rdata,.dbg_spad_write_valid,.dbg_spad_write_addr,.dbg_spad_write_data);
  function automatic [31:0] addi(input integer rd,input integer rs1,input integer imm); addi={imm[11:0],rs1[4:0],3'd0,rd[4:0],7'h13}; endfunction
  function automatic [31:0] vload(input integer vd,input integer base,input integer imm); vload={imm[11:0],base[4:0],3'd5,vd[4:0],7'h0b}; endfunction
  function automatic [31:0] vstore(input integer vs,input integer base,input integer imm); vstore={imm[11:5],vs[4:0],base[4:0],3'd6,imm[4:0],7'h0b}; endfunction
  function automatic [31:0] vadd(input integer vd,input integer a,input integer b); vadd={7'd0,b[4:0],a[4:0],3'd3,vd[4:0],7'h0b}; endfunction
  function automatic [31:0] vdot(input integer rd,input integer a,input integer b); vdot={7'd0,b[4:0],a[4:0],3'd4,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] jal(input integer off); jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],5'd0,7'h6f}; endfunction
  function automatic [31:0] madd(input [31:0] a,input [31:0] b); integer k; begin for(k=0;k<4;k=k+1) madd[k*8+:8]=a[k*8+:8]+b[k*8+:8]; end endfunction
  task automatic initv(input integer n,input [31:0] x); begin @(negedge clk);dbg_waddr=n;dbg_wdata=x;dbg_we=1;@(posedge clk);@(negedge clk);dbg_we=0;gold_v[n]=x;end endtask
  task automatic initm(input integer n,input [31:0] x); begin @(negedge clk);dbg_spad_addr=n*4;dbg_spad_wdata=x;dbg_spad_we=1;@(posedge clk);@(negedge clk);dbg_spad_we=0;gold_spad[n]=x;end endtask
  task automatic check_state; integer n; begin for(n=0;n<32;n=n+1) begin dbg_raddr=n;#1;if(dbg_rdata!==gold_v[n])$fatal(1,"v%0d got %h want %h",n,dbg_rdata,gold_v[n]);end for(n=0;n<64;n=n+1)begin dbg_spad_raddr=n*4;#1;if(dbg_spad_rdata!==gold_spad[n])$fatal(1,"spad %0d got %h want %h",n,dbg_spad_rdata,gold_spad[n]);end end endtask
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;cmds<=0;cpls<=0;retires<=0;vwrites<=0;mwrites<=0;scalar_writes<=0;traps<=0;end else begin
      if(imem_resp_valid&&imem_resp_ready)imem_resp_valid<=0; if(imem_req_valid&&imem_req_ready)begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[9:2]];end
      if(vec_cmd_valid&&vec_cmd_ready)begin cmds<=cmds+1;if(vec_cmd_op_class==5||vec_cmd_op_class==6)if(vec_cmd_rd_we)$fatal(1,"vmem scalar write intent");end
      if(vec_cpl_valid&&vec_cpl_ready)cpls<=cpls+1;
      if(dbg_vreg_write_valid)vwrites<=vwrites+1; if(dbg_spad_write_valid)mwrites<=mwrites+1;
      if(retire_trap)traps<=traps+1;
      if(retire_valid&&!retire_trap&&retire_instr[6:0]==7'h0b) begin retires<=retires+1;if(retire_rd_we)scalar_writes<=scalar_writes+1;end
    end
  end
  initial begin
    for(i=0;i<256;i=i+1)mem[i]=32'h00000013; for(i=0;i<32;i=i+1)gold_v[i]=0;for(i=0;i<64;i=i+1)gold_spad[i]=0;
    dbg_we=0;dbg_spad_we=0;dbg_waddr=0;dbg_wdata=0;dbg_raddr=0;dbg_spad_addr=0;dbg_spad_wdata=0;dbg_spad_raddr=0;
    repeat(3)@(posedge clk);rst_n=1; for(i=0;i<32;i=i+1)initv(i,32'd0); for(i=0;i<64;i=i+1)initm(i,32'd0); initv(0,32'h44332211);initv(31,32'h01020304);initv(2,32'h01010101);initm(5,32'haabbccdd); cancel_v4=gold_v[4];cancel_spad4=gold_spad[4];
    // x1=24: negative offset targets word 4, positive targets word 6.
    mem[10]=addi(1,0,24);mem[11]=vstore(0,1,-8);gold_spad[4]=gold_v[0];mem[12]=vload(31,1,-8);gold_v[31]=gold_spad[4];mem[13]=vload(2,1,-4);gold_v[2]=gold_spad[5];mem[14]=vstore(31,1,0);gold_spad[6]=gold_v[31];mem[15]=vadd(3,31,2);gold_v[3]=madd(gold_v[31],gold_v[2]);mem[16]=vdot(5,31,2);mem[17]=vstore(0,0,252);gold_spad[63]=gold_v[0];mem[18]=vload(1,0,252);gold_v[1]=gold_spad[63];mem[19]=32'h00000073;
    expected_ops=8;expected_vwrites=4;expected_mwrites=3;
    if(MODE==4) begin
      random_state=32'h1234abcd;expected_ops=0;expected_vwrites=0;expected_mwrites=0;
      for(i=0;i<32;i=i+1)begin random_state=random_state*1103515245+12345;initv(i,random_state);end
      for(i=0;i<64;i=i+1)begin random_state=random_state*1103515245+12345;initm(i,random_state);end
      for(i=0;i<24;i=i+1)begin
        random_state=random_state*1103515245+12345;
        case(i%6)
          0: begin random_addr=0; random_imm=0; end
          1: begin random_addr=252; random_imm=0; end
          2: begin random_addr=((random_state>>16)&31)*4; random_imm=4; if(random_addr<4)random_addr=4; end
          3: begin random_addr=((random_state>>16)&30)*4; random_imm=-4; if(random_addr>248)random_addr=248; end
          default: begin random_addr=((random_state>>16)&63)*4; random_imm=0; end
        endcase
        random_base=random_addr-random_imm;
        random_state=random_state*1103515245+12345; random_index=(random_state>>16)&31;
        random_state=random_state*1103515245+12345; random_is_store=random_state[0];
        mem[10+2*i]=addi(1,0,random_base);
        if(random_is_store)begin mem[11+2*i]=vstore(random_index,1,random_imm);gold_spad[random_addr/4]=gold_v[random_index];expected_mwrites=expected_mwrites+1;end
        else begin mem[11+2*i]=vload(random_index,1,random_imm);gold_v[random_index]=gold_spad[random_addr/4];expected_vwrites=expected_vwrites+1;end
        expected_ops=expected_ops+1;
      end
      mem[58]=32'h00000073;
    end
    if(MODE==5) begin mem[11]=vload(4,1,1);mem[12]=32'h00000073;gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;expected_ops=1;expected_vwrites=0;expected_mwrites=0;end
    if(MODE==7) begin mem[10]=addi(1,0,256);mem[11]=vstore(0,1,0);mem[12]=32'h00000073;gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;expected_ops=1;expected_vwrites=0;expected_mwrites=0;end
    if(MODE==6) begin mem[10]=jal(12);mem[11]=vstore(0,1,0);mem[12]=vload(4,0,20);mem[13]=vload(4,0,20); gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;gold_v[4]=gold_spad[5];mem[14]=32'h00000073;expected_ops=1;expected_vwrites=1;expected_mwrites=0;end
    if(MODE==8||MODE==9) begin mem[11]=vload(4,1,-4);expected_ops=8;expected_vwrites=4;expected_mwrites=3;end
    if(MODE==10) begin mem[11]=vstore(0,1,1);mem[12]=32'h00000073;gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;expected_ops=1;expected_vwrites=0;expected_mwrites=0;end
    if(MODE==11) begin mem[10]=addi(1,0,0);mem[11]=vload(4,1,-4);mem[12]=32'h00000073;gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;expected_ops=1;expected_vwrites=0;expected_mwrites=0;end
    if(MODE==12) begin mem[10]=addi(1,0,256);mem[11]=vload(4,1,0);mem[12]=32'h00000073;gold_v[1]=0;gold_v[31]=32'h01020304;gold_v[2]=32'h01010101;gold_v[3]=0;gold_spad[4]=0;gold_spad[6]=0;gold_spad[63]=0;expected_ops=1;expected_vwrites=0;expected_mwrites=0;end
    // Do not fetch the mutable test program until all debug initialization and
    // mode-specific instruction setup are complete.
    imem_req_ready=1;
    if(MODE==1)begin allow_cmd=0;while(!vec_cmd_valid)@(posedge clk);repeat(3)begin@(posedge clk);if(!vec_cmd_valid||cmds) $fatal(1,"command hold");end allow_cmd=1;end
    if(MODE==3||MODE==8)begin while(cmds==0)@(posedge clk);@(posedge clk);rst_n=0;@(posedge clk);#1;dbg_raddr=4;dbg_spad_raddr=16;#1;if(eng_cpl_valid||vwrites||mwrites||retires||cpls||dbg_rdata!==cancel_v4||dbg_spad_rdata!==cancel_spad4)$fatal(1,"pending reset cancellation");if(MODE==8)mem[11]=vstore(0,1,-8);repeat(2)@(posedge clk);rst_n=1;end
    if(MODE==9)begin while(!(eng_cpl_valid&&!vec_cpl_ready))@(posedge clk);#1;dbg_raddr=4;#1;if(dbg_rdata!==cancel_v4||dbg_vreg_write_valid||dbg_spad_write_valid)$fatal(1,"completion-stall early commit");rst_n=0;@(posedge clk);#1;if(eng_cpl_valid||vwrites||mwrites||retires||cpls)$fatal(1,"completion-stall reset cancellation");mem[11]=vstore(0,1,-8);repeat(2)@(posedge clk);rst_n=1;end
    repeat(1200)begin @(posedge clk);
      if(MODE==2&&eng_cpl_valid&&!vec_cpl_ready&&(dbg_vreg_write_valid||dbg_spad_write_valid))$fatal(1,"early vmem commit");
      if(trap_valid)begin @(posedge clk);check_state;
        if(MODE==5||MODE==7||MODE==10||MODE==11||MODE==12)begin if(mcause==0 || mepc!=32'd44 || cmds!=1 || cpls!=1 || traps!=1 || scalar_writes || vwrites || mwrites || retires)$fatal(1,"error accounting cause=%0d pc=%0d",mcause,mepc); if((MODE==5||MODE==10)&&mcause!=16)$fatal(1,"misalignment cause"); if((MODE==7||MODE==11||MODE==12)&&mcause!=17)$fatal(1,"range cause");end
        else if(cmds!=expected_ops||cpls!=expected_ops||retires!=expected_ops||vwrites!=expected_vwrites||mwrites!=expected_mwrites||scalar_writes!=((MODE==6||MODE==4)?0:1))$fatal(1,"events c=%0d cp=%0d r=%0d vw=%0d mw=%0d sw=%0d",cmds,cpls,retires,vwrites,mwrites,scalar_writes);
        $display("VMEM mode=%0d cmds=%0d cpls=%0d retires=%0d vwrites=%0d mwrites=%0d",MODE,cmds,cpls,retires,vwrites,mwrites);$finish;
      end
    end
    $fatal(1,"VMEM timeout mode=%0d",MODE);
  end
endmodule
