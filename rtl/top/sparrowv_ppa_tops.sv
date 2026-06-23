// Synthesis-only integration tops. They expose the real scalar memory ports
// and deliberately omit all testbench/debug connections.
module sparrowv_ppa_scalar_top (
  input logic clk, rst_n,
  output logic imem_req_valid, input logic imem_req_ready, output logic [31:0] imem_req_addr,
  input logic imem_resp_valid, output logic imem_resp_ready, input logic [31:0] imem_resp_data,
  output logic dmem_req_valid, input logic dmem_req_ready, output logic dmem_req_write,
  output logic [31:0] dmem_req_addr, output logic [31:0] dmem_req_wdata, output logic [3:0] dmem_req_wstrb,
  input logic dmem_resp_valid, output logic dmem_resp_ready, input logic [31:0] dmem_resp_data
);
  logic trap_valid; logic [31:0] mepc, mcause, mtvec;
  logic [63:0] cycle_count, instret_count, imem_stall_cycles, dmem_stall_cycles, dep_stall_cycles, control_flush_cycles;
  logic retire_valid, retire_rd_we, retire_mem_we, retire_trap;
  logic [31:0] retire_pc, retire_instr, retire_rd_data, retire_mem_addr, retire_mem_data, retire_cause;
  logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb;
  rv32_core core (.*);
endmodule

module sparrowv_ppa_vector_top #(
  parameter bit ENABLE_SPARSE = 1'b1
) (
  input logic clk, rst_n,
  output logic imem_req_valid, input logic imem_req_ready, output logic [31:0] imem_req_addr,
  input logic imem_resp_valid, output logic imem_resp_ready, input logic [31:0] imem_resp_data,
  output logic dmem_req_valid, input logic dmem_req_ready, output logic dmem_req_write,
  output logic [31:0] dmem_req_addr, output logic [31:0] dmem_req_wdata, output logic [3:0] dmem_req_wstrb,
  input logic dmem_resp_valid, output logic dmem_resp_ready, input logic [31:0] dmem_resp_data
);
  logic trap_valid; logic [31:0] mepc, mcause, mtvec;
  logic [63:0] cycle_count, instret_count, imem_stall_cycles, dmem_stall_cycles, dep_stall_cycles, control_flush_cycles;
  logic [63:0] taken_branch_redirects, non_taken_branches, wrong_path_fetches, stale_responses, load_instructions, store_instructions, load_response_wait_cycles, load_use_stall_cycles, misaligned_memory_ops;
  logic retire_valid, retire_rd_we, retire_mem_we, retire_trap;
  logic [31:0] retire_pc, retire_instr, retire_rd_data, retire_mem_addr, retire_mem_data, retire_cause;
  logic [4:0] retire_rd; logic [3:0] retire_mem_wstrb;
  logic vec_cmd_valid, vec_cmd_ready, vec_cpl_valid, vec_cpl_ready, vec_cmd_id, vec_cpl_id, vec_cpl_result_valid;
  logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct;
  logic [4:0] vec_cmd_vs1, vec_cmd_vs2, vec_cmd_vd, vec_cmd_rd;
  logic [31:0] vec_cmd_rs1_data, vec_cmd_rs2_data, vec_cmd_imm, vec_cmd_pc, vec_cpl_result_data, vec_cpl_exception_cause;
  logic vec_cmd_rs1_valid, vec_cmd_rs2_valid, vec_cmd_rd_we; logic [1:0] vec_cpl_status;
  rv32_core_pipe core (.*);
  rv32_vec_vadd_engine #(.ENABLE_SPARSE(ENABLE_SPARSE)) engine (
    .clk, .rst_n, .vec_cmd_valid, .vec_cmd_ready, .vec_cmd_op_class, .vec_cmd_funct,
    .vec_cmd_vs1, .vec_cmd_vs2, .vec_cmd_vd, .vec_cmd_rs1_data, .vec_cmd_imm,
    .vec_cmd_id, .vec_cpl_ready, .vec_cpl_valid, .vec_cpl_id, .vec_cpl_status,
    .vec_cpl_result_valid, .vec_cpl_result_data, .vec_cpl_exception_cause, .busy(),
    .dbg_we(1'b0), .dbg_waddr(5'd0), .dbg_wdata(32'd0), .dbg_raddr(5'd0), .dbg_rdata(),
    .dbg_vreg_write_valid(), .dbg_vreg_write_addr(), .dbg_vreg_write_data(),
    .dbg_vsdot_mul_exec_valid(), .dbg_vsdot_mul_skip_valid(),
    .dbg_spad_we(1'b0), .dbg_spad_addr(32'd0), .dbg_spad_wdata(32'd0), .dbg_spad_raddr(32'd0),
    .dbg_spad_rdata(), .dbg_spad_write_valid(), .dbg_spad_write_addr(), .dbg_spad_write_data()
  );
endmodule

module sparrowv_ppa_dense_top (
  input logic clk, rst_n, output logic imem_req_valid, input logic imem_req_ready, output logic [31:0] imem_req_addr,
  input logic imem_resp_valid, output logic imem_resp_ready, input logic [31:0] imem_resp_data,
  output logic dmem_req_valid, input logic dmem_req_ready, output logic dmem_req_write, output logic [31:0] dmem_req_addr,
  output logic [31:0] dmem_req_wdata, output logic [3:0] dmem_req_wstrb, input logic dmem_resp_valid,
  output logic dmem_resp_ready, input logic [31:0] dmem_resp_data
);
  sparrowv_ppa_vector_top #(.ENABLE_SPARSE(1'b0)) top (.*);
endmodule

module sparrowv_ppa_sparse_top (
  input logic clk, rst_n, output logic imem_req_valid, input logic imem_req_ready, output logic [31:0] imem_req_addr,
  input logic imem_resp_valid, output logic imem_resp_ready, input logic [31:0] imem_resp_data,
  output logic dmem_req_valid, input logic dmem_req_ready, output logic dmem_req_write, output logic [31:0] dmem_req_addr,
  output logic [31:0] dmem_req_wdata, output logic [3:0] dmem_req_wstrb, input logic dmem_resp_valid,
  output logic dmem_resp_ready, input logic [31:0] dmem_resp_data
);
  sparrowv_ppa_vector_top #(.ENABLE_SPARSE(1'b1)) top (.*);
endmodule
