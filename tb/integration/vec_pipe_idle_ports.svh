// Idle experimental vector boundary for scalar-only pipeline regressions.
logic vec_cmd_valid, vec_cmd_ready=1'b1;
logic [3:0] vec_cmd_op_class; logic [7:0] vec_cmd_funct;
logic [4:0] vec_cmd_vs1,vec_cmd_vs2,vec_cmd_vd,vec_cmd_rd;
logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,vec_cmd_imm,vec_cmd_pc;
logic vec_cmd_rs1_valid,vec_cmd_rs2_valid,vec_cmd_rd_we,vec_cmd_id;
logic vec_cpl_valid=1'b0,vec_cpl_ready,vec_cpl_id=1'b0;
logic [1:0] vec_cpl_status=2'd0;
logic vec_cpl_result_valid=1'b0;
logic [31:0] vec_cpl_result_data=0,vec_cpl_exception_cause=0;
