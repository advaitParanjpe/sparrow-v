`timescale 1ns/1ps
module tb_scalar_pipe_redirect;
 logic clk=0,rst_n=0;always #5 clk=~clk;logic imem_req_valid,imem_req_ready,imem_resp_valid,imem_resp_ready;logic [31:0] imem_req_addr,imem_resp_data;logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready;logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0;logic [3:0] dmem_req_wstrb;logic trap_valid;logic [31:0] mepc,mcause,mtvec;logic [63:0] cycle_count,instret_count;logic retire_valid,retire_rd_we,retire_mem_we,retire_trap;logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause;logic [4:0] retire_rd;logic [3:0] retire_mem_wstrb;logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;logic [31:0] mem[0:15];integer i,hold;
 rv32_core_pipe dut(.*);
 function automatic [31:0] ai(input integer m,input integer a,input integer d);ai={m[11:0],a[4:0],3'd0,d[4:0],7'h13};endfunction
 function automatic [31:0] j(input integer o,input integer d);j={{11{o[20]}},o[20],o[10:1],o[11],o[19:12],d[4:0],7'h6f};endfunction
 always_ff @(posedge clk)begin if(!rst_n)begin imem_resp_valid<=0;imem_req_ready<=1;hold<=0;end else begin
   // Hold a request while a previously buffered JAL redirects; then return the
   // accepted old-path response one cycle late, proving generation discard.
   if(cycle_count==4) begin imem_req_ready<=0;hold<=2;end else if(hold!=0) begin hold<=hold-1;if(hold==1)imem_req_ready<=1;end
   if(imem_resp_valid&&imem_resp_ready)imem_resp_valid<=0;
   if(imem_req_valid&&imem_req_ready)begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[5:2]];end
 end end
 initial begin for(i=0;i<16;i=i+1)mem[i]=32'h13;mem[0]=j(12,1);mem[1]=ai(99,0,2);mem[2]=ai(99,0,3);mem[3]=ai(7,0,4);mem[4]=32'h73;repeat(3)@(posedge clk);rst_n=1;repeat(100)begin @(posedge clk);if(trap_valid)begin if(mcause!=11||dut.rf.regs[1]!==4||dut.rf.regs[2]||dut.rf.regs[3]||dut.rf.regs[4]!==7||dut.stale_responses==0) $fatal(1,"redirect/backpressure failure");$display("PIPE-REDIRECT cycles=%0d stale=%0d wrong_path=%0d stalls=%0d",cycle_count,dut.stale_responses,dut.wrong_path_fetches,imem_stall_cycles);$finish;end end $fatal(1,"redirect timeout");end
endmodule
