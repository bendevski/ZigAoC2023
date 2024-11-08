const std = @import("std");
const print = std.debug.print;
const question = @import("d7q1.zig");
pub fn main() !void {
    const answer: u128 = try question.main();
    print("{any}\n", .{answer});
}
