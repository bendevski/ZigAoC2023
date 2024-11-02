const std = @import("std");
const print = std.debug.print;

pub fn q4() !u32 {
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
fn process_line(line: []u8) u16 {
    // result = {"Game x", "14 green..."}
    var it = std.mem.splitSequence(u8, line, ": ");
    // We don't need the game part
    _ = it.next() orelse unreachable;
    // {"14 green...",...}
    const game_info = it.next() orelse unreachable;
    // Splitting on "; " since the seperators have a space after them which we don't want
    var round_it = std.mem.splitSequence(u8, game_info, "; ");
    // We'll be keeping highscores in this Vector
    // let's say rgb
    var highscores = @Vector(3, u8){ 0, 0, 0 };
    while (round_it.next()) |round_string| {
        highscores = @max(highscores, valid_round(round_string));
    }
    // Get the product
    var acc: u16 = 1;
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        acc *= highscores[i];
    }
    return acc;
}
// Get the values through a loop with three ifs
fn valid_round(round_string: []const u8) @Vector(3, u8) {
    var values = std.mem.splitSequence(u8, round_string, ", ");
    var results = @Vector(3, u8){ 0, 0, 0 };
    while (values.next()) |number_color_pair| {
        // Really wish there was a simpler way to collect these, but such be life
        // result = {"14", "red"}
        var number_color_it = std.mem.splitAny(u8, number_color_pair, " ");
        const number_str = number_color_it.next() orelse unreachable;
        const number = std.fmt.parseInt(u8, number_str, 10) catch unreachable;
        const color = number_color_it.next() orelse unreachable;
        // Not sure if theres a cleaner way to do this
        // if there's any impossible pair return false
        if (std.mem.eql(u8, "red", color)) {
            results[0] = number;
        }
        if (std.mem.eql(u8, "green", color)) {
            results[1] = number;
        }
        if (std.mem.eql(u8, "blue", color)) {
            results[2] = number;
        }
    }
    return results;
}
