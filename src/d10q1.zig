const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

const Paths = struct { left: []const u8, right: []const u8 };

pub fn main() !u64 {
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d10.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // summer times
    var lines = std.ArrayList([]u8).init(page_allocator);
    var cur_location: [2]i16 = .{ 0, 0 };
    // Setting this to whatever doesn't matter since the first direction is arbitrary
    // makes sure we don't backtrack
    var prev_location: [2]i16 = .{ 0, 0 };
    while (try stream.readUntilDelimiterOrEofAlloc(page_allocator, '\n', 141)) |line| {
        var i: u16 = 0;
        while (i < line.len) : (i += 1) {
            if (line[i] == 'S') {
                // since we haven't appended the current line yet, I'll just assume
                // we have already started walking by looking at the input for the sake of time
                prev_location[0] = @intCast(lines.items.len);
                prev_location[1] = @intCast(i);
                // The first step we should take
                cur_location[0] = @intCast(lines.items.len + 1);
                cur_location[1] = @intCast(i);
            }
        }
        lines.append(line) catch unreachable;
    }
    const lines_arr = lines.toOwnedSlice() catch unreachable;
    var steps: u16 = 1;
    while (true) {
        const res = move(&cur_location, &prev_location, lines_arr);
        steps += 1;
        if (res == true) return steps / 2;
    }
    unreachable;
}

fn move(cur_location: *[2]i16, prev_location: *[2]i16, lines_arr: [][]u8) bool {
    const cur_symbol = lines_arr[@intCast(cur_location[0])][@intCast(cur_location[1])];
    var delta: [2]i2 = .{ 0, 0 };
    if (cur_symbol == 'S') {
        return true;
    }
    if (cur_symbol == 'F') {
        if (cur_location.*[0] == prev_location.*[0]) {
            delta[0] = 1;
        } else {
            delta[1] = 1;
        }
    } else if (cur_symbol == 'J') {
        if (cur_location.*[0] == prev_location.*[0]) {
            delta[0] = -1;
        } else {
            delta[1] = -1;
        }
    } else if (cur_symbol == '7') {
        if (cur_location.*[0] == prev_location.*[0]) {
            delta[0] = 1;
        } else {
            delta[1] = -1;
        }
    } else if (cur_symbol == 'L') {
        if (cur_location.*[0] == prev_location.*[0]) {
            delta[0] = -1;
        } else {
            delta[1] = 1;
        }
    } else if (cur_symbol == '-') {
        if (cur_location.*[1] > prev_location.*[1]) {
            delta[1] = 1;
        } else {
            delta[1] = -1;
        }
    } else if (cur_symbol == '|') {
        if (cur_location.*[0] > prev_location.*[0]) {
            delta[0] = 1;
        } else {
            delta[0] = -1;
        }
    }
    prev_location.*[0] = cur_location.*[0];
    prev_location.*[1] = cur_location.*[1];
    cur_location.*[0] += delta[0];
    cur_location.*[1] += delta[1];
    return false;
}
