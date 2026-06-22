`timescale 1ns/1ps
// MODE 0: directed/register-file/alias/random chain; 1: command stall;
// MODE 2: completion stall; 3: reset cancellation; 4: randomized sequence;
// MODE 5: unsupported Custom-0 encoding. The golden model is kept separately
// from the engine register array.
module tb_vector_vadd #(parameter integer MODE=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,eng_cmd_ready,vec_cpl_valid,vec_cpl_ready,eng_cpl_valid,eng_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we,dbg_vreg_write_valid; logic [4:0] dbg_waddr,dbg_raddr,dbg_vreg_write_addr; logic [31:0] dbg_wdata,dbg_rdata,dbg_vreg_write_data,expected[0:31],initial_expected[0:31],expected_write_data[0:63]; logic [4:0] expected_write_addr[0:63];
  logic allow_cmd=1; logic [31:0] mem[0:255]; logic [31:0] initial_v3; integer i, cmds,cpls,vec_retires,vreg_writes,write_index,expected_ops,random_state;
  assign vec_cmd_ready=eng_cmd_ready&&allow_cmd; assign eng_cpl_ready=vec_cpl_ready; assign vec_cpl_valid=eng_cpl_valid;
  rv32_core_pipe #(.VEC_CPL_READY_STALL(MODE==2?5:0)) dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(.clk,.rst_n,.vec_cmd_valid(vec_cmd_valid&&allow_cmd),.vec_cmd_ready(eng_cmd_ready),.vec_cmd_op_class,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_id,.vec_cpl_ready(eng_cpl_ready),.vec_cpl_valid(eng_cpl_valid),.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),.dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data);
  function automatic [31:0] vec(input integer rs2,input integer rs1,input integer rd); vec={7'h00,rs2[4:0],rs1[4:0],3'd3,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] vec_bad(input integer rs2,input integer rs1,input integer rd); vec_bad={7'h00,rs2[4:0],rs1[4:0],3'd7,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] jal(input integer off); jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],5'd0,7'h6f}; endfunction
  function automatic [31:0] model_add(input [31:0] a,input [31:0] b); integer k; begin for(k=0;k<4;k=k+1) model_add[k*8 +: 8]=a[k*8 +: 8]+b[k*8 +: 8]; end endfunction
  task automatic init_reg(input integer n,input [31:0] value); begin
    @(negedge clk); dbg_waddr=n; dbg_wdata=value; dbg_we=1;
    @(posedge clk); @(negedge clk); dbg_we=0; expected[n]=value; initial_expected[n]=value;
  end endtask
  task automatic emit(input integer rd,input integer rs1,input integer rs2,input integer slot); begin
    mem[slot]=vec(rs2,rs1,rd);
    expected_write_addr[write_index]=rd[4:0];
    expected_write_data[write_index]=model_add(expected[rs1],expected[rs2]);
    expected[rd]=expected_write_data[write_index];
    write_index=write_index+1;
  end endtask
  task automatic random_emit(input integer slot); integer rd,rs1,rs2; begin
    random_state=(random_state*1103515245)+12345; rd=(random_state>>16)&31;
    random_state=(random_state*1103515245)+12345; rs1=(random_state>>16)&31;
    random_state=(random_state*1103515245)+12345; rs2=(random_state>>16)&31;
    emit(rd,rs1,rs2,slot);
  end endtask
  task automatic check_regs; integer n; begin for(n=0;n<32;n=n+1) begin dbg_raddr=n; #1; if(dbg_rdata!==expected[n]) $fatal(1,"v%0d mismatch got=%h want=%h",n,dbg_rdata,expected[n]); end end endtask
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;cmds<=0;cpls<=0;vec_retires<=0;vreg_writes<=0;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[9:2]];end
      if(vec_cmd_valid&&vec_cmd_ready) cmds<=cmds+1;
      if(vec_cpl_valid&&vec_cpl_ready) cpls<=cpls+1;
      if(dbg_vreg_write_valid) begin
        if(!(vec_cpl_valid&&vec_cpl_ready)) $fatal(1,"vector write outside completion handshake");
        if(dbg_vreg_write_addr!==expected_write_addr[vreg_writes] || dbg_vreg_write_data!==expected_write_data[vreg_writes]) $fatal(1,"vector write %0d got v%0d=%h want v%0d=%h",vreg_writes,dbg_vreg_write_addr,dbg_vreg_write_data,expected_write_addr[vreg_writes],expected_write_data[vreg_writes]);
        vreg_writes<=vreg_writes+1;
      end
      if(retire_valid&&!retire_trap&&retire_instr[6:0]==7'h0b) begin if(retire_rd_we) $fatal(1,"VADD8 scalar writeback"); vec_retires<=vec_retires+1; end
    end
  end
  initial begin
    for(i=0;i<256;i=i+1) mem[i]=32'h00000013;
    // Leave startup NOPs for bounded debug initialization.  The wrong-path
    // VADD8 at PC 804 is skipped by the jump at PC 800.
    mem[200]=jal(8); mem[201]=vec(2,1,30);
    mem[202]=32'h00000013;
    dbg_we=0;dbg_waddr=0;dbg_wdata=0;dbg_raddr=0;
    repeat(3) @(posedge clk); rst_n=1;
    // All state observed by this test is deliberately initialized through
    // the bounded debug port before the first vector instruction at PC 40.
    for(i=0;i<32;i=i+1) init_reg(i,32'h10203040 ^ (i*32'h01010101));
    // Explicit named INT8 cases, with lane 0 in bits [7:0].
    init_reg(6,32'h00000000); init_reg(7,32'h00000000);
    init_reg(9,32'h00000000); init_reg(10,32'h11223344);
    init_reg(12,32'h01010101); init_reg(13,32'h7f7f7f7f);
    init_reg(15,32'h01010101); init_reg(16,32'hffffffff);
    init_reg(18,32'h807ffe80); init_reg(19,32'hff0201ff);
    init_reg(22,32'h10ff7f00); init_reg(23,32'h010102f0);
    initial_v3=expected[3];
    write_index=0;
    // Independent software-style lane model, updated in program order.
    emit(8,6,7,202); emit(11,9,10,203); emit(14,12,13,204);
    emit(17,15,16,205); emit(20,18,19,206); emit(24,22,23,207);
    emit(3,1,2,208); emit(4,3,1,209); emit(1,1,2,210); emit(2,1,2,211);
    emit(5,5,5,212); emit(31,0,31,213); emit(0,0,0,214);
    mem[215]=32'h00000073;
    expected_ops=write_index;
    if(MODE==4) begin
      random_state=32'h13579bdf;
      for(i=0;i<32;i=i+1) random_emit(215+i);
      mem[247]=32'h00000073;
      expected_ops=write_index;
    end
    if(MODE==5) begin
      mem[200]=vec_bad(2,1,3);
      for(i=0;i<32;i=i+1) expected[i]=initial_expected[i];
      expected_ops=0;
    end
    if(MODE==1) begin allow_cmd=0; while(!vec_cmd_valid) @(posedge clk); repeat(4) begin @(posedge clk); if(!vec_cmd_valid||cmds!=0) $fatal(1,"command backpressure failure"); end allow_cmd=1; end
    if(MODE==3) begin while(cmds==0) @(posedge clk); @(posedge clk); rst_n=0; @(posedge clk); #1; dbg_raddr=3; #1; if(eng_cpl_valid||retire_valid||dbg_vreg_write_valid||vreg_writes!=0||dbg_rdata!==initial_v3) $fatal(1,"reset failed to cancel VADD8 without destination update got=%h want=%h",dbg_rdata,initial_v3); repeat(2) @(posedge clk); rst_n=1; end
    repeat(900) begin
      @(posedge clk);
      // The first command writes v3. Check its pre-commit state only; later
      // commands intentionally observe the updated v3 as part of the chain.
      if(MODE==2 && cpls==0 && eng_cpl_valid && !vec_cpl_ready && (engine.vregs[3]!==initial_v3 || dbg_vreg_write_valid)) $fatal(1,"VADD committed before completion handshake");
      if(trap_valid) begin
        @(posedge clk); check_regs;
        // Counters reset with the DUT, so reset mode reports the fresh run.
        if(cmds != expected_ops || cpls != expected_ops || vec_retires != expected_ops || vreg_writes != expected_ops) $fatal(1,"event counts cmds=%0d cpls=%0d writes=%0d retires=%0d",cmds,cpls,vreg_writes,vec_retires);
        if(dut.rf.regs[0]!==0 || dut.rf.regs[1]!==0 || dut.rf.regs[2]!==0) $fatal(1,"unexpected scalar state");
        if(MODE==5 && mcause!=2) $fatal(1,"unsupported Custom-0 cause=%0d",mcause);
        if(MODE!=5 && mcause!=11) $fatal(1,"VADD program trap cause=%0d",mcause);
        $display("VADD mode=%0d cmds=%0d cpls=%0d writes=%0d retires=%0d",MODE,cmds,cpls,vreg_writes,vec_retires); $finish;
      end
    end
    $fatal(1,"VADD timeout mode=%0d",MODE);
  end
endmodule
