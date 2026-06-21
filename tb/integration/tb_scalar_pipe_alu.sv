`timescale 1ns/1ps
module tb_scalar_pipe_alu;
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] mem[0:63]; integer i,n,run,maxrun,last;
  rv32_core_pipe dut(.*);
  function automatic [31:0] iop(input integer imm,input integer rs1,input integer f3,input integer rd); iop={imm[11:0],rs1[4:0],f3[2:0],rd[4:0],7'h13}; endfunction
  function automatic [31:0] rop(input integer f7,input integer rs2,input integer rs1,input integer f3,input integer rd); rop={f7[6:0],rs2[4:0],rs1[4:0],f3[2:0],rd[4:0],7'h33}; endfunction
  function automatic [31:0] uop(input integer imm20,input integer rd,input integer opc); uop={imm20[19:0],rd[4:0],opc[6:0]}; endfunction
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;n<=0;run<=0;maxrun<=0;last<=-2;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=mem[imem_req_addr[7:2]]; end
      if(retire_valid&&!retire_trap) begin n<=n+1; if(cycle_count==last+1) begin run<=run+1;if(run+1>maxrun)maxrun<=run+1;end else begin run<=1;if(maxrun<1)maxrun<=1;end last<=cycle_count; end
    end
  end
  task automatic checkreg(input integer r,input [31:0] v,input [127:0] name); begin if(dut.rf.regs[r]!==v) $fatal(1,"%0s x%0d got %h expected %h",name,r,dut.rf.regs[r],v); end endtask
  initial begin
    for(i=0;i<64;i=i+1) mem[i]=32'h00000013;
    mem[0]=uop(20'h80000,1,7'h37);              // LUI
    mem[1]=uop(20'h00000,2,7'h17);              // AUIPC at PC=4
    mem[2]=iop(-1,0,0,3);                       // ADDI
    mem[3]=iop(0,3,2,4); mem[4]=iop(0,3,3,5);  // SLTI/SLTIU
    mem[5]=iop(8'hff,3,4,6); mem[6]=iop(1,0,6,7); mem[7]=iop(12'h7ff,3,7,8);
    mem[8]=iop(31,7,1,9); mem[9]=iop(31,9,5,10); mem[10]={7'h20,5'd31,5'd9,3'd5,5'd11,7'h13};
    mem[11]=rop(0,10,7,0,12); mem[12]=rop(7'h20,7,12,0,13); mem[13]=rop(0,10,7,1,14);
    mem[14]=rop(0,0,3,2,15); mem[15]=rop(0,0,3,3,16); mem[16]=rop(0,10,7,4,17);
    mem[17]=rop(0,10,9,5,18); mem[18]=rop(7'h20,10,9,5,19); mem[19]=rop(0,10,7,6,20); mem[20]=rop(0,10,7,7,21);
    mem[21]=uop(20'h00001,22,7'h37); mem[22]=iop(31,22,0,22); mem[23]=rop(0,22,7,1,23); // register shamt masking
    mem[24]=32'h00000073;
    repeat(3) @(posedge clk); rst_n=1;
    repeat(150) begin @(posedge clk); if(trap_valid) begin
      if(mcause!=11) $fatal(1,"expected ECALL, got cause %0d",mcause);
      checkreg(1,32'h80000000,"lui"); checkreg(2,32'h4,"auipc"); checkreg(3,32'hffffffff,"addi"); checkreg(4,1,"slti"); checkreg(5,0,"sltiu"); checkreg(6,32'hffffff00,"xori"); checkreg(7,1,"ori"); checkreg(8,32'h7ff,"andi"); checkreg(9,32'h80000000,"slli"); checkreg(10,1,"srli"); checkreg(11,32'hffffffff,"srai"); checkreg(12,2,"add"); checkreg(13,1,"sub"); checkreg(14,2,"sll"); checkreg(15,1,"slt"); checkreg(16,0,"sltu"); checkreg(17,0,"xor"); checkreg(18,32'h40000000,"srl"); checkreg(19,32'hc0000000,"sra"); checkreg(20,1,"or"); checkreg(21,1,"and"); checkreg(23,32'h80000000,"shift mask");
      $display("PIPE-ALU cycles=%0d retired=%0d maxrun=%0d CPI=%f",cycle_count,n,maxrun,cycle_count*1.0/n); $finish;
    end end
    $fatal(1,"ALU test timeout");
  end
endmodule
