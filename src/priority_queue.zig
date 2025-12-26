const std = @import("std");

fn Node(comptime V: type) type {
    return struct {
        value: V,
        priority: i64,
    };
}

pub fn PriorityQueue(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: []Node(V),
        length: usize,

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, size: usize) !PriorityQueue(V) {
            const list = try alloc.alloc(Node(V), size + 1);
            return PriorityQueue(V){ .allocator = alloc, .list = list, .length = 0 };
        }

        fn swap(self: *Self, a: usize, b: usize) void {
            const node = self.list[a];
            self.list[a] = self.list[b];
            self.list[b] = node;
        }

        pub fn add(self: *Self, value: V, priority: i64) !void {
            const node = Node(V){ .value = value, .priority = priority };
            if (self.length >= self.list.len) {
                return error.QueueIsFull;
            }
            self.list[self.length+1] = node;
            var id = self.length;
            while (self.hasFather(id)) : (id = fatherID(id)) {
                const fID = fatherID(id);
                const father = self.list[fID];
                if (father.priority > node.priority) {
                    self.swap(fID, id);
                } else {
                    id = 0; // break the loop
                }
            }
            self.length += 1;
        }
        
        pub fn pop(self: *Self) !V {
            if (self.length == 0) return error.EmptyQueue;
            const min = self.list[1];
            self.list[1] = self.list[self.length];
            self.length -= 1;
            self.replaceSmallestChild(1);
            return min.value;
        }

        fn replaceSmallestChild(self: *Self, id: usize) void {
            if (self.isLeave(id)) return;
            const l_id = leftChildID(id);
            const r_id = rightChildID(id);
            var smallest: usize = 0;
            if (!self.hasRightChild(id)) {
                smallest = l_id;
            } else if (self.list[l_id].priority < self.list[r_id].priority) {
                smallest = l_id;
            } else {
                smallest = r_id;
            }
            if (self.list[smallest].priority >= self.list[id].priority) return;
            self.swap(id, smallest);
            self.replaceSmallestChild(smallest);
        }

        fn isNode(self: *Self, id: usize) bool {
            return id < self.length and id > 0;
        }

        fn hasLeftChild(self: *Self, id: usize) bool {
            return self.isNode(leftChildID(id));
        }

        fn hasRightChild(self: *Self, id: usize) bool {
            return self.isNode(rightChildID(id));
        }

        fn hasFather(_: *Self, id: usize) bool {
            return id != 0;
        }

        fn isLeave(self: *Self, id: usize) bool {
            return !self.hasLeftChild(id);
        }

        pub fn traverse(self: *Self) void {
            var i: usize = 0;
            while (2*i <= self.length) : (i += 1) {
                const min = std.math.pow(usize, 2, i);
                const max = 2*min; 
                for (min..max) |j| {
                    if (j < self.length) std.debug.print("{} ", .{self.list[j+1].value});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}

fn fatherID(id: usize) usize {
    return (id) / 2;
}

fn leftChildID(id: usize) usize {
    return 2 * (id);
}

fn rightChildID(id: usize) usize {
    return 2 * (id) + 1;
}

test "initializing an empty priority queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const p = try PriorityQueue(u64).new(allocator, 5);

    try std.testing.expect(p.length == 0);
}

test "inserting a value in the priority queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var p = try PriorityQueue(u64).new(allocator, 5);

    try p.add(10, 1);

    try std.testing.expect(p.length == 1);
    const get = try p.pop();
    try std.testing.expect(get == 10);
    try std.testing.expect(p.length == 0);
}

test "verifying inputs in the priority queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var p = try PriorityQueue(u64).new(allocator, 20);

    for (0..10) |i| {
        try p.add(i, @as(i64, @intCast(i)));
    }

    try std.testing.expect(p.length == 10);

    for (0..10) |i| {
        const get = try p.pop();
        try std.testing.expect(get == i);
        try std.testing.expect(p.length == 10 - i - 1);
    }
}
