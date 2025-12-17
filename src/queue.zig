const std = @import("std");
const linkedList = @import("linked_list.zig");
const EmptyQueue = error.EmptyQueue;

pub fn Queue(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: *linkedList.LinkedList(T),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator) !Queue(T) {
            const list = try alloc.create(linkedList.LinkedList(T));
            list.* = linkedList.LinkedList(T).new(alloc);
            return Queue(T){ .allocator = alloc, .list = list };
        }

        pub fn empty(self: *Self) bool {
            return self.length() == 0;
        }

        pub fn enqueue(self: *Self, v: T) !void {
            try self.list.insert(v);
        }

        pub fn dequeue(self: *Self) !T {
            const t = self.list.last orelse return EmptyQueue;
            self.list.last = t.before;
            const val = t.val;
            self.allocator.destroy(t);
            self.list.length -= 1;
            return val;
        }

        pub fn peek(self: *Self) !T {
            if (self.empty()) {
                return EmptyQueue;
            }
            return self.list.last.?.val;
        }

        pub fn length(self: *Self) u64 {
            return self.list.length;
        }
    };
}

test "initializing builds an empty queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var queue = try Queue(u32).new(allocator);

    try std.testing.expect(queue.length() == 0);
    try std.testing.expect(queue.list.first == null);
    try std.testing.expect(queue.empty());
}

test "inserting a value in the queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var queue = try Queue(u32).new(allocator);

    try queue.enqueue(69);

    try std.testing.expect(queue.length() == 1);
    try std.testing.expect(queue.list.first != null);
    try std.testing.expect(queue.list.first.?.val == 69);
    try std.testing.expect(!queue.empty());
    try std.testing.expect(try queue.peek() == 69);
}

test "verifying order in the queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var queue = try Queue(u32).new(allocator);

    for (0..10) |i| {
        try queue.enqueue(@intCast(i));
    }

    var i: u32 = 0;
    while (!queue.empty()) {
        try std.testing.expect(try queue.dequeue() == i);
        i += 1;
    }
}
