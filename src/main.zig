const std = @import("std");
const print = std.debug.print;
const q5 = @import("q5.zig");
pub fn main() !void {
    const q1_answer = try q5.main();
    print("{any}\n", .{q1_answer});
}
