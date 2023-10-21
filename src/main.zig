const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});

const SCREENWIDTH: i32 = 900;
const SCREENHEIGHT: i32 = 900;
const CRAZY_AI = true;
const TOKENTEXTURES = "C:/Users/Alexander/Desktop/Zig/raylib_tests/src/resources/tokens.png";
const ORIGIN: ray.Vector2 = std.mem.zeroes(ray.Vector2);
const X = Token.X.getSource();
const O = Token.O.getSource();

pub fn main() void {
    var board = Board{ .width = @as(f32, SCREENWIDTH), .height = @as(f32, SCREENHEIGHT), .color = ray.WHITE, .entries = undefined };
    board.getEntries();
    var gamestatus = GameStatus.main_menu;
    var turn = Turn.player;
    var token_to_insert: TokenEntry = TokenEntry{};

    ray.InitWindow(SCREENWIDTH, SCREENHEIGHT, "Tic Tac Toe");
    const token_textures = ray.LoadTexture(TOKENTEXTURES);
    defer ray.UnloadTexture(token_textures);
    ray.SetTargetFPS(60);
    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);
        switch (gamestatus) {
            GameStatus.main_loop => gamestatus.runMainLoop(&board, &turn, &token_to_insert, token_textures),
            GameStatus.main_menu => gamestatus.menu(),
            else => gamestatus.endGame(&board),
        }

        ray.EndDrawing();
    }
    defer ray.CloseWindow();
}

const Token = enum {
    X,
    O,
    Empty,

    pub fn getSource(t: Token) ray.Rectangle {
        var source_rec: ray.Rectangle = undefined;
        source_rec = switch (t) {
            Token.X => ray.Rectangle{ .x = 35.0, .y = 35.0, .width = 200, .height = 200 },
            Token.O => ray.Rectangle{ .x = 250.0, .y = 35.0, .width = 200, .height = 200 },
            Token.Empty => undefined,
        };
        return source_rec;
    }

    pub fn isEmpty(t: Token) bool {
        return if (t == Token.Empty) true else false;
    }
};

const GameStatus = enum {
    X_won,
    O_won,
    tie,
    main_loop,
    main_menu,

    pub fn isWon(t: *GameStatus, board: *Board) void {
        const top_row = (!board.*.entries[0].token.isEmpty()) and (board.*.entries[0].token == board.*.entries[1].token) and (board.*.entries[0].token == board.*.entries[2].token);
        const mid_row = (!board.*.entries[3].token.isEmpty()) and (board.*.entries[3].token == board.*.entries[4].token) and (board.*.entries[3].token == board.*.entries[5].token);
        const bottom_row = (!board.*.entries[6].token.isEmpty()) and (board.*.entries[6].token == board.*.entries[7].token) and (board.*.entries[6].token == board.*.entries[8].token);
        //
        const left_col = (!board.*.entries[0].token.isEmpty()) and (board.*.entries[0].token == board.*.entries[3].token) and (board.*.entries[3].token == board.*.entries[6].token);
        const mid_col = (!board.*.entries[1].token.isEmpty()) and (board.*.entries[1].token == board.*.entries[4].token) and (board.*.entries[1].token == board.*.entries[7].token);
        const right_col = (!board.*.entries[2].token.isEmpty()) and (board.*.entries[2].token == board.*.entries[5].token) and (board.*.entries[2].token == board.*.entries[8].token);
        //
        const back_diag = (!board.*.entries[4].token.isEmpty()) and (board.*.entries[4].token == board.*.entries[0].token) and (board.*.entries[4].token == board.*.entries[8].token);
        const forward_diag = (!board.*.entries[4].token.isEmpty()) and (board.*.entries[4].token == board.*.entries[6].token) and (board.*.entries[4].token == board.*.entries[2].token);
        //
        var won_token = Token.Empty;
        if (top_row or left_col or back_diag) won_token = board.*.entries[0].token;
        if (mid_row or mid_col or back_diag or forward_diag) won_token = board.*.entries[4].token;
        if (bottom_row or right_col) won_token = board.*.entries[8].token;
        if (won_token == Token.Empty and board.isFull()) {
            t.* = GameStatus.tie;
            return;
        }
        t.* = switch (won_token) {
            Token.X => GameStatus.X_won,
            Token.O => GameStatus.O_won,
            Token.Empty => GameStatus.main_loop,
        };
    }

    pub fn menu(gamestatus: *GameStatus) void {
        ray.DrawText("CLICK TO PLAY", SCREENWIDTH / 4, SCREENHEIGHT / 2, 45, ray.WHITE);
        // ray.DrawRectanglePro(ray.Rectangle{ .height = SCREENHEIGHT / 9, .width = SCREENWIDTH / 4, .x = SCREENWIDTH / 4, .y = SCREENHEIGHT / 6 }, ORIGIN, 0, ray.GREEN);
        if (ray.IsMouseButtonPressed(0)) {
            gamestatus.* = GameStatus.main_loop;
        }
    }

    pub fn runMainLoop(gamestatus: *GameStatus, board: *Board, turn: *Turn, token_to_insert: *TokenEntry, token_textures: ray.Texture2D) void {
        gamestatus.*.isWon(board);
        //DISPLAY
        board.draw();
        board.displayTokens(token_textures);
        // INSERT
        if (ray.IsMouseButtonPressed(0)) {
            token_to_insert.getMove(turn, board);
            board.insertToken(token_to_insert, turn);
            board.debug();
        }
    }

    pub fn endGame(status: *GameStatus, board: *Board) void {
        const s = status.*;
        switch (s) {
            GameStatus.X_won => {
                ray.DrawText("X Has Won", SCREENWIDTH / 3, SCREENHEIGHT / 3, 45, ray.WHITE);
                ray.DrawText("To Play again Press the mouse button.", SCREENWIDTH / 9, SCREENHEIGHT / 2, 35, ray.WHITE);
            },
            GameStatus.O_won => {
                ray.DrawText("O Has Won", SCREENWIDTH / 3, SCREENHEIGHT / 3, 45, ray.WHITE);
                ray.DrawText("To Play again Press the mouse button.", SCREENWIDTH / 9, SCREENHEIGHT / 2, 35, ray.WHITE);
            },
            GameStatus.tie => {
                ray.DrawText("Tie Game", SCREENWIDTH / 3, SCREENHEIGHT / 3, 45, ray.WHITE);
                ray.DrawText("To Play again Press the mouse button.", SCREENWIDTH / 9, SCREENHEIGHT / 2, 35, ray.WHITE);
            },
            else => std.debug.print("ERROR\n", .{}),
        }
        if (ray.IsMouseButtonPressed(0)) {
            status.* = GameStatus.main_menu;
            board.getEntries();
        }
    }

    pub fn value(status: GameStatus, turn_count: i32) i32 {
        return switch (status) {
            GameStatus.X_won => turn_count - 30,
            GameStatus.O_won => 10 - turn_count,
            else => 0,
        };
    }
};

