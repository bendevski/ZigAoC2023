const std = @import("std");
const print = std.debug.print;
const question = @import("q6.zig");
pub fn main() !void {
    const answer = try question.main();
    print("{any}\n", .{answer});
}
