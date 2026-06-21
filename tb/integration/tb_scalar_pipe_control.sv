`timescale 1ns/1ps
module tb_scalar_pipe_control;
 logic clk=0,rst_n=0; always #5 clk=~clk; logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
 logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb; logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count; logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles; logic [31:0] mem[0:31]; integer i,n;
 rv32_core_pipe dut(.*);
 function automatic [31:0] ai(input integer m,input integer a,input integer d);ai={m[11:0],a[4:0],3'd0,d[4:0],7'h13};endfunction
 function automatic [31:0] br(input integer off,input integer b,input integer a,input integer f);br={{19{off[12]}},off[12],off[10:5],b[4:0],a[4:0],f[2:0],off[4:1],off[11],7'h63};endfunction
 function automatic [31:0] jal(input integer off,input integer d);jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],d[4:0],7'h6f};endfunction
 function automatic [31:0] jr(input integer m,input integer a,input integer d);jr={m[11:0],a[4:0],3'd0,d[4:0],7'h67};endfunction
 always_ff @(posedge clk) begin if(!rst_n) begin imem_resp_valid<=0;n<=0;end else begin if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0; if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[6:2]];end if(retire_valid&&!retire_trap)n<=n+1;end end
 initial begin
  for(i=0;i<32;i=i+1)mem[i]=32'h13;
  mem[0]=ai(1,0,1);mem[1]=ai(1,0,2);mem[2]=br(8,2,1,0);mem[3]=ai(99,0,3);mem[4]=br(8,2,1,1);mem[5]=br(8,1,0,4);mem[6]=ai(99,0,4);mem[7]=br(8,0,1,5);mem[8]=ai(99,0,4);mem[9]=br(8,1,0,6);mem[10]=ai(99,0,4);mem[11]=br(8,0,1,7);mem[12]=ai(99,0,4);mem[13]=jal(8,5);mem[14]=ai(99,0,6);mem[15]=ai(0,5,6);mem[16]=ai(81,0,7);mem[17]=jr(-1,7,8);mem[18]=ai(99,0,9);mem[20]=jal(8,0);mem[21]=ai(99,0,9);mem[22]=32'h73;
  repeat(3)@(posedge clk);rst_n=1;repeat(150)begin @(posedge clk);if(trap_valid)begin
   if(mcause!=11||dut.rf.regs[3]||dut.rf.regs[4]||dut.rf.regs[9]||dut.rf.regs[5]!==32'd56||dut.rf.regs[6]!==32'd56||dut.rf.regs[8]!==32'd72||dut.taken_branch_redirects<5||dut.non_taken_branches<1) $fatal(1,"control-flow result mismatch");
   $display("PIPE-CONTROL cycles=%0d retired=%0d redirects=%0d non_taken=%0d flush=%0d stale=%0d",cycle_count,n,dut.taken_branch_redirects,dut.non_taken_branches,control_flush_cycles,dut.stale_responses);$finish;end end $fatal(1,"control timeout");end
endmodule
