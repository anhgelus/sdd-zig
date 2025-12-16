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
            if (self.empty()) {
                return EmptyQueue;
            }
            const t = self.list.last;
            self.list.last = t.before;
            const val = t.val;
            try self.allocator.deinit(val);
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
