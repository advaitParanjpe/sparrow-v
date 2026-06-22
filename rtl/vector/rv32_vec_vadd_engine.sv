// Experimental 4xINT8 vector endpoint.  Debug ports are simulation-only
// verification access; they are not part of the scalar/vector protocol or ISA.
module rv32_vec_vadd_engine #(
  parameter integer LATENCY = 3,
  parameter integer VLEN = 32,
  parameter integer LANES = 4,
  parameter integer SEW = 8,
  parameter integer VREG_COUNT = 32
) (
  input logic clk, rst_n,
  input logic vec_cmd_valid, output logic vec_cmd_ready,
  input logic [3:0] vec_cmd_op_class, input logic [4:0] vec_cmd_vs1, vec_cmd_vs2, vec_cmd_vd,
  input logic vec_cmd_id, input logic vec_cpl_ready,
  output logic vec_cpl_valid, output logic vec_cpl_id, output logic [1:0] vec_cpl_status,
  output logic vec_cpl_result_valid, output logic [31:0] vec_cpl_result_data, vec_cpl_exception_cause,
  output logic busy,
  input logic dbg_we, input logic [4:0] dbg_waddr, input logic [31:0] dbg_wdata,
  input logic [4:0] dbg_raddr, output logic [31:0] dbg_rdata,
  // Test/debug-only observation of the sole architectural vector write.
  output logic dbg_vreg_write_valid, output logic [4:0] dbg_vreg_write_addr,
  output logic [31:0] dbg_vreg_write_data
);
  localparam logic [3:0] VADD8_OP = 4'd3;
  localparam logic [3:0] VDOT8_OP = 4'd4;
  logic [VLEN-1:0] vregs [0:VREG_COUNT-1];
  logic [4:0] vd_q;
  logic [VLEN-1:0] result_q;
  logic vector_write_q;
  logic [31:0] scalar_result_q;
  logic pending_q, cpl_hold_q;
  logic [4:0] cpl_hold_vd_q;
  logic [VLEN-1:0] cpl_hold_result_q;
  logic cpl_hold_vector_write_q, cpl_hold_result_valid_q;
  logic [31:0] cpl_hold_scalar_result_q;
  integer count;
  integer lane;

  function automatic logic signed [31:0] dot8;
    input logic [31:0] a;
    input logic [31:0] b;
    logic signed [7:0] a_lane, b_lane;
    logic signed [15:0] product;
    logic signed [31:0] sum;
    integer dot_lane;
    begin
      sum = 0;
      for (dot_lane = 0; dot_lane < LANES; dot_lane = dot_lane + 1) begin
        a_lane = $signed(a[dot_lane*SEW +: SEW]);
        b_lane = $signed(b[dot_lane*SEW +: SEW]);
        product = a_lane * b_lane;
        sum = sum + {{16{product[15]}}, product};
      end
      dot8 = sum;
    end
  endfunction

  initial begin
    if (VLEN != LANES * SEW || VLEN != 32 || LANES != 4 || SEW != 8 || VREG_COUNT != 32)
      $error("rv32_vec_vadd_engine parameters must describe 32-bit 4x8, 32-register state");
  end
  assign busy = (count != 0) || vec_cpl_valid;
  assign vec_cmd_ready = !busy;
  assign dbg_rdata = vregs[dbg_raddr];
  assign dbg_vreg_write_valid = vec_cpl_valid && vec_cpl_ready && vector_write_q;
  assign dbg_vreg_write_addr = vd_q;
  assign dbg_vreg_write_data = result_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count <= 0;
      vec_cpl_valid <= 0;
      vec_cpl_id <= 0;
      vec_cpl_status <= 0;
      vec_cpl_result_valid <= 0;
      vec_cpl_result_data <= 0;
        vec_cpl_exception_cause <= 0;
        vd_q <= 0;
        result_q <= 0;
        vector_write_q <= 0;
        scalar_result_q <= 0;
      pending_q <= 0;
      cpl_hold_q <= 0;
      cpl_hold_vd_q <= 0;
        cpl_hold_result_q <= 0;
        cpl_hold_vector_write_q <= 0;
        cpl_hold_result_valid_q <= 0;
        cpl_hold_scalar_result_q <= 0;
    end else begin
      if (dbg_we && !busy) vregs[dbg_waddr] <= dbg_wdata;
      if (vec_cpl_valid && vec_cpl_ready) begin
        // VADD8 commits vector state precisely with completion acceptance;
        // VDOT8 has no vector architectural write.
        if (vector_write_q) vregs[vd_q] <= result_q;
        vec_cpl_valid <= 0;
        pending_q <= 0;
      end
      if (vec_cmd_valid && vec_cmd_ready) begin
        vd_q <= vec_cmd_vd;
        vector_write_q <= vec_cmd_op_class == VADD8_OP;
        if (vec_cmd_op_class == VADD8_OP) begin
          for (lane = 0; lane < LANES; lane = lane + 1)
            result_q[lane*SEW +: SEW] <= vregs[vec_cmd_vs1][lane*SEW +: SEW] + vregs[vec_cmd_vs2][lane*SEW +: SEW];
          scalar_result_q <= 0;
        end else begin
          scalar_result_q <= dot8(vregs[vec_cmd_vs1], vregs[vec_cmd_vs2]);
        end
        count <= LATENCY;
        pending_q <= 1;
      end else if (count > 1) begin
        count <= count - 1;
      end else if (count == 1) begin
        count <= 0;
        vec_cpl_valid <= 1;
        vec_cpl_id <= 0;
        vec_cpl_status <= 0;
        vec_cpl_result_valid <= !vector_write_q;
        vec_cpl_result_data <= scalar_result_q;
        vec_cpl_exception_cause <= 0;
      end
      if (vec_cpl_valid && !vec_cpl_ready) begin
        if (cpl_hold_q) begin
          assert (vd_q == cpl_hold_vd_q && result_q == cpl_hold_result_q &&
                  vector_write_q == cpl_hold_vector_write_q &&
                  vec_cpl_result_valid == cpl_hold_result_valid_q &&
                  vec_cpl_result_data == cpl_hold_scalar_result_q)
            else $error("vector completion state changed under backpressure");
        end
        cpl_hold_q <= 1;
        cpl_hold_vd_q <= vd_q;
        cpl_hold_result_q <= result_q;
        cpl_hold_vector_write_q <= vector_write_q;
        cpl_hold_result_valid_q <= vec_cpl_result_valid;
        cpl_hold_scalar_result_q <= vec_cpl_result_data;
      end else begin
        cpl_hold_q <= 0;
      end
      if (vec_cmd_valid && vec_cmd_ready)
        assert (!pending_q && count == 0 && !vec_cpl_valid)
          else $error("vector engine accepted overlapping command");
      if (vec_cpl_valid && vec_cpl_ready)
        assert (pending_q && count == 0)
          else $error("vector completion without a pending command");
      if (dbg_vreg_write_valid)
        assert (pending_q && vec_cpl_valid && vec_cpl_ready)
          else $error("vector register write outside completion handshake");
      if (vec_cmd_valid && vec_cmd_ready)
        assert (vec_cmd_op_class == VADD8_OP || vec_cmd_op_class == VDOT8_OP)
          else $error("unsupported vector operation reached vector engine");
      if (vec_cpl_valid && vector_write_q)
        assert (!vec_cpl_result_valid) else $error("VADD8 must not return a scalar result");
      if (vec_cpl_valid && !vector_write_q)
        assert (vec_cpl_result_valid) else $error("VDOT8 must return a scalar result");
    end
  end
endmodule
