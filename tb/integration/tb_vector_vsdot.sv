`timescale 1ns/1ps
// MODE: 0 patterns/directed, 1 command stall, 2 completion stall, 3 reset executing,
// 4 reset stalled completion, 5 redirect, 6/8 invalid metadata, 7 deterministic random.
module tb_vector_vsdot #(parameter integer MODE=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,eng_cmd_ready,vec_cpl_valid,vec_cpl_ready,eng_cpl_valid,eng_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we,dbg_vreg_write_valid,dbg_spad_we,dbg_spad_write_valid,dbg_vsdot_mul_exec_valid,dbg_vsdot_mul_skip_valid; logic [4:0] dbg_waddr,dbg_raddr,dbg_vreg_write_addr; logic [31:0] dbg_wdata,dbg_rdata,dbg_vreg_write_data,dbg_spad_addr,dbg_spad_wdata,dbg_spad_raddr,dbg_spad_rdata,dbg_spad_write_addr,dbg_spad_write_data;
  logic allow_cmd=1; logic [31:0] mem[0:511], v[0:31], want[0:191]; logic [4:0] want_rd[0:191]; integer i,cmds,cpls,retires,writes,vwrites,swrites,execs,skips,nwant,nspares,nwrites,seed,all_cmds,all_cpls,load_retires,exceptions,traps,sparse_vwrites,sparse_swrites,order_sparse_retires,order_dense_retires;
  assign vec_cmd_ready=eng_cmd_ready&&allow_cmd; assign eng_cpl_ready=vec_cpl_ready; assign vec_cpl_valid=eng_cpl_valid;
  rv32_core_pipe #(.VEC_CPL_READY_STALL((MODE==2||MODE==4)?5:0)) dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(.clk,.rst_n,.vec_cmd_valid(vec_cmd_valid&&allow_cmd),.vec_cmd_ready(eng_cmd_ready),.vec_cmd_op_class,.vec_cmd_funct,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_rs1_data,.vec_cmd_imm,.vec_cmd_id,.vec_cpl_ready(eng_cpl_ready),.vec_cpl_valid(eng_cpl_valid),.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),.dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data,.dbg_vsdot_mul_exec_valid,.dbg_vsdot_mul_skip_valid,.dbg_spad_we,.dbg_spad_addr,.dbg_spad_wdata,.dbg_spad_raddr,.dbg_spad_rdata,.dbg_spad_write_valid,.dbg_spad_write_addr,.dbg_spad_write_data);
  function automatic [31:0] vsdot(input integer pat,input integer rs2,input integer rs1,input integer rd); vsdot={pat[2:0],4'd0,rs2[4:0],rs1[4:0],3'd7,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] vdot(input integer rs2,input integer rs1,input integer rd); vdot={7'd0,rs2[4:0],rs1[4:0],3'd4,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] vload(input integer vd,input integer base,input integer imm); vload={imm[11:0],base[4:0],3'd5,vd[4:0],7'h0b}; endfunction
  function automatic [31:0] addi(input integer rd,input integer rs1,input integer imm); addi={imm[11:0],rs1[4:0],3'd0,rd[4:0],7'h13}; endfunction
  function automatic [31:0] jal(input integer off); jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],5'd0,7'h6f}; endfunction
  function automatic signed [31:0] sparse_model(input [31:0] a,input [31:0] w,input integer pat);
    integer lo,hi; reg signed [7:0] al,ah,wl,wh; reg signed [15:0] pl,ph;
    begin
      case(pat) 0:begin lo=0;hi=1;end 1:begin lo=0;hi=2;end 2:begin lo=0;hi=3;end 3:begin lo=1;hi=2;end 4:begin lo=1;hi=3;end default:begin lo=2;hi=3;end endcase
      al=$signed(a[lo*8 +:8]); ah=$signed(a[hi*8 +:8]); wl=$signed(w[7:0]); wh=$signed(w[15:8]); pl=al*wl; ph=ah*wh;
      sparse_model={{16{pl[15]}},pl}+{{16{ph[15]}},ph};
    end
  endfunction
  function automatic [31:0] dense_for(input [31:0] w,input integer pat); integer lo,hi; reg [31:0] d; begin case(pat) 0:begin lo=0;hi=1;end 1:begin lo=0;hi=2;end 2:begin lo=0;hi=3;end 3:begin lo=1;hi=2;end 4:begin lo=1;hi=3;end default:begin lo=2;hi=3;end endcase d=0;d[lo*8 +:8]=w[7:0];d[hi*8 +:8]=w[15:8];dense_for=d;end endfunction
  function automatic signed [31:0] dense_model(input [31:0] a,input [31:0] b); integer k; reg signed [7:0] x,y; reg signed [15:0] p; reg signed [31:0] s; begin s=0;for(k=0;k<4;k=k+1) begin x=$signed(a[k*8+:8]);y=$signed(b[k*8+:8]);p=x*y;s=s+{{16{p[15]}},p};end dense_model=s;end endfunction
  task automatic initv(input integer n,input [31:0] x); begin @(negedge clk);dbg_waddr=n;dbg_wdata=x;dbg_we=1;@(posedge clk);@(negedge clk);dbg_we=0;v[n]=x;end endtask
  task automatic initm(input integer n,input [31:0] x); begin @(negedge clk);dbg_spad_addr=n*4;dbg_spad_wdata=x;dbg_spad_we=1;@(posedge clk);@(negedge clk);dbg_spad_we=0;end endtask
  task automatic emit_sparse(input integer slot,input integer rd,input integer va,input integer vw,input integer pat); reg signed [31:0] s,d; begin s=sparse_model(v[va],v[vw],pat);d=dense_model(v[va],dense_for(v[vw],pat));if(s!==d)$fatal(1,"sparse/dense golden mismatch pat=%0d",pat);mem[slot]=vsdot(pat,vw,va,rd);want[nwant]=s;want_rd[nwant]=rd;nwant=nwant+1;nspares=nspares+1;if(rd!=0)nwrites=nwrites+1;end endtask
  task automatic emit_dense(input integer slot,input integer rd,input integer va,input integer vd); begin mem[slot]=vdot(vd,va,rd);want[nwant]=dense_model(v[va],v[vd]);want_rd[nwant]=rd;nwant=nwant+1;end endtask
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;cmds<=0;cpls<=0;retires<=0;writes<=0;vwrites<=0;swrites<=0;execs<=0;skips<=0;all_cmds<=0;all_cpls<=0;load_retires<=0;exceptions<=0;traps<=0;sparse_vwrites<=0;sparse_swrites<=0;order_sparse_retires<=0;order_dense_retires<=0;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[10:2]];end
      if(vec_cmd_valid&&vec_cmd_ready) all_cmds<=all_cmds+1;
      if(vec_cmd_valid&&vec_cmd_ready&&vec_cmd_op_class==7) begin cmds<=cmds+1;if(!vec_cmd_rd_we||vec_cmd_funct[4:1]!==0)$fatal(1,"bad VSDOT command metadata");end
      if(vec_cpl_valid&&vec_cpl_ready) all_cpls<=all_cpls+1;
      if(vec_cpl_valid&&vec_cpl_ready&&dut.vec_ins_q[14:12]==7) begin cpls<=cpls+1;if(vec_cpl_status!=0)exceptions<=exceptions+1;end
      if(dbg_vsdot_mul_exec_valid) execs<=execs+2;
      if(dbg_vsdot_mul_skip_valid) skips<=skips+2;
      if(dbg_vreg_write_valid) begin vwrites<=vwrites+1;if(dut.vec_ins_q[14:12]==7)sparse_vwrites<=sparse_vwrites+1;end
      if(dbg_spad_write_valid) begin swrites<=swrites+1;if(dut.vec_ins_q[14:12]==7)sparse_swrites<=sparse_swrites+1;end
      if(retire_trap) traps<=traps+1;
      if(retire_valid&&!retire_trap&&retire_instr[6:0]==7'h0b&&retire_instr[14:12]==5)load_retires<=load_retires+1;
      if(retire_valid&&!retire_trap&&retire_instr[6:0]==7'h0b&&(retire_instr[14:12]==4||retire_instr[14:12]==7)) begin
        if(retires>=nwant||retire_rd!==want_rd[retires]||retire_rd_data!==want[retires])$fatal(1,"dot retirement mismatch %0d rd=%0d/%0d data=%h/%h",retires,retire_rd,want_rd[retires],retire_rd_data,want[retires]);
        if(retire_instr[14:12]==7&&((retire_rd==0&&retire_rd_we)||(retire_rd!=0&&!retire_rd_we)))$fatal(1,"VSDOT scalar write intent");
        retires<=retires+1;if(retire_instr[14:12]==7&&retire_rd_we)writes<=writes+1;
        if(MODE==0&&retire_pc==32'd108&&retire_instr[14:12]==7)order_sparse_retires<=order_sparse_retires+1;
        if(MODE==0&&retire_pc==32'd112&&retire_instr[14:12]==4)begin if(!order_sparse_retires)$fatal(1,"sparse-to-dense retirement order");order_dense_retires<=order_dense_retires+1;end
      end
    end
  end
  initial begin
    imem_req_ready=0; for(i=0;i<512;i=i+1) mem[i]=32'h00000013; dbg_we=0;dbg_waddr=0;dbg_wdata=0;dbg_raddr=0;dbg_spad_we=0;dbg_spad_addr=0;dbg_spad_wdata=0;dbg_spad_raddr=0;nwant=0;nspares=0;nwrites=0;
    repeat(3)@(posedge clk);rst_n=1;
    initv(0,32'h807f0201); initv(1,32'hdeadfb04); // compressed weights 4, -5; upper bits ignored
    for(i=0;i<6;i=i+1) begin initv(2+i,dense_for(v[1],i)); emit_dense(10+i*2,10+i,0,2+i); emit_sparse(11+i*2,20+i,0,1,i); end
    // Signed extremes, cancellation, same source index, v31, x0, and immediate dependency.
    initv(8,32'h80807f7f); initv(9,32'h00008080); initv(31,32'h80ff7f01); initv(30,32'h0000ff80);
    emit_sparse(22,5,8,9,0); mem[23]=addi(6,5,1); emit_sparse(24,0,0,1,5); emit_sparse(25,7,31,30,4); emit_sparse(26,8,1,1,3);
    // Explicit sparse-to-dense pair: no vector instruction separates slots 27 and 28.
    emit_sparse(27,9,0,1,2); initv(10,dense_for(v[1],2)); emit_dense(28,11,0,10); if(want[16]!==want[17])$fatal(1,"sparse-to-dense result mismatch");
    // Both sparse operands below come from scratchpad VLOAD32, never debug vreg injection.
    initm(8,32'h807f0201); initm(9,32'hbeeffb04); v[12]=32'h807f0201; v[13]=32'hbeeffb04;
    mem[29]=addi(1,0,32); mem[30]=vload(12,1,0); mem[31]=addi(2,0,36); mem[32]=vload(13,2,0); emit_sparse(33,14,12,13,4); mem[34]=32'h00000073;
    if(MODE==7) begin
      seed=32'h5a17c0de;nwant=0;nspares=0;nwrites=0;
      for(i=0;i<32;i=i+1) begin seed=seed*1103515245+12345; initv(i,seed); end
      for(i=0;i<96;i=i+1) begin seed=seed*1103515245+12345; emit_sparse(10+i,(seed>>16)&31,(seed>>21)&31,(seed>>11)&31,(seed>>8)%6); end
      mem[106]=32'h00000073;
    end
    if(MODE==5) begin nwant=0;nspares=0;nwrites=0;mem[10]=jal(8);mem[11]=vsdot(0,1,0,5);emit_sparse(12,6,0,1,1);mem[13]=32'h00000073;end
    if(MODE==6||MODE==8) begin nwant=0;nspares=0;nwrites=0;mem[10]=vsdot((MODE==6)?6:7,1,0,5);mem[11]=32'h00000073;end
    imem_req_ready=1;
    if(MODE==1) begin allow_cmd=0;while(!vec_cmd_valid)@(posedge clk);repeat(4)begin @(posedge clk);if(!vec_cmd_valid||cmds!=0)$fatal(1,"VSDOT command backpressure");end allow_cmd=1;end
    if(MODE==3) begin while(cmds==0)@(posedge clk);@(posedge clk);rst_n=0;@(posedge clk);#1;if(eng_cpl_valid||retires||writes||execs||skips)$fatal(1,"VSDOT execution reset effects");repeat(2)@(posedge clk);rst_n=1; nwant=0;nspares=0;nwrites=0;emit_sparse(10,5,0,1,0);mem[11]=32'h00000073;end
    if(MODE==4) begin while(!eng_cpl_valid)@(posedge clk);if(vec_cpl_ready)$fatal(1,"expected stalled completion");rst_n=0;@(posedge clk);#1;if(eng_cpl_valid||retires||writes||execs||skips)$fatal(1,"VSDOT stalled completion reset effects");repeat(2)@(posedge clk);rst_n=1;nwant=0;nspares=0;nwrites=0;emit_sparse(10,5,0,1,0);mem[11]=32'h00000073;end
    repeat(6000) begin @(posedge clk);
      if(trap_valid) begin
        @(posedge clk);
        if(MODE==6||MODE==8) begin if(mcause!=18||mepc!=32'd40||cmds!=1||cpls!=1||exceptions!=1||traps!=1||retires||writes||execs||skips||vwrites||swrites||sparse_vwrites||sparse_swrites)$fatal(1,"invalid VSDOT metadata effects");end
        else begin if(cmds!=nspares||retires!=nwant||cpls!=cmds||writes!=nwrites||execs!=2*cmds||skips!=2*cmds||sparse_vwrites||sparse_swrites)$fatal(1,"VSDOT events c=%0d cp=%0d r=%0d w=%0d e=%0d s=%0d",cmds,cpls,retires,writes,execs,skips); if(MODE==0&&dut.rf.regs[6]!==want[12]+1)$fatal(1,"VSDOT dependency"); if(MODE==0&&(all_cmds!=21||all_cpls!=21||load_retires!=2||vwrites!=2||order_sparse_retires!=1||order_dense_retires!=1))$fatal(1,"load/order events ac=%0d ap=%0d lr=%0d vw=%0d sr=%0d dr=%0d",all_cmds,all_cpls,load_retires,vwrites,order_sparse_retires,order_dense_retires);end
        $display("VSDOT mode=%0d cmds=%0d cpls=%0d retires=%0d writes=%0d exec=%0d skip=%0d all_cmds=%0d all_cpls=%0d loads=%0d vwrites=%0d exceptions=%0d traps=%0d",MODE,cmds,cpls,retires,writes,execs,skips,all_cmds,all_cpls,load_retires,vwrites,exceptions,traps);$finish;
      end
    end
    $fatal(1,"VSDOT timeout mode=%0d",MODE);
  end
endmodule
