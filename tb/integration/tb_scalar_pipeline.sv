`timescale 1ns/1ps
module tb_scalar_pipeline;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] mem[0:31]; integer i, retire_count, max_run, run, last_retire_cycle, gaps, elapsed;
  rv32_core dut(.*);
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0; retire_count<=0; max_run<=0; run<=0; last_retire_cycle<=-2; gaps<=0; end else begin
      if(imem_resp_valid && imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid && imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=mem[imem_req_addr[6:2]]; end
      if(retire_valid) begin retire_count<=retire_count+1; if(cycle_count==last_retire_cycle+1) run<=run+1; else begin run<=1; gaps<=gaps+1; end if(run>max_run) max_run<=run; last_retire_cycle<=cycle_count; end
    end
  end
  function automatic [31:0] addi(input integer imm,input integer rd); addi={imm[11:0],5'd0,3'd0,rd[4:0],7'h13}; endfunction
  initial begin for(i=0;i<16;i=i+1) mem[i]=addi(i+1,(i%31)+1); mem[16]=32'h00000073; #1; repeat(3) @(posedge clk); rst_n=1; repeat(300) begin @(posedge clk); if(trap_valid) begin elapsed=cycle_count; $display("PIPELINE cycles=%0d retired=%0d max_consecutive_retire=%0d gaps=%0d",elapsed,retire_count,max_run,gaps); if(max_run<4) $fatal(1,"no sustained one-retire-per-cycle overlap"); $finish; end end $fatal(1,"pipeline timeout"); end
endmodule
