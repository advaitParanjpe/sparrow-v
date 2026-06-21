`timescale 1ns/1ps
// Test-only architectural differential harness.  The two cores have independent
// memories and run the same generated image; ready/response decisions depend on
// transaction number, not core cycle number.
module scalar_diff_env #(parameter bit PIPE=0, parameter integer SEED=1, parameter integer MODE=0, parameter integer DEBUG=0) (
  input logic clk, input logic rst_n
);
  localparam integer WORDS=128, DATA_BYTES=256, MAX_EVENTS=256;
  logic imem_req_valid,imem_req_ready,imem_resp_valid,imem_resp_ready;
  logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready,dmem_req_write,dmem_resp_valid,dmem_resp_ready;
  logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data;
  logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap;
  logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause;
  logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb;
  logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic [31:0] imem[0:WORDS-1]; logic [7:0] data[0:DATA_BYTES-1];
  logic [31:0] regs_snapshot[0:31]; logic [7:0] data_snapshot[0:DATA_BYTES-1]; logic terminal_seen;
  logic [31:0] trace_pc[0:MAX_EVENTS-1],trace_ins[0:MAX_EVENTS-1],trace_data[0:MAX_EVENTS-1];
  logic [4:0] trace_rd[0:MAX_EVENTS-1]; logic trace_we[0:MAX_EVENTS-1],trace_trap[0:MAX_EVENTS-1];
  logic [31:0] store_addr[0:MAX_EVENTS-1],store_data[0:MAX_EVENTS-1]; logic [3:0] store_strb[0:MAX_EVENTS-1];
  integer trace_count,store_count,cycles,ireqs,dreqs,ipend,idelay,dpend,ddelay,iwait,dwait;
  logic [31:0] iaddr,daddr,dwdata; logic dwrite; logic [3:0] dwstrb;

  generate if (PIPE) begin: g_pipe
    rv32_core_pipe dut(.*);
  end else begin: g_ref
    rv32_core dut(.*);
  end endgenerate

  function automatic [31:0] I(input integer imm,input integer rs1,input integer f3,input integer rd);
    I={imm[11:0],rs1[4:0],f3[2:0],rd[4:0],7'b0010011};
  endfunction
  function automatic [31:0] R(input integer f7,input integer rs2,input integer rs1,input integer f3,input integer rd);
    R={f7[6:0],rs2[4:0],rs1[4:0],f3[2:0],rd[4:0],7'b0110011};
  endfunction
  function automatic [31:0] LD(input integer imm,input integer rs1,input integer f3,input integer rd);
    LD={imm[11:0],rs1[4:0],f3[2:0],rd[4:0],7'b0000011};
  endfunction
  function automatic [31:0] ST(input integer imm,input integer rs2,input integer rs1,input integer f3);
    ST={imm[11:5],rs2[4:0],rs1[4:0],f3[2:0],imm[4:0],7'b0100011};
  endfunction
  function automatic [31:0] BR(input integer imm,input integer rs2,input integer rs1,input integer f3);
    BR={imm[12],imm[10:5],rs2[4:0],rs1[4:0],f3[2:0],imm[4:1],imm[11],7'b1100011};
  endfunction
  function automatic [31:0] J(input integer imm,input integer rd);
    J={imm[20],imm[10:1],imm[11],imm[19:12],rd[4:0],7'b1101111};
  endfunction
  function automatic [31:0] U(input integer imm,input integer rd,input integer op);
    U={imm[31:12],rd[4:0],op[6:0]};
  endfunction
  function automatic integer stall_for(input integer txn,input integer kind);
    if (MODE==0 || MODE==2) stall_for=0;
    else if (MODE==1) stall_for=(txn+kind)%3;
    else stall_for=(txn+kind+SEED)%3;
  endfunction
  function automatic integer delay_for(input integer txn,input integer kind);
    if (MODE==0) delay_for=0;
    else if (MODE==1) delay_for=1;
    else if (MODE==2) delay_for=2+(txn%3);
    else delay_for=(txn+kind+SEED)%4;
  endfunction
  // Stall windows are local to each core's accepted transaction sequence.  They
  // therefore remain architecturally equivalent even when pipeline timing differs.
  assign imem_req_ready=(iwait==0);
  assign dmem_req_ready=(dwait==0);
  assign imem_resp_valid=ipend && idelay==0;
  assign imem_resp_data=imem[iaddr[8:2]];
  assign dmem_resp_valid=dpend && ddelay==0;
  assign dmem_resp_data={data[daddr+3],data[daddr+2],data[daddr+1],data[daddr]};

  task automatic emit(input integer n,input [31:0] ins); imem[n]=ins; endtask
  task automatic build_program;
    integer i,n,r,rd,rs,off;
    begin
      for(i=0;i<WORDS;i=i+1) imem[i]=32'h00000013;
      for(i=0;i<DATA_BYTES;i=i+1) data[i]=0;
      n=0; emit(n,I(128,0,0,1)); n=n+1; emit(n,I(5,0,0,2)); n=n+1; emit(n,I(-3,0,0,3)); n=n+1;
      emit(n,U(32'h12345000,4,7'h37)); n=n+1; emit(n,U(0,5,7'h17)); n=n+1;
      emit(n,R(0,3,2,0,6)); n=n+1; emit(n,R(7'h20,3,2,0,7)); n=n+1; emit(n,R(0,2,2,1,8)); n=n+1;
      emit(n,R(0,2,3,2,9)); n=n+1; emit(n,R(0,2,3,3,10)); n=n+1; emit(n,R(0,3,2,4,11)); n=n+1;
      emit(n,R(0,2,3,5,12)); n=n+1; emit(n,R(7'h20,2,3,5,13)); n=n+1; emit(n,R(0,3,2,6,14)); n=n+1; emit(n,R(0,3,2,7,15)); n=n+1;
      emit(n,ST(0,2,1,2)); n=n+1; emit(n,ST(4,3,1,2)); n=n+1; emit(n,LD(0,1,2,16)); n=n+1; emit(n,LD(4,1,2,17)); n=n+1;
      // Each taken branch skips its poison instruction; BNE below is deliberately not taken.
      emit(n,BR(8,2,2,0)); n=n+1; emit(n,I(99,0,0,20)); n=n+1; emit(n,BR(8,2,2,1)); n=n+1; emit(n,I(98,0,0,20)); n=n+1;
      emit(n,BR(8,2,3,4)); n=n+1; emit(n,I(97,0,0,20)); n=n+1; emit(n,BR(8,3,2,5)); n=n+1; emit(n,I(96,0,0,20)); n=n+1;
      emit(n,BR(8,3,2,6)); n=n+1; emit(n,I(95,0,0,20)); n=n+1; emit(n,BR(8,2,3,7)); n=n+1; emit(n,I(94,0,0,20)); n=n+1;
      emit(n,J(8,21)); n=n+1; emit(n,I(93,0,0,20)); n=n+1;
      emit(n,U(0,30,7'h17)); n=n+1; emit(n,I(16,30,0,30)); n=n+1; emit(n,LD(0,1,2,22)); n=n+1; // replaced below with JALR encoding
      imem[n-1]={12'd0,5'd30,3'd0,5'd0,7'b1100111}; emit(n,I(92,0,0,20)); n=n+1;
      r=SEED;
      for(i=0;i<24;i=i+1) begin
        r=(r*1103515245)+12345; rd=2+((r>>8)%27); rs=2+((r>>16)%27); off=((r>>4)%16)*4;
        case(r[3:0])
          0: emit(n,I(r>>20,rs,0,rd)); 1: emit(n,I(r>>20,rs,4,rd)); 2: emit(n,I(r>>20,rs,6,rd));
          3: emit(n,I(r>>20,rs,7,rd)); 4: emit(n,I(r>>20,rs,2,rd)); 5: emit(n,I(r>>20,rs,3,rd));
          6: emit(n,{7'd0,r[4:0],rs[4:0],3'd1,rd[4:0],7'b0010011});
          7: emit(n,{7'd0,r[4:0],rs[4:0],3'd5,rd[4:0],7'b0010011});
          8: emit(n,{7'h20,r[4:0],rs[4:0],3'd5,rd[4:0],7'b0010011});
          9: emit(n,R(0,rs,rd,0,rd)); 10: emit(n,R(0,rs,rd,4,rd)); 11: emit(n,R(0,rs,rd,6,rd));
          12: emit(n,R(0,rs,rd,7,rd)); 13: emit(n,ST(off,rs,1,2));
          default: emit(n,LD(off,1,2,rd));
        endcase
        n=n+1;
      end
      emit(n,32'h00000073);
    end
  endtask

  integer k;
  always_ff @(posedge clk) begin
    if(!rst_n) begin
      cycles<=0; ireqs<=0; dreqs<=0; ipend<=0; dpend<=0; idelay<=0; ddelay<=0; iwait<=0; dwait<=0; trace_count<=0; store_count<=0; terminal_seen<=0;
    end else begin
      cycles<=cycles+1;
      if(iwait!=0) iwait<=iwait-1;
      if(dwait!=0) dwait<=dwait-1;
      if(ipend && idelay!=0) idelay<=idelay-1;
      else if(imem_resp_valid && imem_resp_ready) ipend<=0;
      if(imem_req_valid && imem_req_ready) begin ipend<=1; iaddr<=imem_req_addr; idelay<=delay_for(ireqs,0); iwait<=stall_for(ireqs+1,0); ireqs<=ireqs+1; end
      if(DEBUG!=0 && PIPE && (cycles>=55 && cycles<=100)) $display("DIFFDBG c=%0d req=%0d/%0d a=%h fire=%0d reqg=%0d out=%0d oa=%h og=%0d fg=%0d ipend=%0d ia=%h idly=%0d resp=%0d/%0d rfire=%0d redir=%0d tgt=%h ifdxmw=%0d%0d%0d ireqs=%0d",cycles,imem_req_valid,imem_req_ready,imem_req_addr,imem_req_valid&&imem_req_ready,g_pipe.dut.req_gen,g_pipe.dut.out_v,g_pipe.dut.out_addr,g_pipe.dut.out_gen,g_pipe.dut.fetch_gen,ipend,iaddr,idelay,imem_resp_valid,imem_resp_ready,imem_resp_valid&&imem_resp_ready,g_pipe.dut.dx_redirect,g_pipe.dut.dx_target,g_pipe.dut.if_v,g_pipe.dut.dx_v,g_pipe.dut.mw_v,ireqs);
      if(dmem_req_valid && dmem_req_ready) begin
        daddr<=dmem_req_addr; dwdata<=dmem_req_wdata; dwstrb<=dmem_req_wstrb; dwrite<=dmem_req_write; ddelay<=delay_for(dreqs,1); dwait<=stall_for(dreqs+1,1); dreqs<=dreqs+1;
        if(dmem_req_write && !terminal_seen) begin store_addr[store_count]<=dmem_req_addr; store_data[store_count]<=dmem_req_wdata; store_strb[store_count]<=dmem_req_wstrb; store_count<=store_count+1; end
        if(PIPE && dmem_req_write) begin
          if(dmem_req_wstrb[0]) data[dmem_req_addr]<=dmem_req_wdata[7:0]; if(dmem_req_wstrb[1]) data[dmem_req_addr+1]<=dmem_req_wdata[15:8]; if(dmem_req_wstrb[2]) data[dmem_req_addr+2]<=dmem_req_wdata[23:16]; if(dmem_req_wstrb[3]) data[dmem_req_addr+3]<=dmem_req_wdata[31:24];
          dpend<=0;
        end else dpend<=1;
      end else if(dpend && ddelay!=0) ddelay<=ddelay-1;
      else if(dmem_resp_valid && dmem_resp_ready) begin
        if(dwrite) begin if(dwstrb[0]) data[daddr]<=dwdata[7:0]; if(dwstrb[1]) data[daddr+1]<=dwdata[15:8]; if(dwstrb[2]) data[daddr+2]<=dwdata[23:16]; if(dwstrb[3]) data[daddr+3]<=dwdata[31:24]; end
        dpend<=0;
      end
      if(retire_valid && !terminal_seen) begin trace_pc[trace_count]<=retire_pc; trace_ins[trace_count]<=retire_instr; trace_we[trace_count]<=retire_rd_we; trace_rd[trace_count]<=retire_rd_we ? retire_rd : 0; trace_data[trace_count]<=retire_rd_we ? retire_rd_data : 0; trace_trap[trace_count]<=retire_trap; trace_count<=trace_count+1; end
      if(retire_valid && retire_trap && !terminal_seen) begin
        terminal_seen<=1;
        for(k=0;k<32;k=k+1) begin
          if(PIPE) regs_snapshot[k]<=g_pipe.dut.rf.regs[k]; else regs_snapshot[k]<=g_ref.dut.rf.regs[k];
        end
        for(k=0;k<DATA_BYTES;k=k+1) data_snapshot[k]<=data[k];
      end
    end
  end
  initial build_program();
endmodule

module tb_scalar_differential #(parameter integer SEED=1, parameter integer MODE=0, parameter integer NEGATIVE=0, parameter integer DEBUG=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  scalar_diff_env #(.PIPE(0),.SEED(SEED),.MODE(MODE)) reference(.clk,.rst_n);
  scalar_diff_env #(.PIPE(1),.SEED(SEED),.MODE(MODE),.DEBUG(DEBUG)) pipeline(.clk,.rst_n);
  integer i,limit; logic mismatch,negative_detected;
  task automatic fail(input [255:0] what,input integer index); begin
    $display("DIFF FAIL seed=%0d mode=%0d category=%0s index=%0d ref={pc=%h ins=%h we=%0d rd=%0d data=%h trap=%0d} pipe={pc=%h ins=%h we=%0d rd=%0d data=%h trap=%0d} rerun='make test-scalar-diff-seed SEED=%0d MODE=%0d'",SEED,MODE,what,index,reference.trace_pc[index],reference.trace_ins[index],reference.trace_we[index],reference.trace_rd[index],reference.trace_data[index],reference.trace_trap[index],pipeline.trace_pc[index],pipeline.trace_ins[index],pipeline.trace_we[index],pipeline.trace_rd[index],pipeline.trace_data[index],pipeline.trace_trap[index],SEED,MODE); $fatal(1);
  end endtask
  initial begin
    repeat(3) @(posedge clk); rst_n=1;
    for(i=0;i<4000 && (!reference.trap_valid || !pipeline.trap_valid);i=i+1) @(posedge clk);
    if(!reference.trap_valid || !pipeline.trap_valid) begin
      $display("DIFF timeout seed=%0d mode=%0d ref_trap=%0d pipe_trap=%0d ref_retire=%0d pipe_retire=%0d pipe_if=%0d pipe_dx=%0d pipe_mw=%0d req_v=%0d out_v=%0d ipend=%0d req=%h pcy=%0d pready=%0d pivalid=%0d",SEED,MODE,reference.trap_valid,pipeline.trap_valid,reference.trace_count,pipeline.trace_count,pipeline.g_pipe.dut.if_v,pipeline.g_pipe.dut.dx_v,pipeline.g_pipe.dut.mw_v,pipeline.g_pipe.dut.req_v,pipeline.g_pipe.dut.out_v,pipeline.ipend,pipeline.g_pipe.dut.req_addr,pipeline.cycles,pipeline.imem_req_ready,pipeline.imem_req_valid);
      $fatal(1);
    end
    @(posedge clk);
    if(reference.mepc!==pipeline.mepc || reference.mcause!==pipeline.mcause) fail("terminal",0);
    limit=(reference.trace_count<pipeline.trace_count)?reference.trace_count:pipeline.trace_count;
    for(i=0;i<limit;i=i+1) if(reference.trace_pc[i]!==pipeline.trace_pc[i] || reference.trace_ins[i]!==pipeline.trace_ins[i] || reference.trace_we[i]!==pipeline.trace_we[i] || reference.trace_rd[i]!==pipeline.trace_rd[i] || reference.trace_data[i]!==pipeline.trace_data[i] || reference.trace_trap[i]!==pipeline.trace_trap[i]) fail("retirement-trace",i);
    if(reference.trace_count!==pipeline.trace_count) begin $display("DIFF retirement counts ref=%0d pipe=%0d",reference.trace_count,pipeline.trace_count); fail("retirement-count",0); end
    if(reference.store_count!==pipeline.store_count) fail("store-count",0);
    for(i=0;i<reference.store_count;i=i+1) if(reference.store_addr[i]!==pipeline.store_addr[i] || reference.store_data[i]!==pipeline.store_data[i] || reference.store_strb[i]!==pipeline.store_strb[i]) fail("store-trace",i);
    for(i=0;i<32;i=i+1) if(reference.regs_snapshot[i]!==pipeline.regs_snapshot[i]) fail("final-register",i);
    for(i=0;i<256;i=i+1) if(reference.data_snapshot[i]!==pipeline.data_snapshot[i]) fail("final-memory",i);
    negative_detected=0;
    if(NEGATIVE!=0) begin if(reference.regs_snapshot[2] !== (pipeline.regs_snapshot[2]^32'h1)) negative_detected=1; if(!negative_detected) $fatal(1,"negative checker did not detect perturbation"); $display("DIFF NEGATIVE DETECTED seed=%0d injected=final-register-x2",SEED); end
    $display("DIFF PASS seed=%0d mode=%0d retire=%0d stores=%0d ref_cycles=%0d pipe_cycles=%0d negative=%0d",SEED,MODE,reference.trace_count,reference.store_count,reference.cycle_count,pipeline.cycle_count,negative_detected);
    $finish;
  end
endmodule
