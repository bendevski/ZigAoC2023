const std = @import("std");
const print = std.debug.print;

pub fn q2() !u32 {
    //Q2 uses the same txt as q1
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

/// Gets the first and last digit present in a string
/// We also take worded out digits into account
/// meaning one == 1
/// Note: Assumes that there is at least 2 digits in
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
        } else {
            const firstSearch = isDigit(line[i..]);
            if (firstSearch != -1) {
                first = @intCast(firstSearch);
                break;
            }
        }
    }
    // Search from the back until we hit a digit
    i = line.len - 1;
    while (i >= 0) : (i -= 1) {
        if (std.ascii.isDigit(line[i])) {
            second = std.fmt.charToDigit(line[i], 10) catch unreachable;
            break;
        } else {
            const secondSearch = isDigit(line[i..]);
            if (secondSearch != -1) {
                second = @intCast(secondSearch);
                break;
            }
        }
    }
    print("{d}, {d}, {s}\n", .{ first, second, line });
    return 10 * first + second;
}

const numbers = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
fn isDigit(cur: []u8) i8 {
    var cur_number: u8 = 0;
    // Loop through all the numbers
    while (cur_number < 10) : (cur_number += 1) {
        var cur_idx: usize = 0;
        var mismatch = false;
        // If theres any difference mismatch will be set to true an we'll go onto the next outer loop
        while (cur_idx < numbers[cur_number].len) : (cur_idx += 1) {
            // If we reach the end of the string it means it's not what we're looking for
            if (cur_idx >= cur.len) {
                mismatch = true;
                break;
            }
            if (cur[cur_idx] != numbers[cur_number][cur_idx]) {
                mismatch = true;
                break;
            }
        }
        // All the characters were the same, we've found a match
        if (mismatch == false) return @intCast(cur_number);
    }
    return -1;
}
