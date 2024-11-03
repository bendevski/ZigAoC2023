const std = @import("std");
const print = std.debug.print;

pub fn main() !usize {
    const fp = try std.fs.cwd().openFile("src/d4.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    var accumulator: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        accumulator += read_card(line);
    }
    return accumulator;
}

// Card 1: 32 123 321 | 83 24 32 13 23
fn read_card(line: []u8) usize {
    // Get rid of everything before :
    var junk_it = std.mem.splitSequence(u8, line, ": ");
    _ = junk_it.next() orelse unreachable;
    const card = junk_it.next() orelse unreachable;
    // Split into scoreboard and values
    var card_it = std.mem.splitSequence(u8, card, " | ");
    // Two splits
    const winners = card_it.next() orelse unreachable;
    const actual = card_it.next() orelse unreachable;
    // with ints
    const winners_arr = string_to_bool_array(winners);
    var actual_it = std.mem.splitSequence(u8, actual, " ");
    var accumulator: usize = 0;
    while (actual_it.next()) |number_str| {
        if (number_str.len == 0) continue;
        const number_int: usize = std.fmt.parseInt(u8, number_str, 10) catch unreachable;
        if (winners_arr[number_int] == 1) {
            if (accumulator > 0) {
                accumulator += accumulator;
            } else accumulator = 1;
        }
    }
    return accumulator;
}

// Turns a string of space seperated numbers
// into a u1 array (since I don't know how to memset bools in zig
// since the challenge uses at most 2 digit numbers it's a u8 sized arr
fn string_to_bool_array(line: []const u8) []u1 {
    var number_it = std.mem.splitSequence(u8, line, " ");
    var bool_arr = std.mem.zeroes([128]u1);
    while (number_it.next()) |number| {
        // For single digits
        if (number.len == 0) continue;
        const number_int = std.fmt.parseInt(u8, number, 10) catch unreachable;
        bool_arr[number_int] = 1;
    }
    // Have to do this so the data doesn't get overwritten later down the line
    return std.heap.page_allocator.dupe(u1, &bool_arr) catch unreachable;
}
