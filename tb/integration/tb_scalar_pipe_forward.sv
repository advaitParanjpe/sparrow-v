`timescale 1ns/1ps
`include "tb/integration/vec_pipe_idle_ports.svh"
module tb_scalar_pipe_forward;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] mem[0:31]; integer i,n,run,maxrun,last;
  rv32_core_pipe dut(.*);
  function automatic [31:0] ai(input integer imm,input integer rs,input integer rd); ai={imm[11:0],rs[4:0],3'd0,rd[4:0],7'h13}; endfunction
  function automatic [31:0] rr(input integer f7,input integer b,input integer a,input integer f3,input integer d); rr={f7[6:0],b[4:0],a[4:0],f3[2:0],d[4:0],7'h33}; endfunction
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;n<=0;run<=0;maxrun<=0;last<=-2;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=mem[imem_req_addr[6:2]]; end
      if(retire_valid&&!retire_trap) begin n<=n+1; if(cycle_count==last+1) begin run<=run+1; if(run+1>maxrun) maxrun<=run+1; end else begin run<=1; if(maxrun<1) maxrun<=1; end last<=cycle_count; $display("RETIRE cycle=%0d pc=%h rd=x%0d value=%h",cycle_count,retire_pc,retire_rd,retire_rd_data); end
    end
  end
  initial begin
    for(i=0;i<32;i=i+1) mem[i]=32'h13;
    mem[0]=ai(5,0,1); mem[1]=ai(1,1,2); mem[2]=rr(0,1,2,0,3); mem[3]=rr(7'h20,3,3,0,4); mem[4]=rr(0,4,0,0,5); mem[5]=ai(1,5,6); mem[6]=ai(9,0,7); mem[7]=rr(0,7,6,0,8); mem[8]=ai(99,0,0); mem[9]=ai(1,0,9); mem[10]=ai(1,0,10); mem[11]=ai(1,10,10); mem[12]=32'h73;
    repeat(3) @(posedge clk); rst_n=1;
    repeat(100) begin @(posedge clk); if(trap_valid) begin
      if(dut.rf.regs[1]!==5||dut.rf.regs[2]!==6||dut.rf.regs[3]!==11||dut.rf.regs[4]!==0||dut.rf.regs[5]!==0||dut.rf.regs[6]!==1||dut.rf.regs[8]!==10||dut.rf.regs[0]!==0||dut.rf.regs[9]!==1||dut.rf.regs[10]!==2) $fatal(1,"forwarding register result mismatch");
      if(n!=12||maxrun<12||dep_stall_cycles!=0) $fatal(1,"avoidable dependency bubble: n=%0d run=%0d dep=%0d",n,maxrun,dep_stall_cycles);
      $display("PIPE-FORWARD cycles=%0d retired=%0d maxrun=%0d CPI=%f",cycle_count,n,maxrun,cycle_count*1.0/n); $finish;
    end end
    $fatal(1,"forward test timeout");
  end
endmodule
