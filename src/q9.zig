const std = @import("std");
const print = std.debug.print;

pub fn main() !usize {
    const fp = try std.fs.cwd().openFile("src/d5.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    const seeds = get_seeds(stream.readUntilDelimiter(&buf, '\n') catch unreachable);
    // Since the transitions are well ordered in the input
    // we'll just use an array
    var main_arr: std.ArrayList([][]usize) = std.ArrayList([][]usize).init(std.heap.page_allocator);
    defer main_arr.deinit();
    // map_to_array
    // sorted array upper bound lower bound
    var cur_arr: std.ArrayList([]usize) = std.ArrayList([]usize).init(std.heap.page_allocator);
    defer cur_arr.deinit();
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        if (!std.ascii.isDigit(line[0])) {
            const cur_inputs = cur_arr.toOwnedSlice() catch unreachable;
            main_arr.append(cur_inputs) catch unreachable;
            continue;
        }
        cur_arr.append(read_line_into_arr(line)) catch unreachable;
    }
    const cur_inputs = cur_arr.toOwnedSlice() catch unreachable;
    main_arr.append(cur_inputs) catch unreachable;

    var i: usize = 0;
    var holder: usize = std.math.maxInt(usize);
    var main_arr_as_slice = main_arr.toOwnedSlice() catch unreachable;
    while (i < seeds.len) : (i += 1) {
        const seed_value = follow_seed(&main_arr_as_slice, seeds[i]);
        if (holder > seed_value) holder = seed_value;
    }
    return holder;
}

// Return the seeds as an array of numbers
fn get_seeds(line: []u8) []usize {
    // We don't care about conversion names, since they're sorted anyway
    var gar_it = std.mem.splitSequence(u8, line, ": ");
    _ = gar_it.next() orelse unreachable;
    const seed_string = gar_it.next() orelse unreachable;
    var seed_it = std.mem.splitAny(u8, seed_string, " ");
    var seeds: std.ArrayList(usize) = std.ArrayList(usize).init(std.heap.page_allocator);
    while (seed_it.next()) |seed| {
        const int_seed = std.fmt.parseInt(usize, seed, 10) catch unreachable;
        seeds.append(int_seed) catch unreachable;
    }
    return seeds.toOwnedSlice() catch unreachable;
}

// Just read the line and return it as a tuple of numbers
fn read_line_into_arr(line: []u8) []usize {
    var val_it = std.mem.splitSequence(u8, line, " ");
    var tuple: [3]usize = .{ 0, 0, 0 };
    var i: usize = 0;
    while (val_it.next()) |value| {
        const int_value = std.fmt.parseInt(usize, value, 10) catch unreachable;
        tuple[i] = int_value;
        i += 1;
    }
    return std.heap.page_allocator.dupe(usize, &tuple) catch unreachable;
}

// For a given first number follow it until the final conversion
fn follow_seed(arr: *[][][]usize, starting: usize) usize {
    // Mark which number we're currently working with
    var cur: usize = starting;
    // Each i is a conversion step
    var i: u8 = 0;
    while (i < arr.len) : (i += 1) {
        var j: u8 = 0;
        // Each j is a possible range of numbers our current
        // number could fall into
        while (j < arr.*[i].len) : (j += 1) {
            const min_in_range = arr.*[i][j][1];
            const max_in_range = min_in_range + arr.*[i][j][2];
            if (cur >= min_in_range and cur < max_in_range) {
                // since arr[i][j][1] gives us the minimum of the post conversion
                cur = (cur - min_in_range) + arr.*[i][j][0];
                break;
            }
        }
    }
    std.debug.print("\n", .{});
    return cur;
}
