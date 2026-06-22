`timescale 1ns/1ps
`include "tb/integration/vec_pipe_idle_ports.svh"
module tb_scalar_pipe_store_retire;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready;
  logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready,dmem_req_write,dmem_resp_valid,dmem_resp_ready;
  logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data;
  logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap;
  logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause;
  logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb;
  logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  localparam logic [31:0] KILLED_ADDR=32'd112, TARGET_ADDR=32'd116;
  logic [31:0] imem[0:31]; logic [7:0] dmem[0:255];
  integer i,requests,responses,retires,wait_cycles,response_delay,target_mem_writes,killed_mem_writes;
  logic killed_request_seen,killed_retire_seen;
  logic [31:0] pending_addr,pending_wdata;
  logic [3:0] pending_wstrb;
  logic [31:0] expected_addr[0:7]; logic [3:0] expected_strb[0:7];
  rv32_core_pipe dut(.*);
  function automatic [31:0] I(input integer imm,input integer rs1,input integer f,input integer rd); I={imm[11:0],rs1[4:0],f[2:0],rd[4:0],7'h13}; endfunction
  function automatic [31:0] S(input integer imm,input integer rs2,input integer rs1,input integer f); S={{20{imm[11]}},imm[11:5],rs2[4:0],rs1[4:0],f[2:0],imm[4:0],7'h23}; endfunction
  function automatic [31:0] J(input integer off,input integer rd); J={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],rd[4:0],7'h6f}; endfunction
  assign dmem_req_ready=(wait_cycles==0);
  always_ff @(posedge clk) begin
    if(!rst_n) begin
      imem_resp_valid<=0; dmem_resp_valid<=0; requests<=0; responses<=0; retires<=0; wait_cycles<=0; response_delay<=0;
      target_mem_writes<=0; killed_mem_writes<=0; killed_request_seen<=0; killed_retire_seen<=0;
      pending_addr<=0; pending_wdata<=0; pending_wstrb<=0;
    end
    else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=imem[imem_req_addr[6:2]]; end
      if(wait_cycles!=0) wait_cycles<=wait_cycles-1;
      if(dmem_resp_valid&&dmem_resp_ready) begin
        dmem_resp_valid<=0; responses<=responses+1;
        if(pending_wstrb[0]) dmem[pending_addr]<=pending_wdata[7:0];
        if(pending_wstrb[1]) dmem[pending_addr+1]<=pending_wdata[15:8];
        if(pending_wstrb[2]) dmem[pending_addr+2]<=pending_wdata[23:16];
        if(pending_wstrb[3]) dmem[pending_addr+3]<=pending_wdata[31:24];
        if(pending_addr==TARGET_ADDR) target_mem_writes<=target_mem_writes+1;
        if(pending_addr==KILLED_ADDR) killed_mem_writes<=killed_mem_writes+1;
      end
      if(dmem_req_valid&&dmem_req_ready) begin
        if(!dmem_req_write) $fatal(1,"unexpected load request");
        requests<=requests+1; wait_cycles<=2; response_delay<=requests%3+1;
        pending_addr<=dmem_req_addr; pending_wdata<=dmem_req_wdata; pending_wstrb<=dmem_req_wstrb;
        if(dmem_req_addr==KILLED_ADDR && dmem_req_wdata==32'h00000055 && dmem_req_wstrb==4'b1111) killed_request_seen<=1;
      end else if(!dmem_resp_valid&&requests>responses) begin
        if(response_delay!=0) response_delay<=response_delay-1;
        else begin dmem_resp_valid<=1; dmem_resp_data<=0; end
      end
      if(retire_mem_we) begin
        if(!retire_valid || retire_rd_we) $fatal(1,"invalid store retirement bundle");
        if(retires>=responses) $fatal(1,"store retired before response completion");
        if(retire_mem_addr==KILLED_ADDR && retire_mem_data==32'h00000055 && retire_mem_wstrb==4'b1111) killed_retire_seen<=1;
        if(retire_mem_addr!==expected_addr[retires] || retire_mem_data!==32'h00000055 || retire_mem_wstrb!==expected_strb[retires])
          $fatal(1,"store retirement mismatch index=%0d addr=%h data=%h strb=%h",retires,retire_mem_addr,retire_mem_data,retire_mem_wstrb);
        retires<=retires+1;
      end
    end
  end
  initial begin
    for(i=0;i<32;i=i+1) imem[i]=32'h00000013;
    for(i=0;i<256;i=i+1) dmem[i]=8'ha5;
    imem[0]=I(100,0,0,1); imem[1]=I(85,0,0,2);
    imem[2]=S(0,2,1,0); imem[3]=S(1,2,1,0); imem[4]=S(2,2,1,0); imem[5]=S(3,2,1,0);
    imem[6]=S(4,2,1,1); imem[7]=S(6,2,1,1); imem[8]=S(8,2,1,2);
    // JAL skips the killed wrong-path SW at 112 and reaches the valid target-path SW at 116.
    imem[9]=J(8,0); imem[10]=S(12,2,1,2); imem[11]=S(16,2,1,2); imem[12]=32'h00000073;
    expected_addr[0]=100; expected_addr[1]=101; expected_addr[2]=102; expected_addr[3]=103; expected_addr[4]=104; expected_addr[5]=106; expected_addr[6]=108; expected_addr[7]=TARGET_ADDR;
    expected_strb[0]=4'b0001; expected_strb[1]=4'b0010; expected_strb[2]=4'b0100; expected_strb[3]=4'b1000; expected_strb[4]=4'b0011; expected_strb[5]=4'b1100; expected_strb[6]=4'b1111; expected_strb[7]=4'b1111;
    repeat(3) @(posedge clk); rst_n=1;
    repeat(500) begin @(posedge clk); if(trap_valid) begin
      if(requests!=8 || responses!=8 || retires!=8) $fatal(1,"store event counts requests=%0d responses=%0d retires=%0d",requests,responses,retires);
      if(killed_request_seen || killed_retire_seen || killed_mem_writes!=0 || dmem[KILLED_ADDR]!==8'ha5)
        $fatal(1,"killed wrong-path store produced request=%0d retire=%0d writes=%0d memory=%h",killed_request_seen,killed_retire_seen,killed_mem_writes,dmem[KILLED_ADDR]);
      if(target_mem_writes!=1 || dmem[TARGET_ADDR]!==8'h55 || dmem[TARGET_ADDR+1]!==8'h00 || dmem[TARGET_ADDR+2]!==8'h00 || dmem[TARGET_ADDR+3]!==8'h00)
        $fatal(1,"target-path store side effect mismatch writes=%0d data=%h%h%h%h",target_mem_writes,dmem[TARGET_ADDR+3],dmem[TARGET_ADDR+2],dmem[TARGET_ADDR+1],dmem[TARGET_ADDR]);
      $display("PIPE STORE RETIRE PASS requests=%0d responses=%0d retires=%0d target_writes=%0d killed_retire=%0d",requests,responses,retires,target_mem_writes,killed_retire_seen);
      rst_n=0; @(posedge clk); #1 if(retire_mem_we||retire_valid) $fatal(1,"stale retirement after reset");
      $finish;
    end end
    $fatal(1,"store retirement timeout");
  end
endmodule
