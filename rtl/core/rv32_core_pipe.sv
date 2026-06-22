// Development-only scalar pipeline.  rv32_core.sv remains the production core.
module rv32_core_pipe #(
  parameter logic [31:0] RESET_PC=0,
  parameter logic [31:0] MTVEC_RESET=32'h100,
  // Default production-experiment behavior accepts a completion immediately.
  // The focused adapter test uses a finite delay to exercise valid/ready hold.
  parameter integer VEC_CPL_READY_STALL=0
) (
 input logic clk,rst_n,output logic imem_req_valid,input logic imem_req_ready,output logic [31:0] imem_req_addr,input logic imem_resp_valid,output logic imem_resp_ready,input logic [31:0] imem_resp_data,
 output logic dmem_req_valid,input logic dmem_req_ready,output logic dmem_req_write,output logic [31:0] dmem_req_addr,dmem_req_wdata,output logic [3:0] dmem_req_wstrb,input logic dmem_resp_valid,output logic dmem_resp_ready,input logic [31:0] dmem_resp_data,
 output logic trap_valid,output logic [31:0] mepc,mcause,mtvec,output logic [63:0] cycle_count,instret_count,
 output logic retire_valid,output logic [31:0] retire_pc,retire_instr,output logic retire_rd_we,output logic [4:0] retire_rd,output logic [31:0] retire_rd_data,output logic retire_mem_we,output logic [31:0] retire_mem_addr,retire_mem_data,output logic [3:0] retire_mem_wstrb,output logic retire_trap,output logic [31:0] retire_cause,output logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles,
 // Experimental, unfrozen scalar-to-vector boundary.  rv32_core is unchanged.
 output logic vec_cmd_valid,input logic vec_cmd_ready,output logic [3:0] vec_cmd_op_class,output logic [7:0] vec_cmd_funct,output logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,output logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,output logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,output logic [4:0] vec_cmd_rd,output logic vec_cmd_rd_we,output logic [31:0] vec_cmd_imm,vec_cmd_pc,output logic vec_cmd_id,
 input logic vec_cpl_valid,output logic vec_cpl_ready,input logic vec_cpl_id,input logic [1:0] vec_cpl_status,input logic vec_cpl_result_valid,input logic [31:0] vec_cpl_result_data,vec_cpl_exception_cause
);
  import sparrowv_scalar_pkg::*;
  logic [31:0] req_addr,out_addr,if_pc,if_ins; logic req_v,out_v,if_v,dx_v,mw_v;
  logic [1:0] fetch_gen,req_gen,out_gen; logic redirect_pending; logic [31:0] pending_target;
  // Exposed development monitors (hierarchical testbench access).
  logic [63:0] taken_branch_redirects,non_taken_branches,wrong_path_fetches,stale_responses;
  logic [31:0] dx_pc,dx_ins,dx_src1,dx_src2,dx_imm; logic [4:0] dx_rs1,dx_rs2,dx_rd;
  logic dx_uses_rs1,dx_uses_rs2,dx_use_imm,dx_reg_write,dx_lui,dx_auipc,dx_ecall,dx_illegal,dx_branch,dx_branch_unsigned,dx_jal,dx_jalr,dx_mem,dx_store,dx_load_unsigned; logic [1:0] dx_branch_kind; alu_op_t dx_alu_op; mem_size_t dx_mem_size;
  logic [31:0] mw_pc,mw_ins,mw_y,mw_cause,mw_addr,mw_wdata,mw_store_data; logic [4:0] mw_rd; logic [3:0] mw_wstrb; logic mw_we,mw_terminal,mw_illegal,mw_mem,mw_store,mw_load_unsigned; mem_size_t mw_mem_size; logic [1:0] mw_mem_state;
  logic if_legal,if_reg_write,if_use_imm,if_ecall,if_ebreak,if_load_unsigned,if_branch,if_branch_unsigned,if_jal,if_jalr;
  logic [1:0] if_result_sel,if_branch_kind; alu_op_t if_alu_op; mem_op_t if_mem_op; mem_size_t if_mem_size;
  logic [31:0] if_imm,rf_rs1,rf_rs2,if_src1_capture,if_src2_capture;
  logic if_lui,if_auipc,if_opimm,if_op,if_supported,if_uses_rs1,if_uses_rs2,if_illegal,if_vec;
  logic [31:0] dx_a,dx_b,dx_alu_y,dx_y,dx_target; logic dx_branch_taken,dx_redirect,dx_misaligned,dx_terminal; logic [31:0] dx_cause;
  logic mw_ready,mw_complete,dx_ready,if_to_dx,dx_to_mw,mw_retire,req_fire,resp_fire,dx_mem_misaligned,dmem_req_fire,dmem_resp_fire; logic [31:0] dx_mem_addr,dx_store_data,dx_store_wdata,load_data;
  logic [3:0] dx_store_wstrb;
  logic [63:0] load_instructions,store_instructions,load_response_wait_cycles,load_use_stall_cycles,misaligned_memory_ops;
  logic dx_vec,vec_outstanding,vec_cmd_fire,vec_cpl_fire,vec_payload_valid;
  integer vec_cpl_stall_count;
  logic [2:0] dx_vec_funct3;
  logic [31:0] vec_pc_q,vec_ins_q,vec_cmd_rs1_q,vec_cmd_rs2_q;
  logic [4:0] vec_rd_q;
  logic vec_rd_we_q;
  logic cmd_hold,cpl_hold;
  logic [3:0] cmd_op_class_q; logic [7:0] cmd_funct_q; logic [4:0] cmd_vs1_q,cmd_vs2_q,cmd_vd_q,cmd_rd_q;
  logic [31:0] cmd_rs1_q,cmd_rs2_q,cmd_imm_q,cmd_pc_q;
  logic cmd_rs1_valid_q,cmd_rs2_valid_q,cmd_rd_we_q,cmd_id_q;
  logic cpl_id_q; logic [1:0] cpl_status_q; logic cpl_result_valid_q; logic [31:0] cpl_result_data_q,cpl_cause_q;

  rv32_decoder decoder(.instr(if_ins),.legal(if_legal),.reg_write(if_reg_write),.use_imm(if_use_imm),.result_sel(if_result_sel),.alu_op(if_alu_op),.mem_op(if_mem_op),.mem_size(if_mem_size),.load_unsigned(if_load_unsigned),.branch(if_branch),.branch_unsigned(if_branch_unsigned),.branch_kind(if_branch_kind),.jal(if_jal),.jalr(if_jalr),.ecall(if_ecall),.ebreak(if_ebreak));
  rv32_immediate immediate(.instr(if_ins),.imm(if_imm));
  rv32_regfile rf(.clk(clk),.rst_n(rst_n),.rs1_addr(if_ins[19:15]),.rs2_addr(if_ins[24:20]),.rs1_data(rf_rs1),.rs2_data(rf_rs2),.we(mw_retire&&mw_we&&!mw_terminal),.rd_addr(mw_rd),.rd_data(mw_y));
  rv32_alu alu(.op(dx_alu_op),.a(dx_a),.b(dx_b),.y(dx_alu_y));
  assign if_lui=if_ins[6:0]==7'h37; assign if_auipc=if_ins[6:0]==7'h17; assign if_opimm=if_ins[6:0]==7'h13; assign if_op=if_ins[6:0]==7'h33;
  // Custom-0 experimental forms: 000=result stub, 001=vector-only stub,
  // 010=exception stub, 011=VADD8 vector-only operation, 100=VDOT8.
  assign if_vec=(if_ins[6:0]==7'h0b)&&((if_ins[14:12]==3'd0)||(if_ins[14:12]==3'd1)||(if_ins[14:12]==3'd2)||(if_ins[14:12]==3'd3)||(if_ins[14:12]==3'd4));
  assign if_supported=if_lui||if_auipc||if_opimm||if_op||if_branch||if_jal||if_jalr||if_ecall||(if_mem_op!=MEM_NONE)||(if_result_sel==2'd1)||if_vec;
  assign if_uses_rs1=if_opimm||if_op||if_branch||if_jalr||(if_mem_op!=MEM_NONE)||if_vec; assign if_uses_rs2=if_op||if_branch||(if_mem_op==MEM_STORE)||if_vec;
  assign if_illegal=(!if_legal||!if_supported||if_ebreak)&&!if_vec;
  assign if_src1_capture=(mw_retire&&mw_we&&!mw_terminal&&mw_rd!=0&&mw_rd==if_ins[19:15])?mw_y:rf_rs1;
  assign if_src2_capture=(mw_retire&&mw_we&&!mw_terminal&&mw_rd!=0&&mw_rd==if_ins[24:20])?mw_y:rf_rs2;
  assign dx_a=(dx_uses_rs1&&mw_v&&mw_we&&!mw_terminal&&mw_rd!=0&&mw_rd==dx_rs1)?mw_y:dx_src1;
  assign dx_b=dx_use_imm?dx_imm:((dx_uses_rs2&&mw_v&&mw_we&&!mw_terminal&&mw_rd!=0&&mw_rd==dx_rs2)?mw_y:dx_src2);
  always_comb begin
    unique case(dx_branch_kind)
      0: dx_branch_taken=(dx_a==dx_b); 1: dx_branch_taken=(dx_a!=dx_b);
      2: dx_branch_taken=dx_branch_unsigned?(dx_a<dx_b):($signed(dx_a)<$signed(dx_b));
      default: dx_branch_taken=dx_branch_unsigned?(dx_a>=dx_b):($signed(dx_a)>=$signed(dx_b));
    endcase
    if(dx_jalr) dx_target=(dx_a+dx_imm)&32'hffff_fffe; else dx_target=dx_pc+dx_imm;
    dx_mem_addr=dx_a+dx_imm; dx_store_data=(dx_uses_rs2&&mw_v&&mw_we&&!mw_terminal&&mw_rd!=0&&mw_rd==dx_rs2)?mw_y:dx_src2;
    dx_store_wdata=32'd0; dx_store_wstrb=0;
    case(dx_mem_size) SZ_BYTE: begin dx_store_wdata=dx_store_data<<(8*dx_mem_addr[1:0]);dx_store_wstrb=4'b0001<<dx_mem_addr[1:0];end SZ_HALF: begin dx_store_wdata=dx_store_data<<(16*dx_mem_addr[1]);dx_store_wstrb=dx_mem_addr[1]?4'b1100:4'b0011;end default: begin dx_store_wdata=dx_store_data;dx_store_wstrb=4'b1111;end endcase
    dx_mem_misaligned=dx_mem&&((dx_mem_size==SZ_HALF&&dx_mem_addr[0])||(dx_mem_size==SZ_WORD&&|dx_mem_addr[1:0]));
    dx_misaligned=((dx_branch||dx_jal||dx_jalr)&&(|dx_target[1:0]))||dx_mem_misaligned;
    // A held DX control instruction may not redirect repeatedly while an older
    // memory operation blocks MW.  Redirect only on the DX-to-MW transfer.
    dx_redirect=dx_v&&mw_ready&&!dx_illegal&&!dx_misaligned&&(dx_jal||dx_jalr||(dx_branch&&dx_branch_taken));
    dx_terminal=dx_ecall||dx_illegal||dx_misaligned;
    if(dx_mem_misaligned) dx_cause=dx_store?32'd6:32'd4;
    else if(dx_misaligned) dx_cause=32'd0;
    else dx_cause=dx_illegal?32'd2:32'd11;
    if(dx_lui) dx_y=dx_imm; else if(dx_auipc) dx_y=dx_pc+dx_imm; else if(dx_jal||dx_jalr) dx_y=dx_pc+4; else dx_y=dx_alu_y;
  end
  // A terminal MW entry is the architectural end of execution.  It must not
  // admit the younger IF/DX entries in the same cycle that it traps.
  assign mw_complete=mw_v&&(!mw_mem||mw_mem_state==2); assign mw_ready=!mw_v||mw_complete; assign dx_ready=mw_ready&&!vec_outstanding; assign if_to_dx=if_v&&dx_ready&&!dx_redirect&&!mw_terminal&&!trap_valid&&!(dx_v&&dx_vec)&&!vec_cpl_fire; assign dx_to_mw=dx_v&&!dx_vec&&mw_ready&&!mw_terminal&&!trap_valid; assign mw_retire=mw_complete;
  assign vec_cmd_valid=dx_v&&dx_vec&&vec_payload_valid&&!vec_outstanding&&mw_ready&&!trap_valid;
  assign vec_cmd_op_class={1'b0,dx_vec_funct3}; assign vec_cmd_funct=dx_ins[31:24]; assign vec_cmd_vs1=dx_rs1; assign vec_cmd_vs2=dx_rs2; assign vec_cmd_vd=dx_rd;
  // Operand values were captured at IF/DX admission with same-edge MW bypass.
  // Do not recompute them while command-ready applies backpressure.
  assign vec_cmd_rs1_data=vec_cmd_rs1_q; assign vec_cmd_rs2_data=vec_cmd_rs2_q;
  assign vec_cmd_rs1_valid=1'b1; assign vec_cmd_rs2_valid=1'b1; assign vec_cmd_rd=dx_rd; assign vec_cmd_rd_we=(dx_vec_funct3==3'd0)||(dx_vec_funct3==3'd4); assign vec_cmd_imm={{20{dx_ins[31]}},dx_ins[31:20]}; assign vec_cmd_pc=dx_pc; assign vec_cmd_id=1'b0;
  assign vec_cmd_fire=vec_cmd_valid&&vec_cmd_ready;
  assign vec_cpl_ready=vec_outstanding&&!mw_v&&!trap_valid&&(vec_cpl_stall_count>=VEC_CPL_READY_STALL);
  assign vec_cpl_fire=vec_cpl_valid&&vec_cpl_ready;
  assign imem_req_valid=req_v&&(!out_v||(imem_resp_valid&&imem_resp_ready))&&!mw_terminal&&!trap_valid&&!vec_outstanding; assign imem_req_addr=req_addr; assign req_fire=imem_req_valid&&imem_req_ready;
  // A response is always consumed when stale; only a current-generation response may occupy IF.
  assign imem_resp_ready=out_v&&!vec_outstanding&&((out_gen!=fetch_gen)||dx_redirect||!if_v||if_to_dx); assign resp_fire=imem_resp_valid&&imem_resp_ready;
  assign dmem_req_valid=mw_v&&mw_mem&&mw_mem_state==0; assign dmem_req_write=mw_store; assign dmem_req_addr={mw_addr[31:2],2'b00}; assign dmem_req_wdata=mw_wdata; assign dmem_req_wstrb=mw_wstrb; assign dmem_resp_ready=mw_v&&mw_mem&&mw_mem_state==1; assign dmem_req_fire=dmem_req_valid&&dmem_req_ready;assign dmem_resp_fire=dmem_resp_valid&&dmem_resp_ready;
  always_comb begin case(mw_mem_size) SZ_BYTE: load_data=mw_load_unsigned?{24'd0,dmem_resp_data[8*mw_addr[1:0]+:8]}:{{24{dmem_resp_data[8*mw_addr[1:0]+7]}},dmem_resp_data[8*mw_addr[1:0]+:8]}; SZ_HALF: load_data=mw_load_unsigned?{16'd0,dmem_resp_data[16*mw_addr[1]+:16]}:{{16{dmem_resp_data[16*mw_addr[1]+15]}},dmem_resp_data[16*mw_addr[1]+:16]}; default: load_data=dmem_resp_data; endcase end

  always_ff @(posedge clk) begin
    if(!rst_n) begin
      req_addr<=RESET_PC; req_gen<=0; req_v<=1; out_v<=0; if_v<=0; dx_v<=0; mw_v<=0; fetch_gen<=0; redirect_pending<=0; pending_target<=0; vec_outstanding<=0; vec_payload_valid<=0; vec_pc_q<=0; vec_ins_q<=0; vec_cmd_rs1_q<=0; vec_cmd_rs2_q<=0; vec_rd_q<=0; vec_rd_we_q<=0; cmd_hold<=0; cpl_hold<=0; vec_cpl_stall_count<=0;
      mw_we<=0; mw_terminal<=0; mw_illegal<=0; mw_rd<=0; mw_y<=0; mw_cause<=0; mw_mem<=0;mw_store<=0;mw_mem_state<=0;mw_addr<=0;mw_wdata<=0;mw_store_data<=0;mw_wstrb<=0; trap_valid<=0; mepc<=0; mcause<=0; mtvec<=MTVEC_RESET; cycle_count<=0; instret_count<=0;
      retire_valid<=0; retire_trap<=0; retire_rd_we<=0; retire_mem_we<=0; retire_pc<=0; retire_instr<=0; retire_rd<=0; retire_rd_data<=0; retire_mem_addr<=0; retire_mem_data<=0; retire_mem_wstrb<=0; retire_cause<=0;
      imem_stall_cycles<=0; dmem_stall_cycles<=0; dep_stall_cycles<=0; control_flush_cycles<=0; taken_branch_redirects<=0; non_taken_branches<=0; wrong_path_fetches<=0; stale_responses<=0;load_instructions<=0;store_instructions<=0;load_response_wait_cycles<=0;load_use_stall_cycles<=0;misaligned_memory_ops<=0;
    end else begin
      cycle_count<=cycle_count+1; retire_valid<=0; retire_trap<=0; retire_rd_we<=0; retire_mem_we<=0;
      if(imem_req_valid&&!imem_req_ready) imem_stall_cycles<=imem_stall_cycles+1;
      if(dmem_req_valid&&!dmem_req_ready) dmem_stall_cycles<=dmem_stall_cycles+1;
      if(mw_v&&mw_mem&&!mw_store&&mw_mem_state==1&&!dmem_resp_fire) load_response_wait_cycles<=load_response_wait_cycles+1;
      if(mw_v&&mw_mem&&!mw_complete&&dx_v&&((dx_uses_rs1&&dx_rs1==mw_rd)||(dx_uses_rs2&&dx_rs2==mw_rd))&&mw_rd!=0) load_use_stall_cycles<=load_use_stall_cycles+1;
      if(dmem_req_fire) mw_mem_state<=1;
      if(dmem_resp_fire) begin mw_y<=load_data;mw_mem_state<=2;end
      if(mw_retire) begin
        retire_valid<=1; retire_pc<=mw_pc; retire_instr<=mw_ins; retire_rd_we<=mw_we&&mw_rd!=0&&!mw_terminal; retire_rd<=mw_rd; retire_rd_data<=mw_y;
        if(mw_store&&!mw_terminal) begin retire_mem_we<=1; retire_mem_addr<=mw_addr; retire_mem_data<=mw_store_data; retire_mem_wstrb<=mw_wstrb; end
        if(mw_terminal) begin trap_valid<=1;mepc<=mw_pc;mcause<=mw_cause;retire_trap<=1;retire_cause<=mw_cause;end else instret_count<=instret_count+1;
        mw_v<=0;mw_we<=0;mw_terminal<=0;mw_illegal<=0;mw_mem<=0;
      end
      if(vec_cpl_fire) begin
        vec_outstanding<=0;
        mw_v<=1; mw_pc<=vec_pc_q; mw_ins<=vec_ins_q; mw_rd<=vec_rd_q;
        mw_we<=vec_cpl_status==2'd0 && vec_cpl_result_valid && vec_rd_we_q;
        mw_y<=vec_cpl_result_data; mw_terminal<=vec_cpl_status!=2'd0; mw_illegal<=vec_cpl_status==2'd2;
        mw_cause<=vec_cpl_exception_cause; mw_mem<=0; mw_store<=0; mw_mem_state<=0;
      end
      if(!vec_outstanding) vec_cpl_stall_count<=0;
      else if(vec_cpl_valid&&vec_cpl_stall_count<VEC_CPL_READY_STALL) vec_cpl_stall_count<=vec_cpl_stall_count+1;
      if(dx_to_mw) begin mw_v<=1;mw_pc<=dx_pc;mw_ins<=dx_ins;mw_rd<=dx_rd;mw_we<=dx_reg_write&&!dx_terminal;mw_y<=dx_y;mw_terminal<=dx_terminal;mw_illegal<=dx_illegal;mw_cause<=dx_cause;mw_mem<=dx_mem&&!dx_terminal;mw_store<=dx_store;mw_mem_size<=dx_mem_size;mw_load_unsigned<=dx_load_unsigned;mw_addr<=dx_mem_addr;mw_wdata<=dx_store_wdata;mw_store_data<=dx_store_data;mw_wstrb<=dx_store_wstrb;mw_mem_state<=0; if(dx_mem&&dx_mem_misaligned)misaligned_memory_ops<=misaligned_memory_ops+1; if(dx_mem&&!dx_store)load_instructions<=load_instructions+1; if(dx_mem&&dx_store)store_instructions<=store_instructions+1;dx_v<=0;end
      if(vec_cmd_fire) begin
        vec_outstanding<=1; vec_payload_valid<=0; vec_pc_q<=dx_pc; vec_ins_q<=dx_ins; vec_rd_q<=dx_rd; vec_rd_we_q<=(dx_vec_funct3==3'd0)||(dx_vec_funct3==3'd4); dx_v<=0;
      end
      if(dx_v&&dx_vec&&!vec_payload_valid) begin vec_cmd_rs1_q<=dx_a; vec_cmd_rs2_q<=dx_b; vec_payload_valid<=1; end
      // Redirect has priority over IF consumption and response buffering.
      if(dx_redirect) begin
        fetch_gen<=fetch_gen+1; if_v<=0; control_flush_cycles<=control_flush_cycles+1; wrong_path_fetches<=wrong_path_fetches+(if_v?1:0);
        if(dx_branch) taken_branch_redirects<=taken_branch_redirects+1;
        if(resp_fire) begin stale_responses<=stale_responses+1; wrong_path_fetches<=wrong_path_fetches+1; end
        // A stale response may complete while a younger request is still held
        // under backpressure.  Retire the old outstanding slot in that case;
        // otherwise out_v would permanently mask the held request.
        if(resp_fire&&!req_fire) out_v<=0;
        if(req_fire) begin out_v<=1;out_addr<=req_addr;out_gen<=req_gen;req_addr<=dx_target;req_gen<=fetch_gen+1;req_v<=1;redirect_pending<=0;end
        else if(imem_req_valid) begin redirect_pending<=1;pending_target<=dx_target;end
        else begin req_addr<=dx_target;req_gen<=fetch_gen+1;req_v<=1;redirect_pending<=0;if(resp_fire) out_v<=0;end
      end else begin
        if(resp_fire) begin
          out_v<=0;
          if(out_gen!=fetch_gen) begin stale_responses<=stale_responses+1;wrong_path_fetches<=wrong_path_fetches+1;end
          else begin if_v<=1;if_pc<=out_addr;if_ins<=imem_resp_data;end
        end
        if(req_fire) begin
          out_v<=1;out_addr<=req_addr;out_gen<=req_gen;
          if(redirect_pending) begin req_addr<=pending_target;req_gen<=fetch_gen;redirect_pending<=0;end else begin req_addr<=req_addr+4;req_gen<=fetch_gen;end
        end
        if(if_to_dx) begin
          dx_v<=1;dx_pc<=if_pc;dx_ins<=if_ins;dx_rs1<=if_ins[19:15];dx_rs2<=if_ins[24:20];dx_rd<=if_ins[11:7];dx_src1<=if_src1_capture;dx_src2<=if_src2_capture;dx_imm<=if_imm;dx_uses_rs1<=if_uses_rs1;dx_uses_rs2<=if_uses_rs2;dx_use_imm<=if_use_imm;dx_reg_write<=if_reg_write;dx_alu_op<=if_alu_op;dx_lui<=if_lui;dx_auipc<=if_auipc;dx_ecall<=if_ecall;dx_illegal<=if_illegal;dx_branch<=if_branch;dx_branch_unsigned<=if_branch_unsigned;dx_branch_kind<=if_branch_kind;dx_jal<=if_jal;dx_jalr<=if_jalr;dx_mem<=if_mem_op!=MEM_NONE;dx_store<=if_mem_op==MEM_STORE;dx_mem_size<=if_mem_size;dx_load_unsigned<=if_load_unsigned;dx_vec<=if_vec;dx_vec_funct3<=if_ins[14:12];
          if(!resp_fire) if_v<=0;
        end
        if(dx_v&&dx_branch&&!dx_branch_taken) non_taken_branches<=non_taken_branches+1;
      end
      assert(!(mw_we&&!mw_v)) else $error("invalid MW register write"); assert(!(mw_illegal&&mw_we)) else $error("illegal instruction writes register"); assert(rf.regs[0]==0) else $error("x0 changed");
      if(vec_cmd_valid&&!vec_cmd_ready) begin
        if(cmd_hold) assert({vec_cmd_op_class,vec_cmd_funct,vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd,vec_cmd_rd_we,vec_cmd_imm,vec_cmd_pc,vec_cmd_id}=={cmd_op_class_q,cmd_funct_q,cmd_vs1_q,cmd_vs2_q,cmd_vd_q,cmd_rs1_q,cmd_rs2_q,cmd_rs1_valid_q,cmd_rs2_valid_q,cmd_rd_q,cmd_rd_we_q,cmd_imm_q,cmd_pc_q,cmd_id_q}) else $error("vector command payload changed under backpressure");
        cmd_hold<=1; cmd_op_class_q<=vec_cmd_op_class; cmd_funct_q<=vec_cmd_funct; cmd_vs1_q<=vec_cmd_vs1; cmd_vs2_q<=vec_cmd_vs2; cmd_vd_q<=vec_cmd_vd; cmd_rs1_q<=vec_cmd_rs1_data; cmd_rs2_q<=vec_cmd_rs2_data; cmd_rs1_valid_q<=vec_cmd_rs1_valid; cmd_rs2_valid_q<=vec_cmd_rs2_valid; cmd_rd_q<=vec_cmd_rd; cmd_rd_we_q<=vec_cmd_rd_we; cmd_imm_q<=vec_cmd_imm; cmd_pc_q<=vec_cmd_pc; cmd_id_q<=vec_cmd_id;
      end else cmd_hold<=0;
      if(vec_cpl_valid) assert(vec_outstanding&&vec_cpl_id==1'b0) else $error("vector completion without matching outstanding command");
      if(vec_cpl_valid&&!vec_cpl_ready) begin
        if(cpl_hold) assert({vec_cpl_id,vec_cpl_status,vec_cpl_result_valid,vec_cpl_result_data,vec_cpl_exception_cause}=={cpl_id_q,cpl_status_q,cpl_result_valid_q,cpl_result_data_q,cpl_cause_q}) else $error("vector completion payload changed under backpressure");
        cpl_hold<=1; cpl_id_q<=vec_cpl_id; cpl_status_q<=vec_cpl_status; cpl_result_valid_q<=vec_cpl_result_valid; cpl_result_data_q<=vec_cpl_result_data; cpl_cause_q<=vec_cpl_exception_cause;
      end else cpl_hold<=0;
      assert(!(vec_cmd_fire&&vec_outstanding)) else $error("second vector command accepted while outstanding");
      assert(!(vec_outstanding&&mw_retire)) else $error("younger scalar retirement while vector command blocks");
      assert(!(mw_terminal&&mw_we)) else $error("vector exception has scalar writeback");
      if(dx_v&&mw_v&&mw_we&&mw_rd==0) begin assert(!dx_uses_rs1||dx_a==dx_src1) else $error("x0 forwarded rs1"); assert(!dx_uses_rs2||dx_b==dx_src2) else $error("x0 forwarded rs2"); end
      if(dx_jalr&&dx_v) assert(dx_target[0]==0) else $error("JALR bit zero not cleared");
    end
  end
endmodule