const Turn = enum {
    player,
    other,

    pub fn change(t: *Turn) void {
        const tmp = t.*;
        t.* = switch (tmp) {
            Turn.player => Turn.other,
            Turn.other => Turn.player,
        };
    }

    pub fn isPlayer(t: Turn) bool {
        return if (t == Turn.player) true else false;
    }
};

const TokenEntry = struct {
    token: Token = Token.Empty,
    point: ray.Vector2 = ray.Vector2{ .x = -10.0, .y = -10.0 },

    pub fn getPoint(entry: *TokenEntry, turn: *Turn, board: *Board) void {
        if (turn.isPlayer()) entry.* = getNearestPoint(ray.GetMousePosition(), board, turn) else entry.* = getComputerPoint(board, turn, CRAZY_AI);
    }
    pub fn getToken(entry: *TokenEntry, turn: *Turn) void {
        entry.*.token = if (turn.isPlayer()) Token.X else Token.O;
    }
    pub fn getMove(entry: *TokenEntry, turn: *Turn, board: *Board) void {
        entry.getToken(turn);
        entry.getPoint(turn, board);
    }

    pub fn bestMove(entry: *TokenEntry, board: *Board, turn: *Turn) void {
        var mock_board = board.*;
        var mock_status = GameStatus.main_loop;
        var moves: [9]TokenEntry = undefined;
        var scores: [9]i32 = std.mem.zeroes([9]i32);
        var index: usize = 0;
        var turns_taken: i32 = 0;
        var score = minimax(&mock_board, &mock_status, turn, turns_taken, &scores, &moves, index);
        // std.debug.print("{any}\n", .{score});
        // std.debug.print("\n\n---------SCORES---------\n", .{});
        // std.debug.print("{any}\n", .{scores});
        // std.debug.print("\n\n---------MOVES---------\n", .{});
        for (scores, moves) |s, m| {
            // m.debug_print();
            if (s >= score and m.token == Token.O) entry.* = m;
        }
    }

    pub fn getNearestPoint(point: ray.Vector2, board: *Board, turn: *Turn) TokenEntry {
        var distance: f32 = SCREENHEIGHT * SCREENWIDTH;
        var returnPoint: TokenEntry = undefined;
        if (turn.isPlayer()) returnPoint.token = Token.X;
        for (board.entries) |cur_square| {
            const cur_point = cur_square.point;
            const cur_distance = std.math.pow(f32, cur_point.x - point.x, 2) + std.math.pow(f32, cur_point.y - point.y, 2);
            returnPoint.point = if (distance > cur_distance) cur_point else returnPoint.point;
            distance = if (distance > cur_distance) cur_distance else distance;
        }
        // std.debug.print("{any}\n", .{returnPoint});
        return returnPoint;
    }

    pub fn getComputerPoint(board: *Board, turn: *Turn, unbeatable: bool) TokenEntry {
        var entry: TokenEntry = TokenEntry{};
        entry.token = Token.O;
        if (unbeatable) {
            entry.bestMove(board, turn);
            return entry;
        } else {
            for (board.entries) |cur_entry| {
                if (!cur_entry.token.isEmpty()) continue;
                entry.point = cur_entry.point;
            }
            // std.debug.print("Chosen Entry: {any}\n", .{entry});
            return entry;
        }
    }

    pub fn debug_print(e: TokenEntry) void {
        std.debug.print("TOKEN: {any} || X: {any}, Y: {any}\n", .{ e.token, e.point.x, e.point.y });
    }
};

