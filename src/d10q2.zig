const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

const Paths = struct { left: []const u8, right: []const u8 };

pub fn main() !i64 {
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d10.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // summer times
    var lines = std.ArrayList([]u8).init(page_allocator);
    // our shoelace array
    // the shoelace formula
    // https://en.wikipedia.org/wiki/Shoelace_formula
    var coords = std.ArrayList([]i16).init(page_allocator);
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
                std.debug.print("{any}", .{cur_location});
                // first coord for shoelace
                const to_append = page_allocator.alloc(i16, 2) catch unreachable;
                to_append[0] = prev_location[0];
                to_append[1] = prev_location[1];
                coords.append(to_append) catch unreachable;
            }
        }
        lines.append(@constCast(line)) catch unreachable;
    }
    var lines_arr = lines.toOwnedSlice() catch unreachable;
    var steps: u16 = 0;
    while (true) {
        const res = move(&cur_location, &prev_location, &lines_arr, &coords);
        if (res) break;
        steps += 1;
    }
    const coords_arr = coords.toOwnedSlice() catch unreachable;
    std.debug.print("{any}\n", .{coords_arr});
    var i: u16 = 0;
    var area_acc: i16 = 0;
    while (i < coords_arr.len - 1) : (i += 1) {
        area_acc += coords_arr[i][0] * coords_arr[i + 1][1];
        area_acc -= coords_arr[i][1] * coords_arr[i + 1][0];
    }
    area_acc = @divTrunc(area_acc, 2) + @rem(area_acc, 2);
    i = 0;
    const step1: i16 = @intCast(steps);
    const acc: i16 = area_acc - (@divTrunc(step1, 2) + @rem(step1, 2)) + 1;
    return acc;
}

fn move(cur_location: *[2]i16, prev_location: *[2]i16, lines_arr: *[][]u8, coords: *std.ArrayList([]i16)) bool {
    const cur_symbol = lines_arr.*[@intCast(cur_location[0])][@intCast(cur_location[1])];
    var delta: [2]i2 = .{ 0, 0 };
    if (cur_symbol == 'S') {
        const to_append = page_allocator.alloc(i16, 2) catch unreachable;
        to_append[0] = cur_location[0];
        to_append[1] = cur_location[1];
        coords.append(to_append) catch unreachable;
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
    const to_append = page_allocator.alloc(i16, 2) catch unreachable;
    to_append[0] = prev_location[0];
    to_append[1] = prev_location[1];
    coords.append(to_append) catch unreachable;
    return false;
}
