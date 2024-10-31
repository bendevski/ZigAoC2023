const std = @import("std");
const print = std.debug.print;

pub fn q1() !u32 {
    var file = try std.fs.cwd().openFile("src/q1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // each line is going to go into this buffer
    var buf: [1024]u8 = undefined;

    // summer times
    var summer: u32 = 0;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        summer += first_and_last_digit(line);
    }
    return summer;
}

/// Assumes that there is at least 2 digits in
/// the string. If there is 1 it will output giberish
/// if there are none it'll error out.
fn first_and_last_digit(line: []u8) u8 {
    var i: usize = 0;

    var first: u8 = undefined;
    var second: u8 = undefined;
    // Search from the front until we hit a digit
    while (i < line.len) : (i += 1) {
        if (std.ascii.isDigit(line[i])) {
            first = std.fmt.charToDigit(line[i], 10) catch unreachable;
            break;
        }
    }
    // Search from the back until we hit a digit
    i = line.len - 1;
    while (i >= 0) : (i -= 1) {
        if (std.ascii.isDigit(line[i])) {
            second = std.fmt.charToDigit(line[i], 10) catch unreachable;
            break;
        }
    }
    return 10 * first + second;
}
