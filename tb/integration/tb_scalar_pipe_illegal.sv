`timescale 1ns/1ps
`include "tb/integration/vec_pipe_idle_ports.svh"
module tb_scalar_pipe_illegal;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] mem[0:7]; integer i,normal;
  rv32_core_pipe dut(.*);
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;normal<=0;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[4:2]];end
      if(retire_valid&&!retire_trap) normal<=normal+1;
    end
  end
  initial begin
    for(i=0;i<8;i=i+1) mem[i]=32'h13;
    mem[0]={7'h01,5'd1,5'd0,3'd1,5'd2,7'h13}; // invalid SLLI funct7
    mem[1]=32'h00000013;
    repeat(3) @(posedge clk);rst_n=1;
    repeat(40) begin @(posedge clk);if(trap_valid) begin
      if(mcause!=2||mepc!=0||!retire_trap||retire_rd_we||dut.rf.regs[2]!==0||normal!=0) $fatal(1,"illegal encoding escaped development illegal path");
      $display("PIPE-ILLEGAL cycles=%0d cause=%0d rd_write=%0d",cycle_count,mcause,retire_rd_we);$finish;
    end end
    $fatal(1,"illegal test timeout");
  end
endmodule
