const std = @import("std");
const page_allocator = std.heap.page_allocator;

const HandDetails = struct { bid: u16, power: u8, value: usize, hand: []const u8 };
pub fn main() !usize {
    const fp = try std.fs.cwd().openFile("src/d7.txt", .{});
    defer fp.close();

    var buf_reader = std.io.bufferedReader(fp.reader());
    var stream = buf_reader.reader();

    var buf: [256]u8 = undefined;
    var hands = std.ArrayList(HandDetails).init(page_allocator);
    // var big_arr_list = std.ArrayList(std.ArrayList([][]u8)).init(page_allocator);
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        hands.append(parse_line(line)) catch unreachable;
    }
    const hands_arr = hands.toOwnedSlice() catch unreachable;
    std.sort.heap(HandDetails, hands_arr, {}, compare_hands);
    var i: u16 = 0;
    const hands_len = hands_arr.len;
    var acc: usize = 0;
    while (i < hands_len) : (i += 1) {
        std.debug.print("{s}\n", .{hands_arr[i].hand});
        acc += (hands_len - i) * hands_arr[i].bid;
    }
    return acc;
}

fn parse_line(line: []u8) HandDetails {
    var main_it = std.mem.splitSequence(u8, line, " ");
    const cards = main_it.next() orelse unreachable;
    const for_saving = page_allocator.dupe(u8, cards) catch unreachable;
    const bid = std.fmt.parseInt(u16, main_it.next() orelse unreachable, 10) catch unreachable;
    var hand_value: usize = 0;
    var card_it: u8 = 0;
    while (card_it < 5) : (card_it += 1) {
        var cur_value: usize = switch (cards[card_it]) {
            'A' => 14,
            'K' => 13,
            'Q' => 12,
            'J' => 11,
            'T' => 10,
            else => 0,
        };
        if (cur_value == 0) cur_value = std.fmt.parseInt(u32, &[_]u8{cards[card_it]}, 10) catch unreachable;
        // Doing 14 to avoid cases where a second K can be bigger than a first 1
        cur_value = cur_value * std.math.pow(usize, 14, 5 - card_it);
        hand_value += cur_value;
    }
    std.sort.heap(u8, @constCast(cards), {}, std.sort.asc(u8));
    card_it = 0;
    var cur_char = cards[0];
    var arr = std.mem.zeroes([5]u8);
    var arr_it: u8 = 0;
    while (card_it < 5) : (card_it += 1) {
        if (cards[card_it] != cur_char) {
            cur_char = cards[card_it];
            arr_it += 1;
        }
        arr[arr_it] += 1;
    }
    std.sort.heap(u8, &arr, {}, std.sort.desc(u8));
    var power: u8 = 0;
    if (arr[0] == 5) {
        power = 7;
    } else if (arr[0] == 4) {
        power = 6;
    } else if (arr[0] == 3 and arr[1] == 2) {
        power = 5;
    } else if (arr[0] == 3) {
        power = 4;
    } else if (arr[0] == 2 and arr[1] == 2) {
        power = 3;
    } else if (arr[0] == 2) {
        power = 2;
    } else {
        power = 1;
    }

    return HandDetails{ .bid = bid, .power = power, .value = hand_value, .hand = for_saving };
}

fn compare_hands(_: void, lhs: HandDetails, rhs: HandDetails) bool {
    if (lhs.power != rhs.power) return lhs.power > rhs.power;
    return lhs.value > rhs.value;
}
