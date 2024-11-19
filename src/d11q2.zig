const std = @import("std");
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;
var arena_allocator = std.heap.ArenaAllocator.init(page_allocator);
var empty_cols: []bool = undefined;
var empty_rows: []bool = undefined;
pub fn main() !u64 {
    defer arena_allocator.deinit();
    //Q2 uses the same txt as q1
    var file = try std.fs.cwd().openFile("src/d11.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    // summer times
    var lines = std.ArrayList([]u8).init(arena_allocator.allocator());
    var empty_row_alist = std.ArrayList(bool).init(arena_allocator.allocator());
    // will be used to optimize expansion
    var row_len: u16 = 0;
    while (try stream.readUntilDelimiterOrEofAlloc(arena_allocator.allocator(), '\n', 141)) |line| {
        // If row has a galaxy then this will be set to false
        var is_row_empty = true;
        if (row_len == 0) {
            row_len = @intCast(line.len);
            empty_cols = arena_allocator.allocator().alloc(bool, line.len) catch unreachable;
            @memset(empty_cols, true);
        }
        var i: u16 = 0;
        var has_galaxy = false;
        while (i < line.len) : (i += 1) {
            if (line[i] != '.') {
                has_galaxy = true;
                // marking which cols have galaxies
                is_row_empty = false;
                empty_cols[i] = false;
            }
        }
        lines.append(line) catch unreachable;
        empty_row_alist.append(is_row_empty) catch unreachable;
    }
    empty_rows = empty_row_alist.toOwnedSlice() catch unreachable;
    var lines_arr = @constCast(lines.toOwnedSlice() catch unreachable);
    var acc: u64 = 0;
    var i: u16 = 0;
    while (i < lines_arr.len) : (i += 1) {
        var j: u16 = 0;
        while (j < lines_arr[i].len) : (j += 1) {
            if (lines_arr[i][j] != '.')
                acc += findAllDistancesAndDeleteGalaxy(i, j, &lines_arr);
        }
    }
    i = 0;
    return acc;
}

const LLData = struct { row: u16, col: u16, step: u64 };
const LL = std.DoublyLinkedList(LLData);
fn findAllDistancesAndDeleteGalaxy(row: u16, col: u16, map: *[][]u8) u64 {
    var visited: [][]bool = arena_allocator.allocator().alloc([]bool, map.len) catch unreachable;
    var i: u16 = 0;
    while (i < visited.len) : (i += 1) {
        visited[i] = arena_allocator.allocator().alloc(bool, map.*[i].len) catch unreachable;
        @memset(visited[i], false);
    }

    var to_visit = LL{};
    const first_node = arena_allocator.allocator().create(LL.Node) catch unreachable;
    const data = arena_allocator.allocator().create(LLData) catch unreachable;
    var step_acc: u64 = 0;
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
            if (empty_rows[nodata.row]) {
                nodata.step = cstep + 1000000;
            } else nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (crow + 1 < map.len) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow + 1;
            nodata.col = ccol;
            if (empty_rows[nodata.row]) {
                nodata.step = cstep + 1000000;
            } else nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (ccol > 0) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow;
            nodata.col = ccol - 1;
            if (empty_cols[nodata.col]) {
                nodata.step = cstep + 1000000;
            } else nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
        if (ccol + 1 < map.*[0].len) {
            var node = arena_allocator.allocator().create(LL.Node) catch unreachable;
            var nodata = arena_allocator.allocator().create(LLData) catch unreachable;
            nodata.row = crow;
            nodata.col = ccol + 1;
            if (empty_cols[nodata.col]) {
                nodata.step = cstep + 1000000;
            } else nodata.step = cstep + 1;
            node.data = nodata.*;
            to_visit.append(node);
        }
    }
    // No need to use this galaxy ever again
    map.*[row][col] = '.';
    return step_acc;
}
