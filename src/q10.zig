const std = @import("std");
const Error = error{Stuff};
const print = std.debug.print;

pub fn main() !u128 {
    const fp = try std.fs.cwd().openFile("src/d5.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    const seeds = get_seeds(stream.readUntilDelimiter(&buf, '\n') catch unreachable);
    // Since the transitions are well ordered in the input
    // we'll just use an array
    var main_arr: std.ArrayList([][]u128) = std.ArrayList([][]u128).init(std.heap.page_allocator);
    defer main_arr.deinit();
    // map_to_array
    // sorted array upper bound lower bound
    var cur_arr: std.ArrayList([]u128) = std.ArrayList([]u128).init(std.heap.page_allocator);
    defer cur_arr.deinit();
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        if (!std.ascii.isDigit(line[0])) {
            const cur_inputs = cur_arr.toOwnedSlice() catch unreachable;
            if (cur_inputs.len == 0) {
                continue;
            }
            main_arr.append(cur_inputs) catch unreachable;
            continue;
        }
        cur_arr.append(read_line_into_arr(line)) catch unreachable;
    }
    const cur_inputs = cur_arr.toOwnedSlice() catch unreachable;
    main_arr.append(cur_inputs) catch unreachable;

    var i: usize = 0;
    var holder: u128 = std.math.maxInt(u128);
    var main_arr_as_slice = main_arr.toOwnedSlice() catch unreachable;
    while (i < seeds.len - 1) : (i += 2) {
        const seed_value = follow_seed(&main_arr_as_slice, seeds[i], seeds[i + 1], 0);
        if (holder > seed_value) {
            holder = seed_value;
        }
    }
    return holder;
}

// Return the seeds as an array of numbers
fn get_seeds(line: []u8) []u128 {
    // We don't care about conversion names, since they're sorted anyway
    var gar_it = std.mem.splitSequence(u8, line, ": ");
    _ = gar_it.next() orelse unreachable;
    const seed_string = gar_it.next() orelse unreachable;
    var seed_it = std.mem.splitAny(u8, seed_string, " ");
    var seeds: std.ArrayList(u128) = std.ArrayList(u128).init(std.heap.page_allocator);
    while (seed_it.next()) |seed| {
        const int_seed = std.fmt.parseInt(u128, seed, 10) catch unreachable;
        seeds.append(int_seed) catch unreachable;
    }
    return seeds.toOwnedSlice() catch unreachable;
}

// Just read the line and return it as a tuple of numbers
fn read_line_into_arr(line: []u8) []u128 {
    var val_it = std.mem.splitSequence(u8, line, " ");
    var tuple: []u128 = std.heap.page_allocator.alloc(u128, 3) catch unreachable;
    var i: usize = 0;
    while (val_it.next()) |value| {
        const int_value = std.fmt.parseInt(u128, value, 10) catch unreachable;
        tuple[i] = int_value;
        i += 1;
    }
    return tuple;
}

