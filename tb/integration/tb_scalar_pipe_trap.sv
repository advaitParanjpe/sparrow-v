`timescale 1ns/1ps
module tb_scalar_pipe_trap;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready;
  logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready;
  logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data;
  logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap;
  logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause;
  logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb;
  logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] imem[0:15],dmem[0:3];
  integer i,test_id,expected_cause,expected_pc,fault_rd,normal_retires,post_trap_retires,store_retires;
  logic expect_load,expect_store,terminal_seen;

  rv32_core_pipe dut(.*);

  function automatic [31:0] addi(input integer imm,input integer rs1,input integer rd);
    addi={imm[11:0],rs1[4:0],3'd0,rd[4:0],7'h13};
  endfunction
  function automatic [31:0] load(input integer imm,input integer rs1,input integer funct3,input integer rd);
    load={imm[11:0],rs1[4:0],funct3[2:0],rd[4:0],7'h03};
  endfunction
  function automatic [31:0] store(input integer imm,input integer rs2,input integer rs1,input integer funct3);
    store={{20{imm[11]}},imm[11:5],rs2[4:0],rs1[4:0],funct3[2:0],imm[4:0],7'h23};
  endfunction
  function automatic [31:0] jal(input integer imm,input integer rd);
    jal={{11{imm[20]}},imm[20],imm[10:1],imm[11],imm[19:12],rd[4:0],7'h6f};
  endfunction

  always_ff @(posedge clk) begin
    if(!rst_n) begin
      imem_resp_valid<=0; dmem_resp_valid<=0;
      normal_retires<=0; post_trap_retires<=0; store_retires<=0; terminal_seen<=0;
    end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin
        imem_resp_valid<=1; imem_resp_data<=imem[imem_req_addr[5:2]];
      end
      if(dmem_resp_valid&&dmem_resp_ready) dmem_resp_valid<=0;
      if(dmem_req_valid&&dmem_req_ready) begin
        if(dmem_req_write) begin
          if(dmem_req_wstrb[0]) dmem[dmem_req_addr[3:2]][7:0]<=dmem_req_wdata[7:0];
          if(dmem_req_wstrb[1]) dmem[dmem_req_addr[3:2]][15:8]<=dmem_req_wdata[15:8];
          if(dmem_req_wstrb[2]) dmem[dmem_req_addr[3:2]][23:16]<=dmem_req_wdata[23:16];
          if(dmem_req_wstrb[3]) dmem[dmem_req_addr[3:2]][31:24]<=dmem_req_wdata[31:24];
          dmem_resp_valid<=1; dmem_resp_data<=0;
        end else begin
          dmem_resp_valid<=1; dmem_resp_data<=dmem[dmem_req_addr[3:2]];
        end
      end
      if(retire_valid&&!retire_trap) begin
        if(terminal_seen) post_trap_retires<=post_trap_retires+1;
        else normal_retires<=normal_retires+1;
      end
      if(retire_valid&&retire_trap) terminal_seen<=1;
      if(retire_mem_we) store_retires<=store_retires+1;
    end
  end

  task automatic setup_case(input integer id);
    begin
      for(i=0;i<16;i=i+1) imem[i]=32'h00000013;
      dmem[0]=32'h11223344; dmem[1]=32'h55667788; dmem[2]=32'h99aabbcc; dmem[3]=32'hddeeff00;
      expected_cause=0; expected_pc=4; fault_rd=0; expect_load=0; expect_store=0;
      imem[0]=addi(1,0,1);
      case(id)
        0: imem[1]=jal(2,0);
        1: begin imem[1]=load(0,1,3'b001,2); expected_cause=4; fault_rd=2; expect_load=1; end
        2: begin imem[1]=load(0,1,3'b010,3); expected_cause=4; fault_rd=3; expect_load=1; end
        3: begin imem[1]=addi(85,0,2); imem[2]=store(0,2,1,3'b001); expected_cause=6; expected_pc=8; expect_store=1; end
        default: begin imem[1]=addi(85,0,2); imem[2]=store(0,2,1,3'b010); expected_cause=6; expected_pc=8; expect_store=1; end
      endcase
      imem[(expected_pc>>2)+1]=addi(99,0,7);
    end
  endtask

  task automatic run_case(input integer id);
    integer timeout;
    begin
      test_id=id; setup_case(id); rst_n=0;
      repeat(3) @(posedge clk); rst_n=1;
      timeout=0;
      while(!trap_valid && timeout<80) begin @(negedge clk); timeout=timeout+1; end
      if(!trap_valid) $fatal(1,"trap case %0d timeout",id);
      if(mcause!==expected_cause || mepc!==expected_pc || !retire_trap || retire_pc!==expected_pc || retire_cause!==expected_cause)
        $fatal(1,"trap case %0d metadata cause=%0d pc=%h retire_pc=%h",id,mcause,mepc,retire_pc);
      if(retire_rd_we || dut.rf.regs[0]!==0 || dut.rf.regs[7]!==0)
        $fatal(1,"trap case %0d retirement/x0/younger register side effect",id);
      if(expect_load && dut.rf.regs[fault_rd]!==0)
        $fatal(1,"trap case %0d faulting load wrote x%0d",id,fault_rd);
      if(expect_store && (store_retires!=0 || retire_mem_we || dmem[0]!==32'h11223344 || dmem[1]!==32'h55667788 || dmem[2]!==32'h99aabbcc || dmem[3]!==32'hddeeff00))
        $fatal(1,"trap case %0d faulting store changed memory",id);
      repeat(8) @(negedge clk);
      if(post_trap_retires!=0 || dut.rf.regs[0]!==0 || dut.rf.regs[7]!==0)
        $fatal(1,"trap case %0d younger instruction retired after terminal trap",id);
      $display("PIPE-TRAP case=%0d cause=%0d mepc=%h normal_retires=%0d",id,mcause,mepc,normal_retires);
    end
  endtask

  initial begin
    for(test_id=0;test_id<5;test_id=test_id+1) run_case(test_id);
    $display("PIPE-TRAP PASS control/LH/LW/SH/SW misalignment");
    $finish;
  end
endmodule
