`timescale 1ns/1ps
// MODE: 0 success, 1 command stall, 2 completion stall, 3 exception,
//       4 vector-only, 5 reset cancellation, 6 wrong-path suppression.
module tb_scalar_pipe_vec_stub #(parameter integer MODE=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,stub_cmd_ready,vec_cpl_valid,vec_cpl_ready,stub_cpl_ready,stub_cpl_valid,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id; logic [1:0] vec_cpl_status; logic vec_cpl_result_valid,stub_busy;
  logic cmd_allow=1; logic [31:0] mem[0:15];
  logic [163:0] cmd_payload_hold;
  integer i,cmds,cpls,vec_retires,vec_writes,traps,normal_retires,wrong_path_cmds;
  logic vec_done,fresh_command_seen,reset_phase;
  assign vec_cmd_ready=stub_cmd_ready&&cmd_allow;
  assign stub_cpl_ready=vec_cpl_ready;
  assign vec_cpl_valid=stub_cpl_valid;
  rv32_core_pipe #(.VEC_CPL_READY_STALL(MODE==2?6:0)) dut(.*);
  rv32_vec_stub_engine #(.LATENCY(3)) stub(.clk,.rst_n,.vec_cmd_valid(vec_cmd_valid&&cmd_allow),.vec_cmd_ready(stub_cmd_ready),.vec_cmd_op_class,.vec_cmd_rs1_data,.vec_cmd_rs2_data,.vec_cmd_id,.vec_cpl_ready(stub_cpl_ready),.vec_cpl_valid(stub_cpl_valid),.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(stub_busy));
  function automatic [31:0] addi(input integer imm,input integer rs,input integer rd); addi={imm[11:0],rs[4:0],3'd0,rd[4:0],7'h13}; endfunction
  function automatic [31:0] vec(input integer f3,input integer rs2,input integer rs1,input integer rd); vec={7'h00,rs2[4:0],rs1[4:0],f3[2:0],rd[4:0],7'h0b}; endfunction
  function automatic [31:0] jal(input integer off,input integer rd); jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],rd[4:0],7'h6f}; endfunction
  always_ff @(posedge clk) begin
    if(!rst_n) begin
      imem_resp_valid<=0; cmds<=0; cpls<=0; vec_retires<=0; vec_writes<=0; traps<=0; normal_retires<=0; wrong_path_cmds<=0; vec_done<=0; fresh_command_seen<=0;
    end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=mem[imem_req_addr[5:2]]; end
      if(vec_cmd_valid&&vec_cmd_ready) begin
        cmds<=cmds+1; fresh_command_seen<=1;
        if(MODE==6 && vec_cmd_pc==12) wrong_path_cmds<=wrong_path_cmds+1;
      end
      if(vec_cpl_valid&&stub_cpl_ready) begin
        if(MODE==5 && !fresh_command_seen) $fatal(1,"stale completion accepted after reset");
        cpls<=cpls+1;
      end
      if(retire_valid&&!retire_trap) begin
        normal_retires<=normal_retires+1;
        if(retire_instr[6:0]==7'h0b) begin
          vec_retires<=vec_retires+1; vec_done<=1;
          if(retire_rd_we) vec_writes<=vec_writes+1;
        end else if(!vec_done && retire_pc>8) $fatal(1,"younger retirement before vector completion");
      end
      if(retire_valid&&retire_trap) traps<=traps+1;
    end
  end
  task automatic load_program;
    begin
      for(i=0;i<16;i=i+1) mem[i]=32'h00000013;
      mem[0]=addi(7,0,1); mem[1]=addi(5,0,2);
      if(MODE==6) begin
        mem[2]=jal(8,0); mem[3]=vec(0,2,1,3); mem[4]=vec(0,2,1,3); mem[5]=addi(9,0,4); mem[6]=32'h00000073;
      end else begin
        mem[2]=vec(MODE==3?2:(MODE==4?1:0),2,1,3); mem[3]=addi(9,0,4); mem[4]=32'h00000073;
      end
    end
  endtask
  task automatic check_success;
    begin
      if(MODE==4) begin
        if(dut.rf.regs[3]!=0||dut.rf.regs[4]!=9||cmds!=1||cpls!=1||vec_retires!=1||vec_writes!=0||traps!=0||dut.rf.regs[0]!=0)
          $fatal(1,"vector-only mismatch cmds=%0d cpls=%0d retires=%0d writes=%0d traps=%0d",cmds,cpls,vec_retires,vec_writes,traps);
      end else if(MODE==6) begin
        if(dut.rf.regs[3]!=12||dut.rf.regs[4]!=9||cmds!=1||cpls!=1||vec_retires!=1||vec_writes!=1||traps!=0||wrong_path_cmds!=0)
          $fatal(1,"wrong-path mismatch cmds=%0d cpls=%0d retires=%0d writes=%0d wrong=%0d",cmds,cpls,vec_retires,vec_writes,wrong_path_cmds);
      end else begin
        if(dut.rf.regs[3]!=12||dut.rf.regs[4]!=9||cmds!=1||cpls!=1||vec_retires!=1||vec_writes!=1||traps!=0)
          $fatal(1,"vector success mismatch x3=%0d x4=%0d cmds=%0d cpls=%0d retires=%0d writes=%0d traps=%0d",dut.rf.regs[3],dut.rf.regs[4],cmds,cpls,vec_retires,vec_writes,traps);
      end
    end
  endtask
  initial begin
    load_program;
    if(MODE==1) cmd_allow=0;
    repeat(3) @(posedge clk); rst_n=1;
    if(MODE==1) begin
      while(!vec_cmd_valid) @(posedge clk);
      cmd_payload_hold={vec_cmd_op_class,vec_cmd_funct,vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd,vec_cmd_rd_we,vec_cmd_imm,vec_cmd_pc,vec_cmd_id};
      repeat(4) begin @(posedge clk); if(!vec_cmd_valid||{vec_cmd_op_class,vec_cmd_funct,vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd,vec_cmd_rd_we,vec_cmd_imm,vec_cmd_pc,vec_cmd_id}!=cmd_payload_hold||cmds!=0||cpls!=0||vec_retires!=0||vec_writes!=0||traps!=0) $fatal(1,"command backpressure violation"); end
      cmd_allow=1;
      while(cmds==0) @(posedge clk);
      repeat(2) @(posedge clk); if(cmds!=1) $fatal(1,"duplicate command after ready");
    end
    if(MODE==2) begin
      while(!vec_cpl_valid) @(posedge clk);
      repeat(4) begin @(posedge clk); if(!vec_cpl_valid||vec_cpl_ready||vec_cpl_result_data!=12||vec_cpl_status!=0||!vec_cpl_result_valid||vec_cpl_id!=0||vec_retires!=0||vec_writes!=0||traps!=0) $fatal(1,"completion backpressure violation"); end
      while(cpls==0) @(posedge clk);
      repeat(2) @(posedge clk); if(cpls!=1||vec_retires>1) $fatal(1,"duplicate completion after ready");
    end
    if(MODE==5) begin
      while(cmds==0) @(posedge clk);
      @(posedge clk); rst_n=0;
      @(posedge clk); if(dut.vec_outstanding||stub_busy||retire_valid||retire_rd_we||retire_trap||trap_valid) $fatal(1,"reset did not cancel vector work");
      repeat(2) @(posedge clk); rst_n=1;
      repeat(2) @(posedge clk); if(vec_cpl_valid||retire_valid||trap_valid) $fatal(1,"stale completion after reset");
    end
    repeat(140) begin
      @(posedge clk);
      if(trap_valid) begin
        if(MODE==3) begin
          @(posedge clk);
          if(mepc!=8||mcause!=2||dut.rf.regs[3]!=0||dut.rf.regs[4]!=0||cmds!=1||cpls!=1||vec_retires!=0||vec_writes!=0||traps!=1) $fatal(1,"vector exception mismatch");
          $display("VEC-STUB exception cmds=%0d cpls=%0d pc=%h cause=%0d",cmds,cpls,mepc,mcause); $finish;
        end else if(mcause==11) begin
          check_success;
          if(MODE==5) $display("VEC-STUB reset-cancel fresh_cmds=%0d cpls=%0d retires=%0d",cmds,cpls,vec_retires);
          else $display("VEC-STUB mode=%0d cmds=%0d cpls=%0d retires=%0d writes=%0d traps=%0d",MODE,cmds,cpls,vec_retires,vec_writes,traps);
          $finish;
        end
      end
    end
    $fatal(1,"vector stub timeout mode=%0d",MODE);
  end
endmodule
