`timescale 1ns/1ps

module move_rect (
	input clk,
	input rst_n,

	input i_button_c,
	input i_button_e,
	input i_button_w,
	input i_button_s,
	input i_button_n,

	output o_sync_vs,
	output o_sync_hs,
	output o_sync_va,
	output o_sync_ha,
	output o_sync_de,
	output [ 8-1: 0] o_sync_red,
	output [ 8-1: 0] o_sync_grn,
	output [ 8-1: 0] o_sync_blu
);

// 4 bits * 2 positions * 4 blocks * 4 rads * 2 types
parameter [1023 /* 4 * 2 * 4 * 4 * 8 - 1 */ : 0] BLOCKS = {
	{ 4'b1, 4'b1 }, { 4'b0, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b1 }, { 4'b0, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b1 }, { 4'b0, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b1 }, { 4'b0, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },

	{ -4'b1, 4'b0 }, { 4'b0, -4'b1 }, { 4'b0, 4'b1 }, { 4'b0, 4'b0 },
	{ 4'b0, 4'b1 }, { 4'b1, 4'b0 }, { -4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b0, -4'b1 }, { 4'b1, 4'b0 }, { -4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b0 }, { 4'b0, 4'b1 }, { 4'b0, -4'b1 }, { 4'b0, 4'b0 },

	{ 4'b1, 4'b0 }, { 4'b0, 4'b1 }, { -4'b1, 4'b1 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, -4'b1 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b0 }, { 4'b0, 4'b1 }, { -4'b1, 4'b1 }, { 4'b0, 4'b0 },
	{ 4'b1, 4'b1 }, { 4'b1, 4'b0 }, { 4'b0, -4'b1 }, { 4'b0, 4'b0 },

	{ -4'b1, -4'b1 }, { 4'b0, -4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, -4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b1 }, { 4'b0, 4'b0 },
	{ -4'b1, -4'b1 }, { 4'b0, -4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b1, -4'b1 }, { 4'b1, 4'b0 }, { 4'b0, 4'b1 }, { 4'b0, 4'b0 },

	{ 4'd2, 4'b1 }, { 4'd2, 4'b0 }, { 4'b1, 4'b0 }, { 4'b0, 4'b0 },
	{ 4'b0, 4'b1 }, { 4'b1, 4'b1 }, { 4'b1, -4'b1 }, { 4'b1, 4'b0 },
	{ 4'd2, 4'b0 }, { 4'b1, 4'b0 }, { 4'b0, -4'b1 }, { 4'b0, 4'b0 },
	{ 4'b1, -4'b1 }, { 4'b0, 4'b1 }, { 4'b0, -4'b1 }, { 4'b0, 4'b0 },

	{ 4'd0, 4'd1 }, { 4'd1, -4'd1 }, { 4'd0, -4'd1 }, { 4'd0, 4'd0 },
	{ 4'd1, 4'd1 }, { 4'd1, 4'd0 }, { -4'd1, 4'd0 }, { 4'd0, 4'd0 },
	{ -4'd1, 4'd1 }, { 4'd0, 4'd1 }, { 4'd0, -4'd1 }, { 4'd0, 4'd0 },
	{ 4'd2, 4'd0 }, { 4'd1, 4'd0 }, { 4'd0, -4'd1 }, { 4'd0, 4'd0 },

	{ 4'd0, -4'd2 }, { 4'd0, -4'd1 }, { 4'd0, 4'd1 }, { 4'd0, 4'd0 },
	{ 4'd3, 4'd0 }, { 4'd2, 4'd0 }, { 4'd1, 4'd0 }, { 4'd0, 4'd0 },
	{ 4'd0, -4'd2 }, { 4'd0, -4'b1 }, { 4'd0, 4'd1 }, { 4'd0, 4'd0 },
	{ 4'd3, 4'd0 }, { 4'd2, 4'd0 }, { 4'd1, 4'd0 }, { 4'd0, 4'd0 }
};

parameter IW = 32'd128; // 4 * 2 * 4 * 4;
parameter RW = 32'd32; // 4 * 2 * 4;

wire i_pls_c;
wire i_pls_e;
wire i_pls_w;
wire i_pls_s;
wire i_pls_n;

wire i_sync_vs;
wire i_sync_hs;
wire i_sync_va;
wire i_sync_ha;
wire i_sync_de;

reg [4:0] blk_pos_x;
reg [4:0] blk_pos_y;
reg [1023:0] board;
reg [3:0] blk_id;
reg [1:0] blk_rad;
wire [3:0] po_blk_id;
assign po_blk_id = blk_id + 4'd1;

wire [9:0] blk_offset;
assign blk_offset = { 6'b0, blk_id } * IW + { 8'b0, blk_rad } * RW;

wire [9:0] blk_abs_x_1;
wire [9:0] blk_abs_y_1;
wire [9:0] blk_abs_x_2;
wire [9:0] blk_abs_y_2;
wire [9:0] blk_abs_x_3;
wire [9:0] blk_abs_y_3;
wire [9:0] blk_abs_x_4;
wire [9:0] blk_abs_y_4;

assign blk_abs_x_1 = { 5'b0, blk_pos_x } + { {6{BLOCKS[blk_offset+ 3]}}, BLOCKS[blk_offset+ 0 +: 4] };
assign blk_abs_y_1 = { 5'b0, blk_pos_y } + { {6{BLOCKS[blk_offset+ 7]}}, BLOCKS[blk_offset+ 4 +: 4] };
assign blk_abs_x_2 = { 5'b0, blk_pos_x } + { {6{BLOCKS[blk_offset+11]}}, BLOCKS[blk_offset+ 8 +: 4] };
assign blk_abs_y_2 = { 5'b0, blk_pos_y } + { {6{BLOCKS[blk_offset+15]}}, BLOCKS[blk_offset+12 +: 4] };
assign blk_abs_x_3 = { 5'b0, blk_pos_x } + { {6{BLOCKS[blk_offset+19]}}, BLOCKS[blk_offset+16 +: 4] };
assign blk_abs_y_3 = { 5'b0, blk_pos_y } + { {6{BLOCKS[blk_offset+23]}}, BLOCKS[blk_offset+20 +: 4] };
assign blk_abs_x_4 = { 5'b0, blk_pos_x } + { {6{BLOCKS[blk_offset+27]}}, BLOCKS[blk_offset+24 +: 4] };
assign blk_abs_y_4 = { 5'b0, blk_pos_y } + { {6{BLOCKS[blk_offset+31]}}, BLOCKS[blk_offset+28 +: 4] };

wire [9:0] blk_offset_1;
wire [9:0] blk_offset_2;
wire [9:0] blk_offset_3;
wire [9:0] blk_offset_4;

assign blk_offset_1 = (blk_abs_y_1 * 10'd10 + blk_abs_x_1) * 10'd4;
assign blk_offset_2 = (blk_abs_y_2 * 10'd10 + blk_abs_x_2) * 10'd4;
assign blk_offset_3 = (blk_abs_y_3 * 10'd10 + blk_abs_x_3) * 10'd4;
assign blk_offset_4 = (blk_abs_y_4 * 10'd10 + blk_abs_x_4) * 10'd4;

wire [9:0] pox_offset_1;
wire [9:0] pox_offset_2;
wire [9:0] pox_offset_3;
wire [9:0] pox_offset_4;

assign pox_offset_1 = blk_offset_1 + 10'd4;
assign pox_offset_2 = blk_offset_2 + 10'd4;
assign pox_offset_3 = blk_offset_3 + 10'd4;
assign pox_offset_4 = blk_offset_4 + 10'd4;

wire [9:0] mox_offset_1;
wire [9:0] mox_offset_2;
wire [9:0] mox_offset_3;
wire [9:0] mox_offset_4;

assign mox_offset_1 = blk_offset_1 - 10'd4;
assign mox_offset_2 = blk_offset_2 - 10'd4;
assign mox_offset_3 = blk_offset_3 - 10'd4;
assign mox_offset_4 = blk_offset_4 - 10'd4;

wire [9:0] poy_offset_1;
wire [9:0] poy_offset_2;
wire [9:0] poy_offset_3;
wire [9:0] poy_offset_4;

assign poy_offset_1 = blk_offset_1 + 10'd40;
assign poy_offset_2 = blk_offset_2 + 10'd40;
assign poy_offset_3 = blk_offset_3 + 10'd40;
assign poy_offset_4 = blk_offset_4 + 10'd40;

wire [9:0] pr_offset;
assign pr_offset = blk_id * IW + ((blk_rad + 1) % 4) * RW;

wire [9:0] blk_abs_x_pr_1;
wire [9:0] blk_abs_x_pr_2;
wire [9:0] blk_abs_x_pr_3;
wire [9:0] blk_abs_x_pr_4;
wire [9:0] blk_abs_y_pr_1;
wire [9:0] blk_abs_y_pr_2;
wire [9:0] blk_abs_y_pr_3;
wire [9:0] blk_abs_y_pr_4;

assign blk_abs_x_pr_1 = { 5'b0, blk_pos_x } + { {6{BLOCKS[pr_offset+ 3]}}, BLOCKS[pr_offset+ 0 +: 4] };
assign blk_abs_y_pr_1 = { 5'b0, blk_pos_y } + { {6{BLOCKS[pr_offset+ 7]}}, BLOCKS[pr_offset+ 4 +: 4] };
assign blk_abs_x_pr_2 = { 5'b0, blk_pos_x } + { {6{BLOCKS[pr_offset+11]}}, BLOCKS[pr_offset+ 8 +: 4] };
assign blk_abs_y_pr_2 = { 5'b0, blk_pos_y } + { {6{BLOCKS[pr_offset+15]}}, BLOCKS[pr_offset+12 +: 4] };
assign blk_abs_x_pr_3 = { 5'b0, blk_pos_x } + { {6{BLOCKS[pr_offset+19]}}, BLOCKS[pr_offset+16 +: 4] };
assign blk_abs_y_pr_3 = { 5'b0, blk_pos_y } + { {6{BLOCKS[pr_offset+23]}}, BLOCKS[pr_offset+20 +: 4] };
assign blk_abs_x_pr_4 = { 5'b0, blk_pos_x } + { {6{BLOCKS[pr_offset+27]}}, BLOCKS[pr_offset+24 +: 4] };
assign blk_abs_y_pr_4 = { 5'b0, blk_pos_y } + { {6{BLOCKS[pr_offset+31]}}, BLOCKS[pr_offset+28 +: 4] };

wire [9:0] pr_offset_1;
wire [9:0] pr_offset_2;
wire [9:0] pr_offset_3;
wire [9:0] pr_offset_4;

assign pr_offset_1 = (blk_abs_y_pr_1 * 10 + blk_abs_x_pr_1) * 4;
assign pr_offset_2 = (blk_abs_y_pr_2 * 10 + blk_abs_x_pr_2) * 4;
assign pr_offset_3 = (blk_abs_y_pr_3 * 10 + blk_abs_x_pr_3) * 4;
assign pr_offset_4 = (blk_abs_y_pr_4 * 10 + blk_abs_x_pr_4) * 4;

reg [24:0] drop_counter;

reg [3:0] state;

parameter STATE_PLAY = 4'd0;
parameter STATE_RESET = 4'd1;
parameter STATE_DELETE = 4'd2;
parameter STATE_PUT = 4'd3;
parameter STATE_DELETE_CHECK = 4'd4;
parameter STATE_DELETE_MOVE_1 = 4'd5;
parameter STATE_DELETE_MOVE_2 = 4'd6;
parameter STATE_GAME_OVER = 4'd7;
parameter STATE_JUDGE = 4'd8;

reg [9:0] target_line;
reg [9:0] drop_line_count;

wire [9:0] drop_target_line_board_offset;
assign drop_target_line_board_offset = target_line * 40;

wire [9:0] drop_dest_line_board_offset;
assign drop_dest_line_board_offset = (target_line + drop_line_count) * 40;

integer i;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		blk_pos_x <= 5'd4;
		blk_pos_y <= 5'd0;
		blk_id <= 4'b0;
		blk_rad <= 2'b0;
		board <= 1024'b0;
		drop_counter <= 25'b0;
		target_line <= 10'd20;
		drop_line_count <= 10'b0;
		state <= STATE_PLAY;
	end else begin
		// reset game
		if (i_pls_s != 0) begin
			board <= 1025'b0;
			state <= STATE_RESET;
		end
		
		if (state == STATE_RESET) begin
			blk_pos_x <= 5'd4;
			blk_pos_y <= 5'd0;
			blk_id <= (blk_id == 10'd6 ? 4'b0 : blk_id + 4'b1);
			blk_rad <= 2'b0;
			drop_counter <= 25'b0;
			target_line <= 10'd20;
			drop_line_count <= 10'b0;
			
			// state <= STATE_PLAY;
			state <= STATE_JUDGE;
		end
		
		if (state == STATE_JUDGE) begin
			if (
				board[blk_offset_1 +: 4] != 4'b0 ||
				board[blk_offset_2 +: 4] != 4'b0 ||
				board[blk_offset_3 +: 4] != 4'b0 ||
				board[blk_offset_4 +: 4] != 4'b0
			) begin
				state <= STATE_GAME_OVER;
			end else begin
				state <= STATE_PLAY;
			end			
		end

		// move right
		if (
			state == STATE_PLAY &&
			i_pls_e != 0 &&
			blk_abs_x_1 < 10'd9 &&
			blk_abs_x_2 < 10'd9 &&
			blk_abs_x_3 < 10'd9 &&
			blk_abs_x_4 < 10'd9 &&
			board[pox_offset_1 +: 4] == 4'b0 &&
			board[pox_offset_2 +: 4] == 4'b0 &&
			board[pox_offset_3 +: 4] == 4'b0 &&
			board[pox_offset_4 +: 4] == 4'b0
		) begin
			blk_pos_x <= blk_pos_x + 5'd1;
		end

		// move left
		if (
			state == STATE_PLAY &&
			i_pls_w != 0 &&
			blk_abs_x_1 > 10'd0 &&
			blk_abs_x_2 > 10'd0 &&
			blk_abs_x_3 > 10'd0 &&
			blk_abs_x_4 > 10'd0 &&
			board[mox_offset_1 +: 4] == 4'b0 &&
			board[mox_offset_2 +: 4] == 4'b0 &&
			board[mox_offset_3 +: 4] == 4'b0 &&
			board[mox_offset_4 +: 4] == 4'b0
		) begin
			blk_pos_x <= blk_pos_x - 5'd1;
		end

		// rotate
		if (
			state == STATE_PLAY &&
			i_pls_n != 0 &&
			board[pr_offset_1 +: 4] == 4'b0 && board[pr_offset_2 +: 4] == 4'b0 &&
			board[pr_offset_3 +: 4] == 4'b0 && board[pr_offset_4 +: 4] == 4'b0 &&
			blk_abs_x_pr_1 < 10'd10 && blk_abs_y_pr_1 < 10'd20 &&
			blk_abs_x_pr_2 < 10'd10 && blk_abs_y_pr_2 < 10'd20 &&
			blk_abs_x_pr_3 < 10'd10 && blk_abs_y_pr_3 < 10'd20 &&
			blk_abs_x_pr_4 < 10'd10 && blk_abs_y_pr_4 < 10'd20
		) begin
			blk_rad <= (blk_rad + 2'b1) % 4;
		end

		// drop timer
		if (state == STATE_PLAY) begin
			drop_counter <= drop_counter + 25'b1;
		end

		// drop
		if (state == STATE_PLAY && drop_counter == 25'b0) begin
			if (
				board[poy_offset_1 +: 4] == 4'b0 &&
				board[poy_offset_2 +: 4] == 4'b0 &&
				board[poy_offset_3 +: 4] == 4'b0 &&
				board[poy_offset_4 +: 4] == 4'b0 &&
				blk_abs_y_1 < 10'd19 &&
				blk_abs_y_2 < 10'd19 &&
				blk_abs_y_3 < 10'd19 &&
				blk_abs_y_4 < 10'd19
			) begin
				blk_pos_y <= blk_pos_y + 5'b1;
			end else begin
				state <= STATE_PUT;
			end
		end

		if (state == STATE_PUT) begin
			state <= STATE_DELETE;

			board[blk_offset_1 + 0] <= po_blk_id[0];
			board[blk_offset_1 + 1] <= po_blk_id[1];
			board[blk_offset_1 + 2] <= po_blk_id[2];
			board[blk_offset_1 + 3] <= po_blk_id[3];
			board[blk_offset_2 + 0] <= po_blk_id[0];
			board[blk_offset_2 + 1] <= po_blk_id[1];
			board[blk_offset_2 + 2] <= po_blk_id[2];
			board[blk_offset_2 + 3] <= po_blk_id[3];
			board[blk_offset_3 + 0] <= po_blk_id[0];
			board[blk_offset_3 + 1] <= po_blk_id[1];
			board[blk_offset_3 + 2] <= po_blk_id[2];
			board[blk_offset_3 + 3] <= po_blk_id[3];
			board[blk_offset_4 + 0] <= po_blk_id[0];
			board[blk_offset_4 + 1] <= po_blk_id[1];
			board[blk_offset_4 + 2] <= po_blk_id[2];
			board[blk_offset_4 + 3] <= po_blk_id[3];
		end

//		if (state == STATE_DELETE) begin
//			state <= STATE_RESET;
//		end

		if (state == STATE_DELETE) begin
			if (target_line > 10'd20) begin
				state <= STATE_RESET;
			end else begin
				state <= STATE_DELETE_CHECK;
				
				target_line <= target_line - 10'b1;
			end
		end

		if (state == STATE_DELETE_CHECK) begin
			if (
				board[drop_target_line_board_offset + 0 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset + 4 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset + 8 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +12 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +16 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +20 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +24 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +28 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +32 +: 4] != 4'b0 &&
				board[drop_target_line_board_offset +36 +: 4] != 4'b0
			) begin
				state <= STATE_DELETE_MOVE_2;
				
				drop_line_count <= drop_line_count + 10'b1;
			end else if (drop_line_count != 10'b0) begin
				state <= STATE_DELETE_MOVE_1;
			end else begin
				state <= STATE_DELETE;
			end
		end

		// Move target line
		if (state == STATE_DELETE_MOVE_1) begin
			state <= STATE_DELETE_MOVE_2;
			
			for (i = 0; i < 40; i = i + 1) begin
				board[drop_dest_line_board_offset + i] <= board[drop_target_line_board_offset + i];
			end
		end

		// Delete target line
		if (state == STATE_DELETE_MOVE_2) begin
			state <= STATE_DELETE;

			for (i = 0; i < 40; i = i + 1) begin
				board[drop_target_line_board_offset + i] <= 1'b0;
			end
		end
	end
end

button_detector A0_BUTTON (
	.clk (clk),//i
	.rst_n (rst_n),//i
	.BUTTON_C (i_button_c),//i
	.BUTTON_E (i_button_e),//i
	.BUTTON_W (i_button_w),//i
	.BUTTON_S (i_button_s),//i
	.BUTTON_N (i_button_n),//i
	.O_PLS_BUTTON_C (i_pls_c),//o
	.O_PLS_BUTTON_E (i_pls_e),//o
	.O_PLS_BUTTON_W	(i_pls_w),//o
	.O_PLS_BUTTON_S	(i_pls_s),//o
	.O_PLS_BUTTON_N	(i_pls_n) //o
);

sync_gen A1_SYNC (
	.disp_clk (clk),//i
	.rst_disp_n (rst_n),//i
	.o_sync_vs (i_sync_vs),//o
	.o_sync_hs (i_sync_hs),//o
	.o_sync_va (i_sync_va),//o
	.o_sync_ha (i_sync_ha),//o
	.o_sync_de (i_sync_de) //o
);

draw_rect #(.BLOCKS(BLOCKS), .IW(IW), .RW(RW)) A2_DRAW (
	.clk (clk),//i
	.rst_n (rst_n),//i
	.i_sync_vs (i_sync_vs),//i
	.i_sync_hs (i_sync_hs),//i
	.i_sync_va (i_sync_va),//i
	.i_sync_ha (i_sync_ha),//i
	.i_sync_de (i_sync_de),//i
	.blk_pos_x (blk_pos_x),
	.blk_pos_y (blk_pos_y),
	.blk_id (blk_id),
	.po_blk_id (po_blk_id),
	.blk_rad (blk_rad),
	.board (board),
	.state (state),
	.o_sync_vs (o_sync_vs),//o
	.o_sync_hs (o_sync_hs),//o
	.o_sync_va (o_sync_va),//o
	.o_sync_ha (o_sync_ha),//o
	.o_sync_de (o_sync_de),//o
	.o_sync_red (o_sync_red),//o[ 8-1: 0]
	.o_sync_grn (o_sync_grn),//o[ 8-1: 0]
	.o_sync_blu (o_sync_blu) //o[ 8-1: 0]
);

endmodule
