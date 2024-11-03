const std = @import("std");
const print = std.debug.print;

pub fn main() !usize {
    const fp = try std.fs.cwd().openFile("src/d4.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    var card_number_counter: u8 = 1;

    var map: std.AutoHashMap(u8, u8) = std.AutoHashMap(u8, u8).init(std.heap.page_allocator);
    defer map.deinit();
    // Will process the numbers backwards, will use this to store calculations for lower numbers
    // so I don't have to recalculate every time
    var solution_map: std.AutoHashMap(u8, usize) = std.AutoHashMap(u8, usize).init(std.heap.page_allocator);
    defer solution_map.deinit();

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        read_card_into_map(&map, card_number_counter, line);
        card_number_counter += 1;
    }
    var i: u8 = card_number_counter - 1;
    var acc: usize = 0;
    while (i > 0) : (i -= 1) {
        acc += process_card(&solution_map, &map, i);
    }
    return acc;
}

// Card 1: 32 123 321 | 83 24 32 13 23
fn read_card_into_map(map: *std.hash_map.AutoHashMap(u8, u8), card_number: u8, line: []u8) void {
    // Get rid of everything before :
    var junk_it = std.mem.splitSequence(u8, line, ": ");
    _ = junk_it.next() orelse unreachable;
    const card = junk_it.next() orelse unreachable;
    // Split into scoreboard and values
    var card_it = std.mem.splitSequence(u8, card, " | ");
    // Two splits
    const winners = card_it.next() orelse unreachable;
    const actual = card_it.next() orelse unreachable;
    // with ints
    const winners_arr = string_to_bool_array(winners);
    var actual_it = std.mem.splitSequence(u8, actual, " ");
    var accumulator: u8 = 0;
    while (actual_it.next()) |number_str| {
        if (number_str.len == 0) continue;
        const number_int: usize = std.fmt.parseInt(u8, number_str, 10) catch unreachable;
        if (winners_arr[number_int] == 1) {
            accumulator += 1;
        }
    }
    map.put(card_number, accumulator) catch unreachable;
}

// Turns a string of space seperated numbers
// into a u1 array (since I don't know how to memset bools in zig
// since the challenge uses at most 2 digit numbers it's a u8 sized arr
fn string_to_bool_array(line: []const u8) []u1 {
    var number_it = std.mem.splitSequence(u8, line, " ");
    var bool_arr = std.mem.zeroes([128]u1);
    while (number_it.next()) |number| {
        // For single digits
        if (number.len == 0) continue;
        const number_int = std.fmt.parseInt(u8, number, 10) catch unreachable;
        bool_arr[number_int] = 1;
    }
    // Have to do this so the data doesn't get overwritten later down the line
    return std.heap.page_allocator.dupe(u1, &bool_arr) catch unreachable;
}

// Calculate the number of cards Card [card_number] is worth
fn process_card(solution_map: *std.hash_map.AutoHashMap(u8, usize), map: *std.hash_map.AutoHashMap(u8, u8), card_number: u8) usize {
    // If we've already calculated the value of this card, just return the value
    const possible_solution = solution_map.get(card_number);
    if (possible_solution != null) return possible_solution orelse unreachable;
    // The number of copies we're adding
    const self_number = map.get(card_number) orelse unreachable;
    // The actual value of this card is 1 (the card itself) + the numbers that each copy brings in
    var i: u4 = 1;
    var acc: usize = 1;
    // Calculate how many cards each one of the copies we're processing is worth
    // and add each one to our own value of 1
    while (i <= self_number) : (i += 1) {
        acc += process_card(solution_map, map, card_number + i);
    }
    // Save this cards value in case it needs to be used as a copy in the future
    // This guarantees we'll never have to calculate the value of the same card twice
    solution_map.put(card_number, acc) catch unreachable;
    return acc;
}
