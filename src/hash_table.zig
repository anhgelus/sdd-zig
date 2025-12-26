const std = @import("std");
const linkedList = @import("linked_list.zig");

pub fn HashNode(comptime K: type, comptime V: type) type {
    return struct {
        key: K,
        val: V,
    };
}

pub fn HashFunction(comptime K: type) type {
    return *const fn (K, usize) usize;
}

pub fn HashTable(comptime K: type, comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: []*linkedList.LinkedList(*HashNode(K, V)),
        hash: HashFunction(K),
        length: usize = 0,

        const Self = @This();
        const Node = HashNode(K, V);

        pub fn new(alloc: std.mem.Allocator, n: usize, hashFn: *const fn (K, usize) usize) !HashTable(K, V) {
            const list = try alloc.alloc(*linkedList.LinkedList(*Node), n);
            for (0..n) |i| {
                const l = try alloc.create(linkedList.LinkedList(*Node));
                l.* = linkedList.LinkedList(*Node).new(alloc);
                list[i] = l;
            }
            return HashTable(K, V){ .allocator = alloc, .list = list, .hash = hashFn };
        }

        fn calcHash(self: *Self, v: K) usize {
            return self.hash(v, self.list.len);
        }

        pub fn add(self: *Self, k: K, v: V) !void {
            var l = self.list[self.calcHash(k)];
            const node = Node{ .key = k, .val = v };
            var currentNode = l.first;
            while (currentNode) |it| : (currentNode = it.next) {
                if (it.val.key == k) {
                    it.val.val = v;
                    return;
                }
            }
            const p = try self.allocator.create(Node);
            p.* = node;
            try l.insert(p);
            self.length += 1;
        }

        pub fn has(self: *Self, k: K) bool {
            var node = self.list[self.calcHash(k)].first;
            while (node) |it| : (node = it.next) {
                if (it.val.key == k) return true;
            }
            return false;
        }

        pub fn get(self: *Self, k: K) ?V {
            var node: ?*linkedList.Node(*Node) = self.list[self.calcHash(k)].first;
            while (node) |it| : (node = it.next) {
                if (it.val.key == k) return it.val.val;
            }
            return null;
        }

        pub fn remove(self: *Self, k: K) !void {
            const l = self.list[self.calcHash(k)];
            if (l.length == 0) return;

            var node = l.first;
            var prec: ?*linkedList.Node() = null;
            while (node) |it| : (node = it.next) {
                if (it.val.key == k) {
                    const before = prec orelse l.first;
                    before.next = it.next;
                    self.allocator.destroy(it);
                    self.length -= 1;
                    return;
                }
                prec = it;
            }
        }

        pub fn traverse(self: *Self) void {
            std.debug.print("len: {}\n", .{self.length});
            for (0..self.list.len) |i| {
                var list = self.list[i];
                std.debug.print("{}, len: {}\n", .{ i, list.length });
                if (list.length != 0) list.traverse();
            }
        }
    };
}

pub fn uintHash(x: u64, n: usize) usize {
    const math = std.math;
    const A = (math.sqrt(5.0) - 1.0) / @as(f64, @floatFromInt(2));
    const xA = @as(f64, @floatFromInt(x)) * A;
    return @as(usize, @intFromFloat(math.floor(@as(f64, @floatFromInt(n)) * (xA - math.floor(xA)))));
}

test "initializing builds an empty hash table" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const map = try HashTable(u64, bool).new(allocator, 5, uintHash);

    try std.testing.expect(map.length == 0);
}

test "inserting a value in the hash table" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var map = try HashTable(u64, bool).new(allocator, 5, uintHash);

    try map.add(10, true);

    try std.testing.expect(map.length == 1);
    try std.testing.expect(map.has(10));
    try std.testing.expect(map.get(10) orelse false);
}

test "verifying inputs in hash table" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var map = try HashTable(u64, bool).new(allocator, 5, uintHash); // using 5 for 9 values to test collisions

    for (0..10) |i| {
        try map.add(i, i % 2 == 0);
    }

    for (0..10) |i| {
        try std.testing.expect(map.has(i));
        try std.testing.expect(map.get(i) orelse (i % 2 == 1) == (i % 2 == 0));
    }
}
