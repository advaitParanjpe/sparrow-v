`timescale 1ns/1ps
module tb_scalar_core;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready,imem_resp_valid,imem_resp_ready;
  logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready,dmem_req_write,dmem_resp_valid,dmem_resp_ready;
  logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] imem[0:255]; logic [7:0] dmem[0:1023];
  logic ipend,dpending; integer idelay,ddelay,cycles,i;
  logic [31:0] iaddr_latched,daddr_latched,dwrite_latched,dwdata_latched; logic [3:0] dwstrb_latched;
  logic prev_iwait,prev_dwait; logic [31:0] prev_iaddr,prev_daddr,prev_dwdata; logic prev_dwrite; logic [3:0] prev_dwstrb;

  rv32_core #(.MTVEC_RESET(32'h00000100)) dut(.*);
  assign imem_req_ready = (cycles % 3) != 0;
  assign dmem_req_ready = (cycles % 4) != 0;
  assign imem_resp_valid = ipend && idelay==0;
  assign imem_resp_data = imem[iaddr_latched[9:2]];
  assign dmem_resp_valid = dpending && ddelay==0;
  assign dmem_resp_data = {dmem[daddr_latched+3],dmem[daddr_latched+2],dmem[daddr_latched+1],dmem[daddr_latched]};
  always_ff @(posedge clk) begin
    if (!rst_n) begin ipend<=0; dpending<=0; idelay<=0; ddelay<=0; cycles<=0; prev_iwait<=0; prev_dwait<=0; end
    else begin
      cycles<=cycles+1;
      if (prev_iwait) check_true(imem_req_valid && imem_req_addr==prev_iaddr,"stable stalled imem request");
      if (prev_dwait) check_true(dmem_req_valid && dmem_req_addr==prev_daddr && dmem_req_write==prev_dwrite && dmem_req_wdata==prev_dwdata && dmem_req_wstrb==prev_dwstrb,"stable stalled dmem request");
      prev_iwait<=imem_req_valid && !imem_req_ready; prev_iaddr<=imem_req_addr;
      prev_dwait<=dmem_req_valid && !dmem_req_ready; prev_daddr<=dmem_req_addr; prev_dwrite<=dmem_req_write; prev_dwdata<=dmem_req_wdata; prev_dwstrb<=dmem_req_wstrb;
      if (imem_req_valid && imem_req_ready) begin ipend<=1; idelay<=2; iaddr_latched<=imem_req_addr; end
      else if (ipend && idelay!=0) idelay<=idelay-1;
      else if (imem_resp_valid && imem_resp_ready) ipend<=0;
      if (dmem_req_valid && dmem_req_ready) begin
        dpending<=1; ddelay<=3; daddr_latched<=dmem_req_addr; dwrite_latched<=dmem_req_write; dwdata_latched<=dmem_req_wdata; dwstrb_latched<=dmem_req_wstrb;
      end else if (dpending && ddelay!=0) ddelay<=ddelay-1;
      else if (dmem_resp_valid && dmem_resp_ready) begin
        if (dwrite_latched) begin
          if(dwstrb_latched[0]) dmem[daddr_latched]<=dwdata_latched[7:0];
          if(dwstrb_latched[1]) dmem[daddr_latched+1]<=dwdata_latched[15:8];
          if(dwstrb_latched[2]) dmem[daddr_latched+2]<=dwdata_latched[23:16];
          if(dwstrb_latched[3]) dmem[daddr_latched+3]<=dwdata_latched[31:24];
        end
        dpending<=0;
      end
    end
  end
  function automatic [31:0] I(input integer imm,input [4:0] rs1,input [2:0] f3,input [4:0] rd,input [6:0] op); I={imm[11:0],rs1,f3,rd,op}; endfunction
  function automatic [31:0] R(input [6:0] f7,input [4:0] rs2,input [4:0] rs1,input [2:0] f3,input [4:0] rd); R={f7,rs2,rs1,f3,rd,7'b0110011}; endfunction
  function automatic [31:0] S(input integer imm,input [4:0] rs2,input [4:0] rs1,input [2:0] f3); S={imm[11:5],rs2,rs1,f3,imm[4:0],7'b0100011}; endfunction
  function automatic [31:0] B(input integer imm,input [4:0] rs2,input [4:0] rs1,input [2:0] f3); B={imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11],7'b1100011}; endfunction
  function automatic [31:0] U(input integer imm,input [4:0] rd,input [6:0] op); U={imm[31:12],rd,op}; endfunction
  function automatic [31:0] J(input integer imm,input [4:0] rd); J={imm[20],imm[10:1],imm[11],imm[19:12],rd,7'b1101111}; endfunction
  task automatic clear_images; begin for(i=0;i<256;i=i+1) imem[i]=32'h00000013; for(i=0;i<1024;i=i+1)dmem[i]=0; end endtask
  task automatic reset_core; begin rst_n=0; repeat(3) @(posedge clk); rst_n=1; end endtask
  task automatic wait_trap; begin for(i=0;i<1000 && !trap_valid;i=i+1) @(posedge clk); if(!trap_valid) $fatal(1,"timeout"); end endtask
  task automatic check_true(input logic cond,input [255:0] msg); if(!cond) $fatal(1,"CHECK FAILED: %0s",msg); endtask
  task automatic load_main; integer n; begin
    clear_images; n=0;
    imem[n++]=I(5,0,0,1,7'b0010011); imem[n++]=I(-3,0,0,2,7'b0010011);
    imem[n++]=R(0,2,1,0,3); imem[n++]=R(7'b0100000,2,1,0,4); imem[n++]=R(0,1,1,1,5); imem[n++]=R(0,1,2,2,6); imem[n++]=R(0,1,2,3,7);
    imem[n++]=R(0,2,1,4,8); imem[n++]=R(0,1,1,5,9); imem[n++]=R(7'b0100000,1,2,5,17); imem[n++]=R(0,2,1,6,18); imem[n++]=R(0,2,1,7,19);
    imem[n++]=I(1,1,1,25,7'b0010011); imem[n++]=I(7,2,2,26,7'b0010011); imem[n++]=I(7,2,3,27,7'b0010011); imem[n++]=I(3,1,4,28,7'b0010011); imem[n++]=I(1,2,5,29,7'b0010011); imem[n++]=I(1,2,5,30,7'b0010011);
    imem[n++]=I(1,1,6,31,7'b0010011); imem[n++]=I(7,1,7,20,7'b0010011); imem[n++]=I(1025,2,5,30,7'b0010011);
    imem[n++]=B(8,1,1,0); imem[n++]=I(99,0,0,21,7'b0010011); imem[n++]=B(8,2,1,1); imem[n++]=I(98,0,0,21,7'b0010011);
    imem[n++]=B(8,1,2,4); imem[n++]=I(97,0,0,21,7'b0010011); imem[n++]=B(8,2,1,5); imem[n++]=I(96,0,0,21,7'b0010011);
    imem[n++]=B(8,2,1,6); imem[n++]=I(95,0,0,21,7'b0010011); imem[n++]=B(8,1,2,7); imem[n++]=I(94,0,0,21,7'b0010011);
    imem[n++]=I(2,0,0,20,7'b0010011); imem[n++]=I(-1,20,0,20,7'b0010011); imem[n++]=B(-4,0,20,1);
    imem[n++]=J(8,22); imem[n++]=I(93,0,0,21,7'b0010011); imem[n++]=U(0,24,7'b0010111); imem[n++]=I(16,24,0,24,7'b0010011); imem[n++]=I(0,24,0,23,7'b1100111); imem[n++]=I(92,0,0,21,7'b0010011);
    imem[n++]=I(512,0,0,10,7'b0010011); imem[n++]=I(-1,0,0,11,7'b0010011); imem[n++]=S(0,11,10,0); imem[n++]=S(2,11,10,1); imem[n++]=U(32'h12345000,12,7'b0110111); imem[n++]=I(16,12,0,12,7'b0010011); imem[n++]=S(4,12,10,2);
    imem[n++]=I(0,10,0,13,7'b0000011); imem[n++]=I(0,10,4,14,7'b0000011); imem[n++]=I(2,10,1,15,7'b0000011); imem[n++]=I(2,10,5,16,7'b0000011); imem[n++]=I(4,10,2,17,7'b0000011);
    imem[n++]=I(123,0,0,0,7'b0010011); imem[n++]=32'h0000000f; imem[n++]=32'h00000073;
  end endtask
  initial begin
    load_main; reset_core; wait_trap;
    check_true(mcause==11,"ecall cause"); check_true(dut.rf.regs[0]===0,"x0"); check_true(dut.rf.regs[3]===2,"add"); check_true(dut.rf.regs[4]===8,"sub"); check_true(dut.rf.regs[5]===160,"sll"); check_true(dut.rf.regs[6]===1,"slt"); check_true(dut.rf.regs[7]===0,"sltu"); check_true(dut.rf.regs[8]===32'hfffffff8 && dut.rf.regs[9]===0,"xor/srl"); check_true(dut.rf.regs[18]===32'hfffffffd && dut.rf.regs[19]===5,"or/and"); check_true(dut.rf.regs[25]===10 && dut.rf.regs[26]===1 && dut.rf.regs[27]===0,"shift/compare immediates"); check_true(dut.rf.regs[28]===6 && dut.rf.regs[29]===32'h7ffffffe && dut.rf.regs[30]===32'hfffffffe && dut.rf.regs[31]===5,"immediate ALU"); check_true(dut.rf.regs[21]===0,"branches/jumps skipped poison");
    check_true(dut.rf.regs[13]===32'hffff_ffff && dut.rf.regs[14]===255,"lb/lbu"); check_true(dut.rf.regs[15]===32'hffff_ffff && dut.rf.regs[16]===65535,"lh/lhu"); check_true(dut.rf.regs[17]===32'h12345010,"lw"); check_true(instret_count>20,"retired counter"); check_true(cycle_count>instret_count,"stall/backpressure timing");
    clear_images; imem[0]=32'h0000000b; reset_core; wait_trap; check_true(mcause==2,"custom-0 illegal");
    clear_images; imem[0]=I(1,0,2,1,7'b0000011); reset_core; wait_trap; check_true(mcause==4,"load misalign");
    clear_images; imem[0]=S(1,0,0,2); reset_core; wait_trap; check_true(mcause==6,"store misalign");
    clear_images; imem[0]=J(2,0); reset_core; wait_trap; check_true(mcause==0,"instruction target misalign");
    clear_images; imem[0]=32'h00100073; reset_core; wait_trap; check_true(mcause==3,"ebreak");
    $display("PASS: scalar RV32I directed smoke, backpressure, traps, and counters"); $finish;
  end
endmodule
