const std = @import("std");
const print = std.debug.print;
const q1 = @import("q1.zig");
pub fn main() !void {
    const q1_answer = try q1.q1();
    print("{any}\n", .{q1_answer});
}
