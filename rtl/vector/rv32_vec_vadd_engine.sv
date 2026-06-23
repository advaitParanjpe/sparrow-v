// Experimental 4xINT8/vector-memory endpoint. Debug ports are simulation-only
// verification access; they are not part of the scalar/vector protocol or ISA.
module rv32_vec_vadd_engine #(
  parameter integer LATENCY = 3,
  parameter integer VLEN = 32, parameter integer LANES = 4,
  parameter integer SEW = 8, parameter integer VREG_COUNT = 32,
  parameter integer SCRATCHPAD_BYTES = 256,
`ifdef SPARROWV_DENSE_ONLY
  parameter bit ENABLE_SPARSE = 1'b0
`else
  parameter bit ENABLE_SPARSE = 1'b1
`endif
) (
  input logic clk, rst_n,
  input logic vec_cmd_valid, output logic vec_cmd_ready,
  input logic [3:0] vec_cmd_op_class, input logic [7:0] vec_cmd_funct, input logic [4:0] vec_cmd_vs1, vec_cmd_vs2, vec_cmd_vd,
  input logic [31:0] vec_cmd_rs1_data, vec_cmd_imm,
  input logic vec_cmd_id, input logic vec_cpl_ready,
  output logic vec_cpl_valid, output logic vec_cpl_id, output logic [1:0] vec_cpl_status,
  output logic vec_cpl_result_valid, output logic [31:0] vec_cpl_result_data, vec_cpl_exception_cause,
  output logic busy,
  input logic dbg_we, input logic [4:0] dbg_waddr, input logic [31:0] dbg_wdata,
  input logic [4:0] dbg_raddr, output logic [31:0] dbg_rdata,
  output logic dbg_vreg_write_valid, output logic [4:0] dbg_vreg_write_addr,
  output logic [31:0] dbg_vreg_write_data,
  // Test-only successful sparse-compute events, asserted at completion only.
  output logic dbg_vsdot_mul_exec_valid, dbg_vsdot_mul_skip_valid,
  // Bounded test-only scratchpad initialization/observation.
  input logic dbg_spad_we, input logic [31:0] dbg_spad_addr, dbg_spad_wdata,
  input logic [31:0] dbg_spad_raddr, output logic [31:0] dbg_spad_rdata,
  output logic dbg_spad_write_valid, output logic [31:0] dbg_spad_write_addr, dbg_spad_write_data
);
  localparam logic [3:0] VADD8_OP = 4'd3, VDOT8_OP = 4'd4, VSDOT8_OP = 4'd7;
  localparam logic [3:0] VLOAD32_OP = 4'd5, VSTORE32_OP = 4'd6;
  localparam logic [31:0] VEC_CAUSE_MISALIGNED = 32'd16;
  localparam logic [31:0] VEC_CAUSE_RANGE = 32'd17;
  localparam logic [31:0] VEC_CAUSE_SPARSE_METADATA = 32'd18;
  logic [VLEN-1:0] vregs [0:VREG_COUNT-1];
  logic [7:0] scratchpad [0:SCRATCHPAD_BYTES-1];
  logic [4:0] vd_q; logic [VLEN-1:0] result_q; logic vector_write_q, store_write_q, sparse_q;
  logic [31:0] scalar_result_q, store_addr_q, store_data_q;
  logic [1:0] status_q; logic [31:0] cause_q;
  logic pending_q, cpl_hold_q;
  logic [170:0] cpl_hold_q_payload;
  integer count, lane;

  function automatic logic signed [31:0] dot8(input logic [31:0] a, input logic [31:0] b);
    logic signed [7:0] a_lane, b_lane; logic signed [15:0] product; logic signed [31:0] sum; integer dot_lane;
    begin
      sum = 0;
      for (dot_lane = 0; dot_lane < LANES; dot_lane = dot_lane + 1) begin
        a_lane = $signed(a[dot_lane*SEW +: SEW]); b_lane = $signed(b[dot_lane*SEW +: SEW]);
        product = a_lane * b_lane; sum = sum + {{16{product[15]}}, product};
      end
      dot8 = sum;
    end
  endfunction
  function automatic logic signed [31:0] sdot8(input logic [31:0] a, input logic [31:0] w, input logic [2:0] pattern);
    logic signed [7:0] a_low, a_high, w_low, w_high;
    logic signed [15:0] low_product, high_product;
    integer low_lane, high_lane;
    begin
      case (pattern)
        3'b000: begin low_lane = 0; high_lane = 1; end
        3'b001: begin low_lane = 0; high_lane = 2; end
        3'b010: begin low_lane = 0; high_lane = 3; end
        3'b011: begin low_lane = 1; high_lane = 2; end
        3'b100: begin low_lane = 1; high_lane = 3; end
        default: begin low_lane = 2; high_lane = 3; end // 3'b101 after validation
      endcase
      a_low = $signed(a[low_lane*SEW +: SEW]); a_high = $signed(a[high_lane*SEW +: SEW]);
      w_low = $signed(w[7:0]); w_high = $signed(w[15:8]);
      low_product = a_low * w_low; high_product = a_high * w_high;
      sdot8 = {{16{low_product[15]}}, low_product} + {{16{high_product[15]}}, high_product};
    end
  endfunction
  function automatic logic access_valid(input logic [31:0] base, input logic [31:0] imm, input logic [31:0] addr);
    logic wrapped;
    begin
      wrapped = imm[31] ? (addr > base) : (addr < base);
      access_valid = !wrapped && !(|addr[1:0]) && (addr <= SCRATCHPAD_BYTES-4);
    end
  endfunction

  initial begin
    if (VLEN != LANES*SEW || VLEN != 32 || LANES != 4 || SEW != 8 || VREG_COUNT != 32 || SCRATCHPAD_BYTES < 256 || (SCRATCHPAD_BYTES % 4) != 0)
      $error("rv32_vec_vadd_engine parameters are unsupported");
  end
  assign busy = (count != 0) || vec_cpl_valid;
  assign vec_cmd_ready = !busy;
  assign dbg_rdata = vregs[dbg_raddr];
  assign dbg_spad_rdata = (dbg_spad_raddr <= SCRATCHPAD_BYTES-4 && !(|dbg_spad_raddr[1:0])) ?
                           {scratchpad[dbg_spad_raddr+3], scratchpad[dbg_spad_raddr+2], scratchpad[dbg_spad_raddr+1], scratchpad[dbg_spad_raddr]} : 32'd0;
  assign dbg_vreg_write_valid = vec_cpl_valid && vec_cpl_ready && vector_write_q && status_q == 0;
  assign dbg_vreg_write_addr = vd_q; assign dbg_vreg_write_data = result_q;
  assign dbg_spad_write_valid = vec_cpl_valid && vec_cpl_ready && store_write_q && status_q == 0;
  assign dbg_spad_write_addr = store_addr_q; assign dbg_spad_write_data = store_data_q;
  assign dbg_vsdot_mul_exec_valid = ENABLE_SPARSE && vec_cpl_valid && vec_cpl_ready && sparse_q && status_q == 0;
  assign dbg_vsdot_mul_skip_valid = dbg_vsdot_mul_exec_valid;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count <= 0; vec_cpl_valid <= 0; vec_cpl_id <= 0; vec_cpl_status <= 0; vec_cpl_result_valid <= 0; vec_cpl_result_data <= 0; vec_cpl_exception_cause <= 0;
      vd_q <= 0; result_q <= 0; vector_write_q <= 0; store_write_q <= 0; sparse_q <= 0; scalar_result_q <= 0; store_addr_q <= 0; store_data_q <= 0; status_q <= 0; cause_q <= 0; pending_q <= 0; cpl_hold_q <= 0; cpl_hold_q_payload <= 0;
    end else begin
      if (dbg_we && !busy) vregs[dbg_waddr] <= dbg_wdata;
      if (dbg_spad_we && !busy && dbg_spad_addr <= SCRATCHPAD_BYTES-4 && !(|dbg_spad_addr[1:0])) begin
        scratchpad[dbg_spad_addr] <= dbg_spad_wdata[7:0]; scratchpad[dbg_spad_addr+1] <= dbg_spad_wdata[15:8];
        scratchpad[dbg_spad_addr+2] <= dbg_spad_wdata[23:16]; scratchpad[dbg_spad_addr+3] <= dbg_spad_wdata[31:24];
      end
      if (vec_cpl_valid && vec_cpl_ready) begin
        if (status_q == 0 && vector_write_q) vregs[vd_q] <= result_q;
        if (status_q == 0 && store_write_q) begin
          scratchpad[store_addr_q] <= store_data_q[7:0]; scratchpad[store_addr_q+1] <= store_data_q[15:8];
          scratchpad[store_addr_q+2] <= store_data_q[23:16]; scratchpad[store_addr_q+3] <= store_data_q[31:24];
        end
        vec_cpl_valid <= 0; pending_q <= 0;
      end
      if (vec_cmd_valid && vec_cmd_ready) begin
        vd_q <= vec_cmd_vd; vector_write_q <= 0; store_write_q <= 0; sparse_q <= 0; scalar_result_q <= 0; status_q <= 0; cause_q <= 0;
        if (vec_cmd_op_class == VADD8_OP) begin
          vector_write_q <= 1;
          for (lane=0; lane<LANES; lane=lane+1) result_q[lane*SEW +: SEW] <= vregs[vec_cmd_vs1][lane*SEW +: SEW] + vregs[vec_cmd_vs2][lane*SEW +: SEW];
        end else if (vec_cmd_op_class == VDOT8_OP) begin
          scalar_result_q <= dot8(vregs[vec_cmd_vs1], vregs[vec_cmd_vs2]);
        end else if (ENABLE_SPARSE && vec_cmd_op_class == VSDOT8_OP) begin
          if (vec_cmd_funct[7:5] <= 3'b101) begin
            sparse_q <= 1;
            scalar_result_q <= sdot8(vregs[vec_cmd_vs1], vregs[vec_cmd_vs2], vec_cmd_funct[7:5]);
          end else begin
            status_q <= 2'd1;
            cause_q <= VEC_CAUSE_SPARSE_METADATA;
          end
        end else if (vec_cmd_op_class == VLOAD32_OP || vec_cmd_op_class == VSTORE32_OP) begin
          store_addr_q <= vec_cmd_rs1_data + vec_cmd_imm;
          if (!access_valid(vec_cmd_rs1_data, vec_cmd_imm, vec_cmd_rs1_data + vec_cmd_imm)) begin
            status_q <= 2'd1;
            cause_q <= (((vec_cmd_rs1_data + vec_cmd_imm) & 32'd3) != 0) ? VEC_CAUSE_MISALIGNED : VEC_CAUSE_RANGE;
          end else if (vec_cmd_op_class == VLOAD32_OP) begin
            vector_write_q <= 1;
            result_q <= {scratchpad[vec_cmd_rs1_data+vec_cmd_imm+3], scratchpad[vec_cmd_rs1_data+vec_cmd_imm+2], scratchpad[vec_cmd_rs1_data+vec_cmd_imm+1], scratchpad[vec_cmd_rs1_data+vec_cmd_imm]};
          end else begin
            store_write_q <= 1; store_data_q <= vregs[vec_cmd_vs2];
          end
        end else begin
          status_q <= 2'd2; cause_q <= 32'd2;
        end
        count <= LATENCY; pending_q <= 1;
      end else if (count > 1) count <= count - 1;
      else if (count == 1) begin
        count <= 0; vec_cpl_valid <= 1; vec_cpl_id <= 0; vec_cpl_status <= status_q;
        vec_cpl_result_valid <= (status_q == 0 && !vector_write_q && !store_write_q);
        vec_cpl_result_data <= scalar_result_q; vec_cpl_exception_cause <= cause_q;
      end
      if (vec_cpl_valid && !vec_cpl_ready) begin
        if (cpl_hold_q) assert ({vec_cpl_id,vec_cpl_status,vec_cpl_result_valid,vec_cpl_result_data,vec_cpl_exception_cause,vd_q,result_q,vector_write_q,store_write_q,store_addr_q,store_data_q} == cpl_hold_q_payload) else $error("vector completion state changed under backpressure");
        cpl_hold_q <= 1; cpl_hold_q_payload <= {vec_cpl_id,vec_cpl_status,vec_cpl_result_valid,vec_cpl_result_data,vec_cpl_exception_cause,vd_q,result_q,vector_write_q,store_write_q,store_addr_q,store_data_q};
      end else cpl_hold_q <= 0;
      if (vec_cmd_valid && vec_cmd_ready) assert (!pending_q && count == 0 && !vec_cpl_valid) else $error("vector engine accepted overlapping command");
      if (dbg_vreg_write_valid) assert (pending_q && vec_cpl_valid && vec_cpl_ready) else $error("vector register write outside completion handshake");
      if (dbg_spad_write_valid) assert (pending_q && vec_cpl_valid && vec_cpl_ready) else $error("scratchpad write outside completion handshake");
      if (store_write_q) assert (!vector_write_q) else $error("store must not write a vector register");
      if (sparse_q) assert (!vector_write_q && !store_write_q) else $error("VSDOT8 must not write vector state");
      if (dbg_vsdot_mul_exec_valid || dbg_vsdot_mul_skip_valid) assert (dbg_vsdot_mul_exec_valid && dbg_vsdot_mul_skip_valid && sparse_q && status_q == 0) else $error("invalid VSDOT8 accounting event");
    end
  end
endmodule
