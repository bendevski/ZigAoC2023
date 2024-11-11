const std = @import("std");
const print = std.debug.print;
const question = @import("d9q2.zig");
pub fn main() !void {
    const answer: i64 = try question.main();
    print("{any}\n", .{answer});
}
