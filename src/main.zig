const std = @import("std");
const print = std.debug.print;
const q2 = @import("q4.zig");
pub fn main() !void {
    const q1_answer = try q2.q4();
    print("{any}\n", .{q1_answer});
}
