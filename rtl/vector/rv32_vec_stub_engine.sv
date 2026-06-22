// Deterministic test-only endpoint for the experimental scalar/vector boundary.
module rv32_vec_stub_engine #(parameter integer LATENCY=3) (
  input logic clk,rst_n,input logic vec_cmd_valid,output logic vec_cmd_ready,
  input logic [3:0] vec_cmd_op_class,input logic [31:0] vec_cmd_rs1_data,vec_cmd_rs2_data,
  input logic vec_cmd_id,input logic vec_cpl_ready,output logic vec_cpl_valid,
  output logic vec_cpl_id,output logic [1:0] vec_cpl_status,
  output logic vec_cpl_result_valid,output logic [31:0] vec_cpl_result_data,vec_cpl_exception_cause,
  output logic busy
);
  integer count;
  logic [3:0] op_q; logic [31:0] a_q,b_q;
  assign busy=vec_cpl_valid||(count!=0); assign vec_cmd_ready=!busy;
  always_ff @(posedge clk) begin
    if(!rst_n) begin count<=0; vec_cpl_valid<=0; vec_cpl_id<=0; vec_cpl_status<=0; vec_cpl_result_valid<=0; vec_cpl_result_data<=0; vec_cpl_exception_cause<=0; op_q<=0; a_q<=0; b_q<=0; end
    else begin
      if(vec_cpl_valid&&vec_cpl_ready) vec_cpl_valid<=0;
      if(vec_cmd_valid&&vec_cmd_ready) begin op_q<=vec_cmd_op_class; a_q<=vec_cmd_rs1_data; b_q<=vec_cmd_rs2_data; count<=LATENCY; end
      else if(count>1) count<=count-1;
      else if(count==1) begin count<=0; vec_cpl_valid<=1; vec_cpl_id<=0; vec_cpl_status<=(op_q==4'd2) ? 2'd1 : 2'd0; vec_cpl_result_valid<=op_q==4'd0; vec_cpl_result_data<=a_q+b_q; vec_cpl_exception_cause<=(op_q==4'd2) ? 32'd2 : 32'd0; end
      assert(!(vec_cmd_valid&&vec_cmd_ready&&busy)) else $error("stub accepted overlapping command");
    end
  end
endmodule
