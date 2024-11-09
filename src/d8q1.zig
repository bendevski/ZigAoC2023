const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

const Paths = struct { left: []const u8, right: []const u8 };

pub fn main() !u32 {
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d8.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // each line is going to go into this buffer
    var buf: [1024]u8 = undefined;

    // summer times
    var map = std.StringHashMap(Paths).init(page_allocator);

    const instruction_set_buf = stream.readUntilDelimiterOrEof(&buf, '\n') catch unreachable orelse unreachable;
    const instruction_set = page_allocator.dupe(u8, instruction_set_buf) catch unreachable;
    std.debug.print("{s}\n", .{instruction_set});
    _ = stream.readUntilDelimiterOrEof(&buf, '\n') catch unreachable;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        read_line(line, &map);
    }
    var map_it = map.keyIterator();
    while (map_it.next()) |key| {
        std.debug.print("{s}\n", .{key.*});
    }
    const steps = following_the_map_that_leads_to_you("AAA", instruction_set, &map, 0);
    return steps;
}

fn following_the_map_that_leads_to_you(cur: []const u8, instructions: []u8, map: *std.StringHashMap(Paths), step: u16) u16 {
    if (std.mem.eql(u8, cur, "ZZZ")) return step;
    const iterator = @rem(step, instructions.len);
    const paths = map.*.get(cur) orelse unreachable;
    const next = switch (instructions[iterator]) {
        'L' => paths.left,
        'R' => paths.right,
        else => unreachable,
    };
    return following_the_map_that_leads_to_you(next, instructions, map, step + 1);
}

fn read_line(line: []u8, map: *std.StringHashMap(Paths)) void {
    std.debug.print("{s}\n", .{line});
    var first_it = std.mem.splitSequence(u8, line, " = (");
    const key = first_it.next() orelse unreachable;
    const dirs_with_cl_br = first_it.next() orelse unreachable;
    var dir_it = std.mem.splitSequence(u8, dirs_with_cl_br, ", ");
    const left_stack = dir_it.next() orelse unreachable;
    const right_w_br = dir_it.next() orelse unreachable;
    const right_stack = right_w_br[0 .. right_w_br.len - 1];
    const allocated_key = page_allocator.dupe(u8, key) catch unreachable;
    const left = page_allocator.dupe(u8, left_stack) catch unreachable;
    const right = page_allocator.dupe(u8, right_stack) catch unreachable;
    map.*.put(allocated_key, Paths{ .left = left, .right = right }) catch unreachable;
}
