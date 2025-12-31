const std = @import("std");

pub fn Node(comptime V: type) type {
    return struct {
        value: V,
        left: ?*Node(V),
        right: ?*Node(V),
        above: ?*Node(V),
        height: u32 = 1,

        const Self = @This();

        pub fn new(val: V, above: ?*Self) Self {
            return Node(V){
                .value = val,
                .above = above,
                .left = null,
                .right = null,
            };
        }

        pub fn prefix(self: *Self) void {
            std.debug.print("{}", .{self.value});
            if (self.left) |it| it.prefix();
            if (self.right) |it| it.prefix();
        }

        pub fn infix(self: *Self) void {
            if (self.left) |it| it.infix();
            std.debug.print("{}", .{self.value});
            if (self.right) |it| it.infix();
        }

        pub fn suffix(self: *Self) void {
            if (self.left) |it| it.suffix();
            if (self.right) |it| it.suffix();
            std.debug.print("{}", .{self.value});
        }

        pub fn size(self: *Self) usize {
            var left: usize = 0;
            if (self.left) |it| left = it.size();
            var right: usize = 0;
            if (self.right) |it| right = it.size();
            return 1 + left + right;
        }

        pub fn calculate_height(self: *Self) u32 {
            var left: u32 = 0;
            if (self.left) |it| left = it.calculate_height();
            var right: u32 = 0;
            if (self.right) |it| right = it.calculate_height();
            self.height = 1 + @max(left, right);
            return self.height;
        }

        pub fn update_height_fast(self: *Node(V)) void {
            var left: u32 = 0;
            if (self.left) |it| left = it.height;
            var right: u32 = 0;
            if (self.right) |it| right = it.height;
            self.height = 1 + @max(left, right);
        }

        pub fn get(self: *Self, val: V) ?*Node(V) {
            if (self.value == val) return self;
            if (self.left) |it| {
                return it.get(val);
            } else if (self.right) |it| {
                return it.get(val);
            }
            return null;
        }
    };
}

pub fn BinaryTree(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        root: *Node(V),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, val: V) !Self {
            const node = try alloc.create(Node(V));
            node.* = Node(V).new(val, null);
            return BinaryTree(V){ .allocator = alloc, .root = node };
        }

        pub fn prefix(self: *Self) void {
            self.root.prefix();
        }

        pub fn infix(self: *Self) void {
            self.root.infix();
        }

        pub fn suffix(self: *Self) void {
            self.root.suffix();
        }

        pub fn size(self: *Self) usize {
            return self.root.size();
        }

        pub fn height(self: *Self) usize {
            return self.root.calculate_height();
        }

        pub fn get(self: *Self, val: V) ?*Node(V) {
            return self.root.get(val);
        }

        pub fn as_btree(self: *Self, node: *Node(V)) Self {
            const cp = self.*;
            cp.root = node;
            return cp;
        }
    };
}

test "initializing a single value binary tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BinaryTree(u64).new(allocator, 0);

    try std.testing.expect(tree.size() == 1);
    try std.testing.expect(tree.height() == 1);
}

test "inserting values in the binary tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BinaryTree(u64).new(allocator, 0);

    var node = try allocator.create(Node(u64));
    node.* = Node(u64).new(1, tree.root);
    tree.root.left = node;

    node = try allocator.create(Node(u64));
    node.* = Node(u64).new(2, tree.root);
    tree.root.right = node;

    try std.testing.expect(tree.size() == 3);
    try std.testing.expect(tree.height() == 2);

    var right = node;

    node = try allocator.create(Node(u64));
    node.* = Node(u64).new(3, right);
    right.left = node;

    try std.testing.expect(tree.size() == 4);
    try std.testing.expect(tree.height() == 3);
}
