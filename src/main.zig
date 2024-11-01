const std = @import("std");
const print = std.debug.print;
const q2 = @import("q3.zig");
pub fn main() !void {
    const q1_answer = try q2.q3();
    print("{any}\n", .{q1_answer});
}
