`timescale 1ns/1ps
`include "tb/integration/vec_pipe_idle_ports.svh"
module tb_scalar_pipe_memory;
 logic clk=0,rst_n=0;always #5 clk=~clk;logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready;logic [31:0] imem_req_addr,imem_resp_data;logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid,dmem_resp_ready;logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data;logic [3:0] dmem_req_wstrb;logic trap_valid;logic [31:0] mepc,mcause,mtvec;logic [63:0] cycle_count,instret_count;logic retire_valid,retire_rd_we,retire_mem_we,retire_trap;logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause;logic [4:0] retire_rd;logic [3:0] retire_mem_wstrb;logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;logic [31:0] mem[0:31],dm[0:3];integer i;
 rv32_core_pipe dut(.*);
 function automatic [31:0] ai(input integer m,input integer a,input integer d);ai={m[11:0],a[4:0],3'd0,d[4:0],7'h13};endfunction
 function automatic [31:0] so(input integer m,input integer b,input integer a,input integer f);so={{20{m[11]}},m[11:5],b[4:0],a[4:0],f[2:0],m[4:0],7'h23};endfunction
 function automatic [31:0] lo(input integer m,input integer a,input integer f,input integer d);lo={m[11:0],a[4:0],f[2:0],d[4:0],7'h03};endfunction
 always_ff @(posedge clk)begin if(!rst_n)begin imem_resp_valid<=0;dmem_resp_valid<=0;dm[0]<=0;dm[1]<=0;end else begin
  if(imem_resp_valid&&imem_resp_ready)imem_resp_valid<=0;if(imem_req_valid&&imem_req_ready)begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[6:2]];end
  if(dmem_resp_valid&&dmem_resp_ready)dmem_resp_valid<=0;
  if(dmem_req_valid&&dmem_req_ready)begin if(dmem_req_write)begin if(dmem_req_wstrb[0])dm[dmem_req_addr[3:2]][7:0]<=dmem_req_wdata[7:0];if(dmem_req_wstrb[1])dm[dmem_req_addr[3:2]][15:8]<=dmem_req_wdata[15:8];if(dmem_req_wstrb[2])dm[dmem_req_addr[3:2]][23:16]<=dmem_req_wdata[23:16];if(dmem_req_wstrb[3])dm[dmem_req_addr[3:2]][31:24]<=dmem_req_wdata[31:24];dmem_resp_valid<=1;dmem_resp_data<=0;end else begin dmem_resp_valid<=1;dmem_resp_data<=dm[dmem_req_addr[3:2]];end end
 end end
 initial begin for(i=0;i<32;i=i+1)mem[i]=32'h13;mem[0]=ai(0,0,1);mem[1]={20'h80000,5'd2,7'h37};mem[2]=ai(-128,0,8);mem[3]=so(0,8,1,0);mem[4]=so(1,8,1,0);mem[5]=so(2,8,1,1);mem[6]=so(4,2,1,2);mem[7]=lo(0,1,0,3);mem[8]=lo(1,1,4,4);mem[9]=lo(2,1,1,5);mem[10]=lo(2,1,5,6);mem[11]=lo(4,1,2,7);mem[12]=32'h73;repeat(3)@(posedge clk);rst_n=1;repeat(150)begin @(posedge clk);if(trap_valid)begin if(dut.rf.regs[3]!==32'hffffff80||dut.rf.regs[4]!==32'h80||dut.rf.regs[5]!==32'hffffff80||dut.rf.regs[6]!==32'hff80||dut.rf.regs[7]!==32'h80000000||dut.load_instructions!=5||dut.store_instructions!=4)$fatal(1,"memory mismatch");$display("PIPE-MEM cycles=%0d loads=%0d stores=%0d",cycle_count,dut.load_instructions,dut.store_instructions);$finish;end end $fatal(1,"memory timeout");end
endmodule
