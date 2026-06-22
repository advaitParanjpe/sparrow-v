`timescale 1ns/1ps
// MODE 0 directed/dependency, 1 command stall, 2 completion stall, 3 reset,
// 4 deterministic random, 5 illegal encoding, 6 wrong-path suppression.
module tb_vector_vdot #(parameter integer MODE=0);
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data=0; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,eng_cmd_ready,vec_cpl_valid,vec_cpl_ready,eng_cpl_valid,eng_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we,dbg_vreg_write_valid; logic [4:0] dbg_waddr,dbg_raddr,dbg_vreg_write_addr; logic [31:0] dbg_wdata,dbg_rdata,dbg_vreg_write_data,expected_v[0:31],expected_result[0:63]; logic [4:0] expected_rd[0:63];
  logic allow_cmd=1; logic [31:0] mem[0:255]; integer i,cmds,cpls,retires,scalar_writes,vreg_writes,expected_ops,expected_scalar_writes,random_state;
  assign vec_cmd_ready=eng_cmd_ready&&allow_cmd; assign eng_cpl_ready=vec_cpl_ready; assign vec_cpl_valid=eng_cpl_valid;
  rv32_core_pipe #(.VEC_CPL_READY_STALL(MODE==2?5:0)) dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(.clk,.rst_n,.vec_cmd_valid(vec_cmd_valid&&allow_cmd),.vec_cmd_ready(eng_cmd_ready),.vec_cmd_op_class,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_id,.vec_cpl_ready(eng_cpl_ready),.vec_cpl_valid(eng_cpl_valid),.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),.dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data);
  function automatic [31:0] vdot(input integer rs2,input integer rs1,input integer rd); vdot={7'h00,rs2[4:0],rs1[4:0],3'd4,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] bad(input integer rs2,input integer rs1,input integer rd); bad={7'h00,rs2[4:0],rs1[4:0],3'd5,rd[4:0],7'h0b}; endfunction
  function automatic [31:0] addi(input integer rd,input integer rs1,input integer imm); addi={imm[11:0],rs1[4:0],3'd0,rd[4:0],7'h13}; endfunction
  function automatic [31:0] jal(input integer off); jal={{11{off[20]}},off[20],off[10:1],off[11],off[19:12],5'd0,7'h6f}; endfunction
  function automatic signed [31:0] model_dot(input [31:0] a,input [31:0] b);
    integer k; reg signed [7:0] av,bv; reg signed [15:0] p; reg signed [31:0] sum;
    begin sum=0; for(k=0;k<4;k=k+1) begin av=$signed(a[k*8 +:8]); bv=$signed(b[k*8 +:8]); p=av*bv; sum=sum+{{16{p[15]}},p}; end model_dot=sum; end
  endfunction
  task automatic init_reg(input integer n,input [31:0] value); begin @(negedge clk);dbg_waddr=n;dbg_wdata=value;dbg_we=1;@(posedge clk);@(negedge clk);dbg_we=0;expected_v[n]=value;end endtask
  task automatic random_init_reg(input integer n); reg [31:0] value; integer lane; begin
    value=0;
    for(lane=0;lane<4;lane=lane+1) begin
      random_state=random_state*1103515245+12345;
      // Deterministic extreme coverage is interleaved with arbitrary INT8 lanes.
      case((n*4+lane)%8)
        0: value[lane*8 +:8]=8'h80;
        1: value[lane*8 +:8]=8'h7f;
        2: value[lane*8 +:8]=8'hff;
        3: value[lane*8 +:8]=8'h00;
        4: value[lane*8 +:8]=8'h01;
        default: value[lane*8 +:8]=(random_state>>16)&8'hff;
      endcase
    end
    init_reg(n,value);
  end endtask
  task automatic emit(input integer rd,input integer rs1,input integer rs2,input integer slot); begin mem[slot]=vdot(rs2,rs1,rd);expected_rd[expected_ops]=rd[4:0];expected_result[expected_ops]=model_dot(expected_v[rs1],expected_v[rs2]);expected_ops=expected_ops+1;if(rd!=0) expected_scalar_writes=expected_scalar_writes+1;end endtask
  task automatic check_vregs; integer n; begin for(n=0;n<32;n=n+1) begin dbg_raddr=n;#1;if(dbg_rdata!==expected_v[n]) $fatal(1,"VDOT changed v%0d got=%h want=%h",n,dbg_rdata,expected_v[n]);end end endtask
  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0;cmds<=0;cpls<=0;retires<=0;scalar_writes<=0;vreg_writes<=0;end else begin
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1;imem_resp_data<=mem[imem_req_addr[9:2]];end
      if(vec_cmd_valid&&vec_cmd_ready) begin cmds<=cmds+1;if(vec_cmd_rd_we!==1 || vec_cmd_op_class!=4) $fatal(1,"bad VDOT command metadata");end
      if(vec_cpl_valid&&vec_cpl_ready) begin cpls<=cpls+1;if(!vec_cpl_result_valid||vec_cpl_status!=0) $fatal(1,"bad VDOT completion");end
      if(dbg_vreg_write_valid) begin vreg_writes<=vreg_writes+1;$fatal(1,"VDOT vector write");end
      if(retire_valid&&!retire_trap&&retire_instr[6:0]==7'h0b&&retire_instr[14:12]==4) begin
        if(retires>=expected_ops || retire_rd!==expected_rd[retires] || retire_rd_data!==expected_result[retires]) $fatal(1,"VDOT retirement mismatch");
        if((retire_rd==0&&retire_rd_we)||(retire_rd!=0&&!retire_rd_we)) $fatal(1,"VDOT scalar write intent mismatch");
        retires<=retires+1; if(retire_rd_we) scalar_writes<=scalar_writes+1;
      end
    end
  end
  initial begin
    for(i=0;i<256;i=i+1) mem[i]=32'h00000013;
    dbg_we=0;dbg_waddr=0;dbg_wdata=0;dbg_raddr=0;expected_ops=0;expected_scalar_writes=0;
    repeat(3) @(posedge clk);rst_n=1;
    for(i=0;i<32;i=i+1) init_reg(i,32'h10203040^(i*32'h01010101));
    // Required named signed cases, lane 0 in bits [7:0].
    init_reg(0,32'h04030201); init_reg(1,32'h08070605); // 70
    init_reg(2,32'h7f7f7f7f); init_reg(3,32'h7f7f7f7f); // 64516
    init_reg(4,32'h80808080); init_reg(5,32'h80808080); // 65536
    init_reg(6,32'hfe02ff01); init_reg(7,32'h03030404); // 0
    init_reg(31,32'h80ff7f01); init_reg(30,32'hff027f80);
    // The first scalar consumer is immediately after its VDOT8 producer.
    emit(5,0,1,10); mem[11]=addi(10,5,1);
    emit(6,2,3,12); emit(7,4,5,13); emit(8,6,7,14); emit(9,31,30,15);
    emit(0,0,1,16); emit(11,1,1,17); // Explicit vs1 == vs2; 5^2+6^2+7^2+8^2 = 174.
    if(expected_result[expected_ops-1]!==32'd174) $fatal(1,"VDOT source-alias golden result");
    mem[18]=32'h00000073;
    if(MODE==4) begin
      random_state=32'h2468ace1;
      for(i=0;i<32;i=i+1) random_init_reg(i);
      expected_ops=0;expected_scalar_writes=0;
      for(i=0;i<32;i=i+1) begin
        random_state=random_state*1103515245+12345;
        emit((random_state>>16)&31,(random_state>>21)&31,(random_state>>11)&31,10+i);
      end
      mem[42]=32'h00000073;
    end
    if(MODE==5) begin expected_ops=0;expected_scalar_writes=0;mem[10]=bad(1,0,5);mem[11]=32'h00000073;end
    if(MODE==6) begin expected_ops=0;expected_scalar_writes=0;mem[10]=jal(8);mem[11]=vdot(1,0,5);emit(6,0,1,12);mem[13]=32'h00000073;end
    if(MODE==1) begin allow_cmd=0;while(!vec_cmd_valid) @(posedge clk);repeat(4) begin @(posedge clk);if(!vec_cmd_valid||cmds!=0) $fatal(1,"VDOT command backpressure");end allow_cmd=1;end
    if(MODE==3) begin while(cmds==0) @(posedge clk);@(posedge clk);rst_n=0;@(posedge clk);if(eng_cpl_valid||retires||scalar_writes||vreg_writes) $fatal(1,"VDOT reset cancellation");repeat(2) @(posedge clk);rst_n=1;end
    repeat(1000) begin @(posedge clk);
      if(MODE==2&&cpls==0&&eng_cpl_valid&&!vec_cpl_ready&&vec_cpl_result_data!==expected_result[0]) $fatal(1,"VDOT completion changed before handshake");
      if(trap_valid) begin @(posedge clk);check_vregs;
        if(MODE==5) begin if(mcause!=2||cmds||cpls||retires||scalar_writes||vreg_writes) $fatal(1,"illegal VDOT accounting");end
        else begin if(cmds!=expected_ops||cpls!=expected_ops||retires!=expected_ops||scalar_writes!=expected_scalar_writes||vreg_writes!=0) $fatal(1,"VDOT events cmds=%0d cpls=%0d retires=%0d scalar=%0d vwrite=%0d",cmds,cpls,retires,scalar_writes,vreg_writes); if(dut.rf.regs[10]!==32'd71&&MODE==0) $fatal(1,"dependent ADDI failed");end
        $display("VDOT mode=%0d cmds=%0d cpls=%0d retires=%0d scalar_writes=%0d",MODE,cmds,cpls,retires,scalar_writes);$finish;
      end
    end
    $fatal(1,"VDOT timeout mode=%0d",MODE);
  end
endmodule
