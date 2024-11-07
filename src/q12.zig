const std = @import("std");
const Error = error{Stuff};
const print = std.debug.print;

pub fn main() !u128 {
    const fp = try std.fs.cwd().openFile("src/d6.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    const time = std.heap.page_allocator.dupe(u8, stream.readUntilDelimiter(&buf, '\n') catch unreachable) catch unreachable;
    const distance = (stream.readUntilDelimiter(&buf, '\n') catch unreachable);
    const tuple = time_and_distance_to_tuples(time, distance);
    var acc: usize = 1;
    acc = calculate_tuple_values(tuple);
    return acc;
}

// This one has annoying spaces, split doesnt cut it.
fn time_and_distance_to_tuples(time: []u8, distance: []u8) []usize {
    std.debug.print("{s} \n {s}\n", .{ time, distance });
    var time_garbage_it = std.mem.splitSequence(u8, time, ": ");
    var distance_garbage_it = std.mem.splitSequence(u8, distance, ": ");
    _ = time_garbage_it.next();
    _ = distance_garbage_it.next();
    const time_str = time_garbage_it.next() orelse unreachable;
    const distance_str = distance_garbage_it.next() orelse unreachable;
    var time_acc = std.ArrayList(u8).init(std.heap.page_allocator);
    var distance_acc = std.ArrayList(u8).init(std.heap.page_allocator);
    var time_pointer: u8 = 0;
    var distance_pointer: u8 = 0;
    while (time_pointer < time_str.len or distance_pointer < distance_str.len) {
        // go through all the spaces
        while (time_str[time_pointer] == ' ') time_pointer += 1;
        // again
        while (distance_str[distance_pointer] == ' ') distance_pointer += 1;
        // collect the full number
        while (time_pointer < time_str.len and time_str[time_pointer] != ' ') {
            time_acc.append(time_str[time_pointer]) catch unreachable;
            time_pointer += 1;
        }
        // again
        while (distance_pointer < distance_str.len and distance_str[distance_pointer] != ' ') {
            distance_acc.append(distance_str[distance_pointer]) catch unreachable;
            distance_pointer += 1;
        }
    }
    const cur_arr = std.heap.page_allocator.alloc(usize, 2) catch unreachable;
    // to owned slice technically turns them into strings
    const cur_time: []u8 = time_acc.toOwnedSlice() catch unreachable;
    const cur_distance: []u8 = distance_acc.toOwnedSlice() catch unreachable;
    cur_arr[0] = std.fmt.parseInt(usize, cur_time, 10) catch unreachable;
    cur_arr[1] = std.fmt.parseInt(usize, cur_distance, 10) catch unreachable;

    return cur_arr;
}

fn calculate_tuple_values(tuple: []usize) usize {
    const time = tuple[0];
    const distance = tuple[1];
    // starting at one cause 0 never beats anything
    var i: usize = 1;
    var acc: usize = 0;
    while (i <= time) : (i += 1) {
        if (time - i > distance / i) {
            acc += 1;
        }
    }
    return acc;
}
