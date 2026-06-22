`timescale 1ns/1ps
// MODE: 0 scalar software multiply, 1 dense VDOT8, 2 sparse VSDOT8.
module tb_workload_fc #(parameter integer MODE=0);
  `include "workload_expected.svh"
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,vec_cpl_valid,vec_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we=0,dbg_vreg_write_valid,dbg_spad_we=0,dbg_spad_write_valid,dbg_vsdot_mul_exec_valid,dbg_vsdot_mul_skip_valid; logic [4:0] dbg_waddr=0,dbg_raddr=0,dbg_vreg_write_addr; logic [31:0] dbg_wdata=0,dbg_rdata,dbg_vreg_write_data,dbg_spad_addr=0,dbg_spad_wdata=0,dbg_spad_raddr=0,dbg_spad_rdata,dbg_spad_write_addr,dbg_spad_write_data;
  logic [31:0] imem[0:WORKLOAD_WORDS-1], dmem[0:511]; integer i,cycles,retired,scalar_mul_ops,vdots,vsdots,mul_exec,mul_skip,vloads,vstores,spad_writes,completion_writes,output_writes; logic done;

  rv32_core_pipe dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(
    .clk,.rst_n,.vec_cmd_valid,.vec_cmd_ready,.vec_cmd_op_class,.vec_cmd_funct,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_rs1_data,.vec_cmd_imm,.vec_cmd_id,.vec_cpl_ready,.vec_cpl_valid,.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),
    .dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data,.dbg_vsdot_mul_exec_valid,.dbg_vsdot_mul_skip_valid,.dbg_spad_we,.dbg_spad_addr,.dbg_spad_wdata,.dbg_spad_raddr,.dbg_spad_rdata,.dbg_spad_write_valid,.dbg_spad_write_addr,.dbg_spad_write_data);

  task automatic init_spad(input integer addr, input logic [31:0] word); begin
    @(negedge clk); dbg_spad_addr=addr; dbg_spad_wdata=word; dbg_spad_we=1; @(posedge clk); @(negedge clk); dbg_spad_we=0;
  end endtask
  task automatic preload_spad; begin
    init_spad(0,WORKLOAD_SPAD_0); init_spad(4,WORKLOAD_SPAD_1); init_spad(8,WORKLOAD_SPAD_2); init_spad(12,WORKLOAD_SPAD_3);
    for(i=4;i<36;i=i+1) begin
      case(i)
        4:init_spad(i*4,WORKLOAD_SPAD_4); 5:init_spad(i*4,WORKLOAD_SPAD_5); 6:init_spad(i*4,WORKLOAD_SPAD_6); 7:init_spad(i*4,WORKLOAD_SPAD_7);
        8:init_spad(i*4,WORKLOAD_SPAD_8); 9:init_spad(i*4,WORKLOAD_SPAD_9); 10:init_spad(i*4,WORKLOAD_SPAD_10); 11:init_spad(i*4,WORKLOAD_SPAD_11);
        12:init_spad(i*4,WORKLOAD_SPAD_12); 13:init_spad(i*4,WORKLOAD_SPAD_13); 14:init_spad(i*4,WORKLOAD_SPAD_14); 15:init_spad(i*4,WORKLOAD_SPAD_15);
        16:init_spad(i*4,WORKLOAD_SPAD_16); 17:init_spad(i*4,WORKLOAD_SPAD_17); 18:init_spad(i*4,WORKLOAD_SPAD_18); 19:init_spad(i*4,WORKLOAD_SPAD_19);
        20:init_spad(i*4,WORKLOAD_SPAD_20); 21:init_spad(i*4,WORKLOAD_SPAD_21); 22:init_spad(i*4,WORKLOAD_SPAD_22); 23:init_spad(i*4,WORKLOAD_SPAD_23);
        24:init_spad(i*4,WORKLOAD_SPAD_24); 25:init_spad(i*4,WORKLOAD_SPAD_25); 26:init_spad(i*4,WORKLOAD_SPAD_26); 27:init_spad(i*4,WORKLOAD_SPAD_27);
        28:init_spad(i*4,WORKLOAD_SPAD_28); 29:init_spad(i*4,WORKLOAD_SPAD_29); 30:init_spad(i*4,WORKLOAD_SPAD_30); 31:init_spad(i*4,WORKLOAD_SPAD_31);
        32:init_spad(i*4,WORKLOAD_SPAD_32); 33:init_spad(i*4,WORKLOAD_SPAD_33); 34:init_spad(i*4,WORKLOAD_SPAD_34); 35:init_spad(i*4,WORKLOAD_SPAD_35);
      endcase
    end
  end endtask

  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0; dmem_resp_valid<=0; done<=0; cycles<=0; retired<=0; scalar_mul_ops<=0; vdots<=0; vsdots<=0; mul_exec<=0; mul_skip<=0; vloads<=0; vstores<=0; spad_writes<=0; completion_writes<=0; output_writes<=0; end else begin
      cycles<=cycles+1;
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=imem[imem_req_addr[14:2]]; end
      if(dmem_resp_valid&&dmem_resp_ready) dmem_resp_valid<=0;
      if(dmem_req_valid&&dmem_req_ready) begin
        dmem_resp_valid<=1; dmem_resp_data<=dmem[dmem_req_addr[10:2]];
        if(dmem_req_write) begin
          if(dmem_req_wstrb[0]) dmem[dmem_req_addr[10:2]][7:0]<=dmem_req_wdata[7:0]; if(dmem_req_wstrb[1]) dmem[dmem_req_addr[10:2]][15:8]<=dmem_req_wdata[15:8]; if(dmem_req_wstrb[2]) dmem[dmem_req_addr[10:2]][23:16]<=dmem_req_wdata[23:16]; if(dmem_req_wstrb[3]) dmem[dmem_req_addr[10:2]][31:24]<=dmem_req_wdata[31:24];
        end
      end
      if(retire_valid&&!retire_trap) begin
        retired<=retired+1;
        // scalar_program emits this unique instruction once per software
        // multiply invocation: addi x8, x0, 0 initializes its product.
        if(MODE==0 && retire_instr==32'h00000413) scalar_mul_ops<=scalar_mul_ops+1;
        if(retire_instr[6:0]==7'h0b && retire_instr[14:12]==4) vdots<=vdots+1;
        if(retire_instr[6:0]==7'h0b && retire_instr[14:12]==7) vsdots<=vsdots+1;
        if(retire_mem_we && retire_mem_addr>=32'h100 && retire_mem_addr<32'h110) output_writes<=output_writes+1;
        if(retire_mem_we && retire_mem_addr==32'h1f0) begin completion_writes<=completion_writes+1; done<=1; end
      end
      if(dbg_vsdot_mul_exec_valid) mul_exec<=mul_exec+2; if(dbg_vsdot_mul_skip_valid) mul_skip<=mul_skip+2;
      if(dbg_spad_write_valid) spad_writes<=spad_writes+1;
      if(vec_cmd_valid&&vec_cmd_ready&&vec_cmd_op_class==5) vloads<=vloads+1;
      if(vec_cmd_valid&&vec_cmd_ready&&vec_cmd_op_class==6) vstores<=vstores+1;
      if(trap_valid) $fatal(1,"unexpected trap cause=%0d pc=%h",mcause,mepc);
    end
  end

  initial begin
    for(i=0;i<WORKLOAD_WORDS;i=i+1) imem[i]=32'h00000013;
    for(i=0;i<512;i=i+1) dmem[i]=0;
    if(MODE==0) $readmemh("sim/build/workload_scalar.mem",imem); else if(MODE==1) $readmemh("sim/build/workload_dense.mem",imem); else $readmemh("sim/build/workload_sparse.mem",imem);
    $readmemh("sim/build/workload_dmem.mem",dmem);
    imem_req_ready=0; repeat(3) @(posedge clk); rst_n=1; preload_spad(); imem_req_ready=1;
    repeat(30000) begin @(posedge clk); if(done) begin
      @(posedge clk);
      if(dmem[64]!==WORKLOAD_OUT_0||dmem[65]!==WORKLOAD_OUT_1||dmem[66]!==WORKLOAD_OUT_2||dmem[67]!==WORKLOAD_OUT_3) $fatal(1,"output mismatch %0d %0d %0d %0d",$signed(dmem[64]),$signed(dmem[65]),$signed(dmem[66]),$signed(dmem[67]));
      if(completion_writes!=1||output_writes!=4) $fatal(1,"completion/output writes %0d/%0d",completion_writes,output_writes);
      if(MODE==0 && (scalar_mul_ops!=64||vdots||vsdots||mul_exec||mul_skip||vloads||vstores||spad_writes)) $fatal(1,"scalar activity mismatch");
      if(MODE==1 && (vdots!=16||vsdots||mul_exec||mul_skip||vloads!=32||vstores||spad_writes||scalar_mul_ops)) $fatal(1,"dense activity mismatch");
      if(MODE==2 && (vdots||vsdots!=16||mul_exec!=32||mul_skip!=32||vloads!=32||vstores||spad_writes||scalar_mul_ops)) $fatal(1,"sparse activity mismatch");
      $display("WORKLOAD mode=%0d cycles=%0d retired=%0d scalar_mul_ops=%0d vdot=%0d vsdot=%0d mul_exec=%0d mul_skip=%0d vload=%0d vstore=%0d spad_writes=%0d outputs=%0d,%0d,%0d,%0d",MODE,cycles,retired,scalar_mul_ops,vdots,vsdots,mul_exec,mul_skip,vloads,vstores,spad_writes,$signed(dmem[64]),$signed(dmem[65]),$signed(dmem[66]),$signed(dmem[67]));
      $finish;
    end end
    $fatal(1,"workload timeout mode=%0d",MODE);
  end
endmodule
