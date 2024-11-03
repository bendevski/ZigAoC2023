const std = @import("std");
const print = std.debug.print;

const MapPoint = [2]usize;

pub fn main() !usize {
    var file = try std.fs.cwd().openFile("src/d3.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // each line is going to go into this buffer
    var buf: [1024]u8 = undefined;

    var whole_thing = std.ArrayList([]u8).init(std.heap.page_allocator);
    var symbol_locations = std.ArrayList(MapPoint).init(std.heap.page_allocator);
    var i: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Save the whole map for later use
        whole_thing.append(std.mem.Allocator.dupe(std.heap.page_allocator, u8, line) catch unreachable) catch unreachable;
        // Save an array of all the symbols
        symbol_locations.appendSlice(locations_of_gears(i, line)) catch unreachable;
        i += 1;
    }
    const ArrayMap = whole_thing.toOwnedSlice() catch unreachable;
    // Go through the symbols and search around them
    var total: usize = 0;
    const locations = symbol_locations.toOwnedSlice() catch unreachable;
    i = 0;
    while (i < locations.len) : (i += 1) {
        total += get_total_around_point(locations[i], ArrayMap);
    }
    return total;
}

// reads a line and saves where the gears in that line are
// in an array
fn locations_of_gears(line_num: usize, line: []u8) []MapPoint {
    var i: usize = 0;
    // might be wasting a bit of memory here but such be life
    var output_alist = std.ArrayList(MapPoint).init(std.heap.page_allocator);
    // look for any symbols
    while (i < line.len) : (i += 1) {
        if (line[i] == '*') {
            output_alist.append([2]usize{ line_num, i }) catch unreachable;
        }
    }
    return output_alist.toOwnedSlice() catch unreachable;
}

// find the sum of numbers around a point
// could be more memory efficient by only using three lines at a time
// if the number of ns is not 2 returns 0
fn get_total_around_point(loc: MapPoint, whole_thing: [][]u8) usize {
    var i: i4 = -1;
    var n_of_ns: u8 = 0;
    var product: usize = 1;
    while (i < 2) : (i += 1) {
        var j: i4 = -1;
        // Have to do this since usize doesn't play well with negatives
        const for_the_sake_of_types_i: isize = @intCast(loc[0]);
        const i_rel_i = for_the_sake_of_types_i + i;
        // if out of bounds skip this iteration
        if (i_rel_i < 0 or i_rel_i >= whole_thing.len) {
            continue;
        }
        // Back to usize since it's guaranteed to be 0 or more
        const rel_i: usize = @intCast(i_rel_i);
        while (j < 2) : (j += 1) {
            // Same as above
            const for_the_sake_of_types_j: isize = @intCast(loc[1]);
            const i_rel_j = for_the_sake_of_types_j + j;
            if (i_rel_j < 0 or i_rel_j >= whole_thing[0].len) {
                continue;
            }
            var rel_j: usize = @intCast(i_rel_j);
            // If we find a digit, find the whole number
            // set it to all . after it's used
            if (std.ascii.isDigit(whole_thing[rel_i][rel_j])) {
                if (n_of_ns == 2) return 0;
                var end_j = rel_j;
                // Search for the beginning of the number
                while (rel_j > 0 and std.ascii.isDigit(whole_thing[rel_i][rel_j - 1])) {
                    rel_j -= 1;
                }
                // Search for the end of the number
                while (end_j < whole_thing[0].len and std.ascii.isDigit(whole_thing[rel_i][end_j])) {
                    end_j += 1;
                }
                // Get the slice with the number
                const cur_number = whole_thing[rel_i][rel_j..end_j];
                const n_as_int = std.fmt.parseInt(usize, cur_number, 10) catch unreachable;
                // Set all of the digits to . so it doesn't get used again
                while (rel_j < end_j) {
                    whole_thing[rel_i][rel_j] = '.';
                    rel_j += 1;
                }
                product *= n_as_int;
                n_of_ns += 1;
            }
        }
    }
    if (n_of_ns == 1) return 0;
    return product;
}