const Board = struct {
    width: f32,
    height: f32,
    color: ray.Color = ray.WHITE,
    entries: [9]TokenEntry,

    pub fn draw(b: Board) void {
        var iwidth: i32 = @intFromFloat(b.width);
        var iheight: i32 = @intFromFloat(b.height);
        var hdiv = @divTrunc(iheight, 3);
        var wdiv = @divTrunc(iwidth, 3);
        ray.DrawLine(wdiv, 0, wdiv, iheight, b.color);
        ray.DrawLine(2 * wdiv, 0, 2 * wdiv, iheight, b.color);
        ray.DrawLine(0, hdiv, iwidth, hdiv, b.color);
        ray.DrawLine(0, 2 * hdiv, iwidth, 2 * hdiv, b.color);
    }

    pub fn displayTokens(b: Board, token_textures: ray.Texture2D) void {
        for (b.entries) |entry| {
            const p = entry.point;
            const dest_rect = ray.Rectangle{ .x = p.x - (SCREENWIDTH / 12), .y = p.y - (SCREENHEIGHT / 12), .width = SCREENWIDTH / 6, .height = SCREENHEIGHT / 6 };
            switch (entry.token) {
                Token.X => ray.DrawTexturePro(token_textures, X, dest_rect, ORIGIN, 0.0, ray.RED),
                Token.O => ray.DrawTexturePro(token_textures, O, dest_rect, ORIGIN, 0.0, ray.BLUE),
                Token.Empty => continue,
            }
        }
    }

    pub fn insertToken(board: *Board, entry: *TokenEntry, turn: *Turn) void {
        if (!board.validMove(entry)) return;
        for (0.., board.*.entries) |i, cur_entry| {
            if (std.meta.eql(cur_entry.point, entry.point)) {
                board.*.entries[i] = entry.*;
                turn.change();
                return;
            }
        }
    }

    pub fn validMove(board: *Board, entry: *TokenEntry) bool {
        if (entry.token.isEmpty()) return true;
        for (board.entries) |cur_entry| {
            if (!std.meta.eql(entry.point, cur_entry.point)) continue;
            if (!cur_entry.token.isEmpty()) return false;
        }
        return true;
    }

    pub fn getEntries(b: *Board) void {
        var idx: usize = 0;
        var centers: [9]TokenEntry = undefined;
        while (idx < 9) : (idx += 1) {
            var i: f32 = @floatFromInt(idx);
            var k: f32 = @mod((i * 2) + 1, 6);
            var j: f32 = @floor(i / 3) * 2 + 1;
            centers[idx] = TokenEntry{ .point = ray.Vector2{ .x = (k / 6.0) * b.width, .y = (j / 6.0) * b.height } };
        }
        b.*.entries = centers;
        return;
    }

    pub fn isFull(b: Board) bool {
        for (b.entries) |entry| {
            if (entry.token.isEmpty()) return false;
        }
        return true;
    }

    pub fn debug(b: *Board) void {
        for (b.entries, 0..) |e, i| {
            if (i > 0 and i % 3 == 0) std.debug.print("\n-----\n", .{});
            const tok = switch (e.token) {
                Token.X => "X",
                Token.O => "O",
                Token.Empty => " ",
            };
            std.debug.print("{s}", .{tok});
            if ((i + 1) % 3 != 0) std.debug.print("|", .{});
        }
        std.debug.print("\n\n", .{});
    }
};

// Util Functions

pub fn minimax(mock_board: *Board, mock_status: *GameStatus, turn: *Turn, turn_count: i32, scores: *[9]i32, moves: *[9]TokenEntry, index: usize) i32 {
    mock_status.isWon(mock_board);
    if (mock_board.isFull() or mock_status.* != GameStatus.main_loop) return mock_status.value(turn_count);
    var best_score: i32 = if (turn.isPlayer()) 1000 else -1000;
    var best_move = TokenEntry{};
    for (mock_board.entries) |move| {
        var m = move;
        m.token = if (turn.isPlayer()) Token.X else Token.O;
        if (mock_board.validMove(&m)) {
            // mock_board.debug();
            var undo = move;
            mock_board.insertToken(&m, turn);
            const score = minimax(mock_board, mock_status, turn, turn_count + 1, scores, moves, index + 1);
            undo.token = Token.Empty;
            mock_board.insertToken(&undo, turn);
            if (turn.isPlayer() and score <= best_score) {
                best_score = score;
                best_move = m;
            } else if (!turn.isPlayer() and score >= best_score) {
                best_score = score;
                best_move = m;
            }
        }
    }
    // mock_board.debug();
    scores.*[index] = best_score;
    moves.*[index] = best_move;
    return best_score;
}
