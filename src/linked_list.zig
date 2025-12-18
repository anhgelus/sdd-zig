const std = @import("std");

pub fn Node(comptime T: type) type {
    return struct { val: T, next: ?*Node(T), before: ?*Node(T) };
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        first: ?*Node(T) = null,
        last: ?*Node(T) = null,
        length: u64 = 0,

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator) LinkedList(T) {
            return LinkedList(T){ .allocator = alloc };
        }

        pub fn free(self: *Self) void {
            var current = self.first;
            while (current) |it| {
                const t = it;
                current = it.next;
                self.allocator.destroy(t);
            }
            self.length = 0;
            self.first = null;
        }

        pub fn insert(self: *Self, v: T) !void {
            const node = try self.allocator.create(Node(T));
            node.val = v;
            node.next = self.first;
            node.before = null;
            if (self.first) |it| {
                it.before = node;
            }
            self.first = node;
            self.length += 1;
            if (self.last == null) {
                self.last = self.first;
            }
        }

        pub fn traverse(self: *Self) void {
            var current = self.first;
            while (current) |it| : (current = it.next) {
                std.log.info("{}", .{it.val});
            }
        }
    };
}

test "initializing builds an empty linked list with no nodes" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const linkedList = &LinkedList(u32).new(allocator);

    try std.testing.expect(linkedList.length == 0);
    try std.testing.expect(linkedList.first == null);
}

test "inserting a value appends to the head of the linked list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var linkedList = LinkedList(u32).new(allocator);

    try linkedList.insert(69);

    try std.testing.expect(linkedList.length == 1);
    try std.testing.expect(linkedList.first != null);
    try std.testing.expect(linkedList.first.?.val == 69);
}

test "verifying order in the linked list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var linkedList = LinkedList(u32).new(allocator);

    for (0..10) |i| {
        try linkedList.insert(@intCast(i));
    }

    var i: i8 = 9;
    var node = linkedList.first;
    while (node) |it| : (node = it.next) {
        try std.testing.expect(it.val == i);
        i -= 1;
    }
}

test "deinit the linked list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var linkedList = LinkedList(u32).new(allocator);

    try linkedList.insert(69);
    linkedList.free();

    try std.testing.expect(linkedList.length == 0);
    try std.testing.expect(linkedList.first == null);
}
