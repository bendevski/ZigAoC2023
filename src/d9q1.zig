const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

const Paths = struct { left: []const u8, right: []const u8 };

pub fn main() !i64 {
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d9.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // each line is going to go into this buffer
    var buf: [1024]u8 = undefined;

    // summer times
    var lines = std.ArrayList([]i32).init(page_allocator);

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        read_line(line, &lines);
    }
    const lines_arr = lines.toOwnedSlice() catch unreachable;
    var sum: i64 = 0;
    var i: u16 = 0;
    while (i < lines_arr.len) : (i += 1) {
        sum += get_next_in_sequence(lines_arr[i]);
    }
    return sum;
}

fn get_next_in_sequence(top_arr: []i32) i32 {
    std.debug.assert(top_arr.len != 0);
    var pyramid = std.ArrayList([]i32).init(page_allocator);
    pyramid.append(top_arr) catch unreachable;
    var i: u8 = 0;
    var all_zeroes: bool = true;
    while (i < pyramid.items.len) : (i += 1) {
        var cur_level = page_allocator.alloc(i32, pyramid.items[i].len - 1) catch unreachable;
        var j: u8 = 0;
        while (j < pyramid.items[i].len - 1) : (j += 1) {
            const diff = pyramid.items[i][j + 1] - pyramid.items[i][j];
            if (diff != 0) all_zeroes = false;
            cur_level[j] = diff;
        }
        pyramid.append(cur_level) catch unreachable;
        if (all_zeroes) break;
        all_zeroes = true;
    }
    var acc: i32 = 0;
    while (i > 0) : (i -= 1) {
        // add the last element of the current line to the accumulator
        acc += (pyramid.items[i][pyramid.items[i].len - 1]);
    }
    acc += (pyramid.items[0][pyramid.items[0].len - 1]);
    return acc;
}

fn read_line(line: []u8, map: *std.ArrayList([]i32)) void {
    var i = std.mem.splitSequence(u8, line, " ");
    var numer_of_elems: u16 = 0;
    var input = page_allocator.alloc(i32, 62) catch unreachable;
    while (i.next()) |num| {
        input[numer_of_elems] = std.fmt.parseInt(i32, num, 10) catch unreachable;
        numer_of_elems += 1;
    }
    map.*.append(input[0..numer_of_elems]) catch unreachable;
}