// For a given first number follow it until the final conversion
fn follow_seed(arr: *[][][]u128, starting: u128, luft: u128, step: u8) u128 {
    if (step == 7) return starting;
    // The options for mappings to send to the next level
    var opt_arr_list = std.ArrayList([]u128).init(std.heap.page_allocator);
    // This will hold the ranges we will pass to the next steps unchanged
    // since there are some numbers that can avoid being mapped
    var excluded_ranges = std.ArrayList([]u128).init(std.heap.page_allocator);
    const what: []u128 = std.heap.page_allocator.dupe(u128, &.{ starting, luft }) catch unreachable;
    excluded_ranges.append(what) catch unreachable;
    // Each i is a conversion step
    var j: u8 = 0;
    // Each j is a possible range of numbers our current
    // number could fall into
    while (j < arr.*[step].len) : (j += 1) {
        const window_bottom = arr.*[step][j][1];
        const res_for_j = smallest_in_range_overlap(starting, starting + luft, window_bottom, window_bottom + arr.*[step][j][2]) catch null;
        if (res_for_j != null) {
            var guaranteed_res = res_for_j orelse unreachable;
            guaranteed_res[0] = (guaranteed_res[0] - window_bottom) + arr.*[step][j][0];
            opt_arr_list.append(guaranteed_res) catch unreachable;
        }
        var exc_i: usize = 0;
        while (exc_i < excluded_ranges.items.len) : (exc_i += 1) {
            const cur_range = excluded_ranges.items[exc_i];
            const after_exclusion = exclude_range(cur_range[0], cur_range[0] + cur_range[1], window_bottom, window_bottom + arr.*[step][j][2]) catch null;
            if (after_exclusion == null) {
                _ = excluded_ranges.orderedRemove(exc_i);
                continue;
            }
            // type stuff
            const a_e_guaranteed = after_exclusion orelse unreachable;
            excluded_ranges.items[exc_i] = a_e_guaranteed[0];
            if (a_e_guaranteed.len == 2) {
                excluded_ranges.append(a_e_guaranteed[1]) catch unreachable;
            }
        }
    }
    const excluded_ranges_slice = excluded_ranges.toOwnedSlice() catch unreachable;
    opt_arr_list.appendSlice(excluded_ranges_slice) catch unreachable;
    const opt_arr_slice = opt_arr_list.toOwnedSlice() catch unreachable;
    var iterator: usize = 0;
    var acc: u128 = std.math.maxInt(u128);
    while (iterator < opt_arr_slice.len) : (iterator += 1) {
        const cur_bottom = follow_seed(arr, opt_arr_slice[iterator][0], opt_arr_slice[iterator][1], step + 1);
        if (acc > cur_bottom) {
            acc = cur_bottom;
        }
    }
    return acc;
}

fn smallest_in_range_overlap(available_min: u128, available_max: u128, band_min: u128, band_max: u128) Error![]u128 {
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
    var output = std.heap.page_allocator.alloc(u128, 2) catch unreachable;
    // base
    output[0] = min_in_range;
    //luft
    output[1] = max_in_range - min_in_range;
    return output;
}
// Gives ranges from the available fields that are not in the band fields
// if available is 14 25 and band is 17 25
// output will be 14-16
fn exclude_range(available_min: u128, available_max: u128, band_min: u128, band_max: u128) ![][]u128 {
    var output: []u128 = std.heap.page_allocator.alloc(u128, 2) catch unreachable;
    // Fully seperate sets
    if (available_min > band_max or band_min > available_max) {
        var full_output = std.heap.page_allocator.alloc([]u128, 1) catch unreachable;
        output[0] = available_min;
        output[1] = available_max - available_min;
        full_output[0] = output;
        return full_output;
    }
    // available is subset, unusable
    if (available_min >= band_min and available_min <= band_max and available_max <= band_max) {
        return Error.Stuff;
    }
    if (available_min >= band_min) {
        var full_output = std.heap.page_allocator.alloc([]u128, 1) catch unreachable;
        output[0] = band_max;
        output[1] = available_max - band_max;
        full_output[0] = output;
        return full_output;
    }
    if (available_max <= band_max) {
        var full_output = std.heap.page_allocator.alloc([]u128, 1) catch unreachable;
        output[0] = available_min;
        output[1] = band_min - available_min - 1;
        full_output[0] = output;
        return full_output;
    }
    // the band is a subset of the avialable numbers that leaks on both ends
    output[0] = available_min;

    output[1] = band_min - available_min - 1;
    var second_output = std.heap.page_allocator.alloc(u128, 2) catch unreachable;
    var full_output = std.heap.page_allocator.alloc([]u128, 2) catch unreachable;
    second_output[0] = band_max + 1;
    second_output[1] = available_max - (band_max + 1);
    full_output[0] = output;
    full_output[1] = second_output;
    return full_output;
}
