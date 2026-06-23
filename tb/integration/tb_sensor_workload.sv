`timescale 1ns/1ps
// MODE: 1 dense VDOT8, 2 sparse VSDOT8. SAMPLE selects one fixture sample.
module tb_sensor_workload #(parameter integer MODE=1, parameter integer SAMPLE=0);
  `include "sensor_expected.svh"
  logic clk=0,rst_n=0; always #5 clk=~clk;
  logic imem_req_valid,imem_req_ready=1,imem_resp_valid=0,imem_resp_ready; logic [31:0] imem_req_addr,imem_resp_data;
  logic dmem_req_valid,dmem_req_ready=1,dmem_req_write,dmem_resp_valid=0,dmem_resp_ready; logic [31:0] dmem_req_addr,dmem_req_wdata,dmem_resp_data; logic [3:0] dmem_req_wstrb;
  logic trap_valid; logic [31:0] mepc,mcause,mtvec; logic [63:0] cycle_count,instret_count;
  logic retire_valid,retire_rd_we,retire_mem_we,retire_trap; logic [31:0] retire_pc,retire_instr,retire_rd_data,retire_mem_addr,retire_mem_data,retire_cause; logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb; logic [63:0] imem_stall_cycles,dmem_stall_cycles,dep_stall_cycles,control_flush_cycles;
  logic vec_cmd_valid,vec_cmd_ready,vec_cpl_valid,vec_cpl_ready,vec_cpl_id; logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct; logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd; logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc,vec_cpl_result_data,vec_cpl_exception_cause; logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id,vec_cpl_result_valid; logic [1:0] vec_cpl_status;
  logic dbg_we=0,dbg_vreg_write_valid,dbg_spad_we=0,dbg_spad_write_valid,dbg_vsdot_mul_exec_valid,dbg_vsdot_mul_skip_valid; logic [4:0] dbg_waddr=0,dbg_raddr=0,dbg_vreg_write_addr; logic [31:0] dbg_wdata=0,dbg_rdata,dbg_vreg_write_data,dbg_spad_addr=0,dbg_spad_wdata=0,dbg_spad_raddr=0,dbg_spad_rdata,dbg_spad_write_addr,dbg_spad_write_data;
  logic [31:0] imem[0:SENSOR_WORKLOAD_WORDS-1],dmem[0:511]; integer i,cycles,retired,vdots,vsdots,mul_exec,mul_skip,vloads,vstores,completion_writes,output_writes,prediction; logic done; string workspace;

  rv32_core_pipe dut(.*);
  rv32_vec_vadd_engine #(.LATENCY(3)) engine(
    .clk,.rst_n,.vec_cmd_valid,.vec_cmd_ready,.vec_cmd_op_class,.vec_cmd_funct,.vec_cmd_vs1,.vec_cmd_vs2,.vec_cmd_vd,.vec_cmd_rs1_data,.vec_cmd_imm,.vec_cmd_id,.vec_cpl_ready,.vec_cpl_valid,.vec_cpl_id,.vec_cpl_status,.vec_cpl_result_valid,.vec_cpl_result_data,.vec_cpl_exception_cause,.busy(),
    .dbg_we,.dbg_waddr,.dbg_wdata,.dbg_raddr,.dbg_rdata,.dbg_vreg_write_valid,.dbg_vreg_write_addr,.dbg_vreg_write_data,.dbg_vsdot_mul_exec_valid,.dbg_vsdot_mul_skip_valid,.dbg_spad_we,.dbg_spad_addr,.dbg_spad_wdata,.dbg_spad_raddr,.dbg_spad_rdata,.dbg_spad_write_valid,.dbg_spad_write_addr,.dbg_spad_write_data);

  task automatic init_spad(input integer address, input logic [31:0] word); begin
    @(negedge clk); dbg_spad_addr=address; dbg_spad_wdata=word; dbg_spad_we=1; @(posedge clk); @(negedge clk); dbg_spad_we=0;
  end endtask
  task automatic preload_spad; begin for(i=0;i<36;i=i+1) init_spad(i*4,sensor_spad_word(SAMPLE,i)); end endtask

  always_ff @(posedge clk) begin
    if(!rst_n) begin imem_resp_valid<=0; dmem_resp_valid<=0; done<=0; cycles<=0; retired<=0; vdots<=0; vsdots<=0; mul_exec<=0; mul_skip<=0; vloads<=0; vstores<=0; completion_writes<=0; output_writes<=0; end else begin
      cycles<=cycles+1;
      if(imem_resp_valid&&imem_resp_ready) imem_resp_valid<=0;
      if(imem_req_valid&&imem_req_ready) begin imem_resp_valid<=1; imem_resp_data<=imem[imem_req_addr[14:2]]; end
      if(dmem_resp_valid&&dmem_resp_ready) dmem_resp_valid<=0;
      if(dmem_req_valid&&dmem_req_ready) begin dmem_resp_valid<=1; dmem_resp_data<=dmem[dmem_req_addr[10:2]]; if(dmem_req_write) begin
        if(dmem_req_wstrb[0]) dmem[dmem_req_addr[10:2]][7:0]<=dmem_req_wdata[7:0]; if(dmem_req_wstrb[1]) dmem[dmem_req_addr[10:2]][15:8]<=dmem_req_wdata[15:8]; if(dmem_req_wstrb[2]) dmem[dmem_req_addr[10:2]][23:16]<=dmem_req_wdata[23:16]; if(dmem_req_wstrb[3]) dmem[dmem_req_addr[10:2]][31:24]<=dmem_req_wdata[31:24]; end end
      if(retire_valid&&!retire_trap) begin retired<=retired+1; if(retire_instr[6:0]==7'h0b&&retire_instr[14:12]==4) vdots<=vdots+1; if(retire_instr[6:0]==7'h0b&&retire_instr[14:12]==7) vsdots<=vsdots+1; if(retire_mem_we&&retire_mem_addr>=32'h100&&retire_mem_addr<32'h110) output_writes<=output_writes+1; if(retire_mem_we&&retire_mem_addr==32'h1f0) begin completion_writes<=completion_writes+1; done<=1; end end
      if(dbg_vsdot_mul_exec_valid) mul_exec<=mul_exec+2; if(dbg_vsdot_mul_skip_valid) mul_skip<=mul_skip+2;
      if(vec_cmd_valid&&vec_cmd_ready&&vec_cmd_op_class==5) vloads<=vloads+1; if(vec_cmd_valid&&vec_cmd_ready&&vec_cmd_op_class==6) vstores<=vstores+1;
      if(trap_valid) $fatal(1,"unexpected trap sample=%0d cause=%0d pc=%h",SAMPLE,mcause,mepc);
    end
  end

  initial begin
    if(SAMPLE<0||SAMPLE>=SENSOR_SAMPLE_COUNT||(MODE!=1&&MODE!=2)) $fatal(1,"invalid sensor parameters");
    if(!$value$plusargs("SENSOR_WORKSPACE=%s",workspace)) workspace="sim/build";
    for(i=0;i<SENSOR_WORKLOAD_WORDS;i=i+1) imem[i]=32'h00000013; for(i=0;i<512;i=i+1) dmem[i]=0;
    if(MODE==1) $readmemh({workspace,"/sensor_dense.mem"},imem); else $readmemh({workspace,"/sensor_sparse.mem"},imem);
    $readmemh($sformatf("%s/sensor_dmem_%0d.mem",workspace,SAMPLE),dmem);
    imem_req_ready=0; repeat(3) @(posedge clk); rst_n=1; preload_spad(); imem_req_ready=1;
    repeat(5000) begin @(posedge clk); if(done) begin
      @(posedge clk);
      for(i=0;i<4;i=i+1) if($signed(dmem[64+i])!==sensor_expected_logit(SAMPLE,MODE,i)) $fatal(1,"logit mismatch sample=%0d mode=%0d output=%0d got=%0d expected=%0d",SAMPLE,MODE,i,$signed(dmem[64+i]),sensor_expected_logit(SAMPLE,MODE,i));
      prediction=0; for(i=1;i<4;i=i+1) if($signed(dmem[64+i])>$signed(dmem[64+prediction])) prediction=i;
      if(prediction!=sensor_expected_prediction(SAMPLE,MODE)) $fatal(1,"prediction mismatch sample=%0d",SAMPLE);
      if(completion_writes!=1||output_writes!=4) $fatal(1,"completion/output writes %0d/%0d",completion_writes,output_writes);
      if(MODE==1&&(vdots!=16||vsdots||mul_exec||mul_skip||vloads!=32||vstores)) $fatal(1,"dense activity mismatch");
      if(MODE==2&&(vdots||vsdots!=16||mul_exec!=32||mul_skip!=32||vloads!=32||vstores)) $fatal(1,"sparse activity mismatch");
      $display("SENSOR_RTL sample=%0d mode=%0d cycles=%0d retired=%0d vload=%0d vdot=%0d vsdot=%0d mul_exec=%0d mul_skip=%0d completion=%0d prediction=%0d",SAMPLE,MODE,cycles,retired,vloads,vdots,vsdots,mul_exec,mul_skip,completion_writes,prediction);
      $finish;
    end end
    $fatal(1,"sensor workload timeout sample=%0d mode=%0d",SAMPLE,MODE);
  end
endmodule
