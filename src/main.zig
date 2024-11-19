const std = @import("std");
const print = std.debug.print;
const question = @import("d11q1.zig");
pub fn main() !void {
    const answer: u64 = try question.main();
    print("{any}\n", .{answer});
}
