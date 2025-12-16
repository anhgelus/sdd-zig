const std = @import("std");

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct { val: T, next: ?*Node(T), before: ?*Node(T) };

        var lenght = 0;
        var head = ?*Node;
        var last = ?*Node;
        var allocator: std.mem.Allocator = std.mem.Allocator{};

        pub fn new(alloc: std.mem.Allocator) LinkedList(T) {
            return LinkedList(T){ .lenght = 0, .allocator = alloc };
        }

        pub fn deinit(self: *Self) !void {
            var current = self.head;
            while (current != null) {
                const t = current;
                current = current.next;
                try self.allocator.deinit(t);
            }
            self.lenght = 0;
            self.head = null;
        }

        pub fn insert(self: *Self, v: T) !void {
            const node = try self.allocator.create(Node);
            node.val = v;
            node.next = self.head;
            node.before = null;
            self.head.?.last = node;
            self.head = node;
            self.lenght += 1;
            if (self.last == null) {
                self.last = self.head;
            }
        }

        pub fn pop(self: *Self) !T {
            if (self.head == null) {
                return error{ListEmpty};
            }
            const old = self.head;
            self.head = old.next;
            const val = old.val;
            try self.allocator.deinit(old);
            if (self.head == null) {
                self.last = null;
            }
            return val;
        }

        pub fn traverse(self: *Self) void {
            var current = self.head;
            while (current != null) : (current = current.?.next) {
                std.log.info("{}", .{current.?.val});
            }
        }
    };
}

test "initializing builds an empty linked list with no nodes" {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const linkedList = LinkedList(u32).new(allocator);

    try std.testing.expect(linkedList.length == 0);
    try std.testing.expect(linkedList.head == null);
}

test "inserting a value appends to the head of the linked list" {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const linkedList = LinkedList(u32).new(allocator);

    linkedList.insert(69);

    try std.testing.expect(linkedList.length == 1);
    try std.testing.expect(linkedList.head != null);
    try std.testing.expect(linkedList.head.?.value != 69);
}

test "verifying order in the linked list" {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const linkedList = LinkedList(u32).new(allocator);

    for (0..10) |i| {
        linkedList.insert(i);
    }

    var i = 10;
    var current = linkedList.head;
    while (current != null) : (current = current.?.next) {
        try std.testing.expect(current.val == i);
        i -= 1;
    }
}

test "deinit the linked list" {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const linkedList = LinkedList(u32).new(allocator);

    linkedList.insert(69);
    linkedList.deinit();

    try std.testing.expect(linkedList.length == 0);
    try std.testing.expect(linkedList.head == null);
}
