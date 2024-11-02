const std = @import("std");
const print = std.debug.print;

pub fn q3() !u32 {
    var file = try std.fs.cwd().openFile("src/d2.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // each line is going to go into this buffer
    var buf: [1024]u8 = undefined;

    // summer times
    var summer: u32 = 0;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        summer += process_line(line);
    }
    return summer;
}

// Returns game id if the game is valid, 0 otherwise
fn process_line(line: []u8) u8 {
    // result = {"Game x", "14 green..."}
    var it = std.mem.splitSequence(u8, line, ": ");
    // result = {"Game", "x"}
    var game_string_it = std.mem.splitAny(u8, it.next() orelse unreachable, " ");
    // result = "Game"
    _ = game_string_it.next() orelse unreachable;
    // result = "x" AKA game number
    const game_number = game_string_it.next() orelse unreachable;
    // Now we need to process the rest
    const game_info = it.next() orelse unreachable;
    // Splitting on "; " since the seperators have a space after them which we don't want
    var round_it = std.mem.splitSequence(u8, game_info, "; ");
    while (round_it.next()) |round_string| {
        // If any round is invalid the game is invalid
        if (!valid_round(round_string)) return 0;
    }
    return std.fmt.parseInt(u8, game_number, 10) catch unreachable;
}
// Checks if a round is valid by through a loop with three ifs
fn valid_round(round_string: []const u8) bool {
    var values = std.mem.splitSequence(u8, round_string, ", ");
    while (values.next()) |number_color_pair| {
        // Really wish there was a simpler way to collect these, but such be life
        // result = {"14", "red"}
        var number_color_it = std.mem.splitAny(u8, number_color_pair, " ");
        const number_str = number_color_it.next() orelse unreachable;
        const number = std.fmt.parseInt(u16, number_str, 10) catch unreachable;
        const color = number_color_it.next() orelse unreachable;
        // Not sure if theres a cleaner way to do this
        // if there's any impossible pair return false
        if (std.mem.eql(u8, "red", color) and number > 12) {
            return false;
        }
        if (std.mem.eql(u8, "green", color) and number > 13) {
            return false;
        }
        if (std.mem.eql(u8, "blue", color) and number > 14) {
            return false;
        }
    }
    // No impossible pairs were found, return true
    return true;
}
