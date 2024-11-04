const std = @import("std");
const Error = error{Stuff};
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
    while (i < seeds.len - 1) : (i += 2) {
        const seed_value = follow_seed(&main_arr_as_slice, seeds[i], seeds[i + 1], 0);
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
fn follow_seed(arr: *[][][]usize, starting: usize, luft: usize, step: u8) usize {
    if (step == 7) return starting;
    // The options for mappings to send to the next level
    var opt_arr_list = std.ArrayList([]usize).init(std.heap.page_allocator);
    // This will hold the ranges we will pass to the next steps unchanged
    // since there are some numbers that can avoid being mapped
    var excluded_ranges = std.ArrayList([2]usize).init(std.heap.page_allocator);
    excluded_ranges.append(.{ starting, luft }) catch unreachable;
    // Each i is a conversion step
    var j: u8 = 0;
    // Each j is a possible range of numbers our current
    // number could fall into
    while (j < arr.*[step].len) : (j += 1) {
        const window_bottom = arr.*[step][j][1];
        const res_for_j = smallest_in_range_overlap(starting, starting + luft, window_bottom, window_bottom + arr.*[step][j][2]) catch null;
        if (res_for_j != null) {
            opt_arr_list.append(res_for_j) catch unreachable;
        }
        var exc_i: usize = 0;
        while (exc_i < excluded_ranges.items.len) : (exc_i += 1) {
            const cur_range = excluded_ranges.items[exc_i];
            const after_exclusion = exclude_range(cur_range[0], cur_range[0] + cur_range[1], window_bottom, window_bottom + arr.*[step][j][2]) catch null;
            if (after_exclusion == null) continue;
            if (after_exclusion.len == 2) {
                excluded_ranges.items[exc_i] = after_exclusion[0];
                excluded_ranges.append(after_exclusion[1]) catch unreachable;
            } else {
                excluded_ranges.items[exc_i] = after_exclusion;
            }
        }
    }
    const excluded_ranges_slice = excluded_ranges.toOwnedSlice();
    opt_arr_list.appendSlice(excluded_ranges_slice) catch unreachable;
    var iterator: usize = 0;
    var acc: usize = std.math.maxInt(usize);
    while (iterator < opt_arr_list.items.len) : (iterator += 1) {
        const cur_bottom = follow_seed(arr, opt_arr_list[iterator][0], opt_arr_list[iterator][1], step + 1);
        if (acc > cur_bottom) acc = cur_bottom;
    }
    return acc;
}

fn smallest_in_range_overlap(available_min: usize, available_max: usize, band_min: usize, band_max: usize) Error![2]usize {
    if (available_min > band_max or available_max < band_min) {
        return Error.Stuff;
    }
    const min_in_range = switch (available_min > band_min) {
        true => available_min,
        false => band_min,
    };
    const max_in_range = switch (available_max > band_max) {
        true => band_max,
        false => available_max,
    };
    var output = std.heap.page_allocator.alloc(usize, 2) catch unreachable;
    // base
    output[0] = min_in_range;
    //luft
    output[1] = max_in_range - min_in_range;
    return output;
}
// Gives ranges from the available fields that are not in the band fields
// if available is 14 25 and band is 17 25
// output will be 14-16
fn exclude_range(available_min: usize, available_max: usize, band_min: usize, band_max: usize) ![][2]usize {
    var output = std.heap.page_allocator.alloc(usize, 2) catch unreachable;
    // Fully seperate sets
    if (available_min > band_max or band_min > available_max) {
        output[0] = available_min;
        output[1] = available_max - available_min;
        return output;
    }
    // available is subset, unusable
    if (available_min >= band_min and available_min <= band_max and available_max <= band_max) {
        return Error;
    }
    if (available_min > band_min) {
        output[0] = band_max;
        output[1] = available_max - band_max;
        return output;
    }
    if (available_max < band_max) {
        output[0] = available_min;
        output[1] = band_min;
        return output;
    }
    // the band is a subset of the avialable numbers that leaks on both ends
    output[0] = available_min;
    output[1] = band_min - available_min - 1;
    var second_output = std.heap.page_allocator.alloc(usize, 2);
    var full_output = std.heap.page_allocator.alloc([2]usize, 2);
    second_output[0] = band_max + 1;
    second_output[1] = available_max - (band_max + 1);
    full_output[0] = output;
    full_output[1] = second_output;
    return full_output;
}
