const std = @import("std");
const linkedList = @import("linked_list.zig");
const EmptyStack = error.EmptyStack;

pub fn Stack(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: *linkedList.LinkedList(T),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator) !Stack(T) {
            const list = try alloc.create(linkedList.LinkedList(T));
            list.* = linkedList.LinkedList(T).new(alloc);
            return Stack(T){ .allocator = alloc, .list = list };
        }

        pub fn empty(self: *Self) bool {
            return self.length() == 0;
        }

        pub fn add(self: *Self, v: T) !void {
            try self.list.insert(v);
        }

        pub fn pop(self: *Self) !T {
            const t = self.list.first orelse return EmptyStack;
            self.list.first = t.next;
            const val = t.val;
            self.allocator.destroy(t);
            self.list.length -= 1;
            return val;
        }

        pub fn peek(self: *Self) !T {
            if (self.empty()) {
                return EmptyStack;
            }
            return self.list.first.?.val;
        }

        pub fn length(self: *Self) u64 {
            return self.list.length;
        }
    };
}

test "initializing builds an empty stack" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var stack = try Stack(u32).new(allocator);

    try std.testing.expect(stack.length() == 0);
    try std.testing.expect(stack.list.first == null);
    try std.testing.expect(stack.empty());
}

test "inserting a value in the stack" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var stack = try Stack(u32).new(allocator);

    try stack.add(69);

    try std.testing.expect(stack.length() == 1);
    try std.testing.expect(stack.list.first != null);
    try std.testing.expect(stack.list.first.?.val == 69);
    try std.testing.expect(!stack.empty());
    try std.testing.expect(try stack.peek() == 69);
}

test "verifying order in the stack" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var stack = try Stack(u32).new(allocator);

    for (0..10) |i| {
        try stack.add(@intCast(i));
    }

    var i: i8 = 9;
    while (!stack.empty()) {
        try std.testing.expect(try stack.pop() == i);
        i -= 1;
    }
}
