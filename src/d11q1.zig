const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;
var arena_allocator = std.heap.ArenaAllocator.init(page_allocator);

pub fn main() !u64 {
    defer arena_allocator.deinit();
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d11.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // summer times
    var lines = std.ArrayList([]u8).init(arena_allocator.allocator());
    // will be used to optimize expansion
    var row_len: u16 = 0;
    var are_empty_cols: []bool = undefined;

    while (try stream.readUntilDelimiterOrEofAlloc(arena_allocator.allocator(), '\n', 141)) |line| {
        if (row_len == 0) {
            row_len = @intCast(line.len);
            are_empty_cols = arena_allocator.allocator().alloc(bool, line.len) catch unreachable;
            @memset(are_empty_cols, true);
        }
        var i: u16 = 0;
        var has_galaxy = false;
        while (i < line.len) : (i += 1) {
            if (line[i] != '.') {
                has_galaxy = true;
                // marking which cols have galaxies
                are_empty_cols[i] = false;
            }
        }
        // If there's no galaxies here just expand the column
        if (!has_galaxy) lines.append(line) catch unreachable;
        lines.append(line) catch unreachable;
    }
    const lines_arr = lines.toOwnedSlice() catch unreachable;
    var expanded_lines = std.ArrayList([]u8).init(arena_allocator.allocator());
    var i: u16 = 0;
    while (i < lines_arr.len) : (i += 1) {
        var j: u16 = 0;
        var current_line_expanded = std.ArrayList(u8).init(arena_allocator.allocator());
        while (j < lines_arr[i].len) : (j += 1) {
            // if the current column doesn't have a galaxy, expand it
            if (are_empty_cols[j]) {
                current_line_expanded.append('.') catch unreachable;
            }
            current_line_expanded.append(lines_arr[i][j]) catch unreachable;
        }
        const current_line_expanded_arr = current_line_expanded.toOwnedSlice() catch unreachable;
        expanded_lines.append(current_line_expanded_arr) catch unreachable;
    }
    var expanded_lines_arr = @constCast(expanded_lines.toOwnedSlice() catch unreachable);
    var acc: u32 = 0;
    i = 0;
    while (i < expanded_lines_arr.len) : (i += 1) {
        var j: u16 = 0;
        while (j < expanded_lines_arr[i].len) : (j += 1) {
            if (expanded_lines_arr[i][j] != '.')
                acc += findAllDistancesAndDeleteGalaxy(i, j, &expanded_lines_arr);
        }
    }
    i = 0;
    return acc;
}

const LLData = struct { row: u16, col: u16, step: u16 };
const LL = std.DoublyLinkedList(LLData);
fn findAllDistancesAndDeleteGalaxy(row: u16, col: u16, map: *[][]u8) u32 {
    var visited: [][]bool = arena_allocator.allocator().alloc([]bool, map.len) catch unreachable;
    var i: u16 = 0;
    while (i < visited.len) : (i += 1) {
        visited[i] = arena_allocator.allocator().alloc(bool, map.*[i].len) catch unreachable;
        @memset(visited[i], false);
    }

    var to_visit = LL{};
    const first_node = arena_allocator.allocator().create(LL.Node) catch unreachable;
    const data = arena_allocator.allocator().create(LLData) catch unreachable;
    var step_acc: u32 = 0;
    data.row = row;
    data.col = col;
    data.step = 0;
    first_node.data = data.*;
    to_visit.prepend(first_node);

    while (to_visit.len != 0) {
        const cur_node = to_visit.popFirst() orelse unreachable;
        const crow = cur_node.data.row;
        const ccol = cur_node.data.col;
        const cstep = cur_node.data.step;
        if (visited[crow][ccol]) {
            continue;
        }
        visited[crow][ccol] = true;
        // If we reached another galaxy add it to the sum
        if (map.*[crow][ccol] != '.') {
            step_acc += cstep;
        }
        if (crow > 0) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow - 1;
            nodata.col = ccol;
            nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (crow + 1 < map.len) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow + 1;
            nodata.col = ccol;
            nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (ccol > 0) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow;
            nodata.col = ccol - 1;
            nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (ccol + 1 < map.*[0].len) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow;
            nodata.col = ccol + 1;
            nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
    }
    // No need to use this galaxy ever again
    map.*[row][col] = '.';
    return step_acc;
}
