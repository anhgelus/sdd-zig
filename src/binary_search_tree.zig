const std = @import("std");
const btree = @import("binary_tree.zig");
const Node = btree.Node;
const Order = std.math.Order;

pub fn OrderFunction(comptime V: type) type {
    return *const fn (a: V, b: V) Order;
}

pub fn BST(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        tree: *btree.BinaryTree(V),
        order: OrderFunction(V),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, orderFn: OrderFunction(V), val: V) !Self {
            const t = try alloc.create(btree.BinaryTree(V));
            t.* = try btree.BinaryTree(V).new(alloc, val);
            return BST(V){
                .allocator = alloc,
                .tree = t,
                .order = orderFn,
            };
        }

        pub fn binary_tree(self: *Self) *btree.BinaryTree(V) {
            return self.tree;
        }

        pub fn min(self: *Self) V {
            var current = self.tree.root;
            while (current.left) |it| : (current = it.left) {}
            return current.value;
        }

        pub fn max(self: *Self) V {
            var current = self.tree.root;
            while (current.right) |it| : (current = it.right) {}
            return current.value;
        }

        pub fn get(self: *Self, val: V) ?*Node(V) {
            var current: ?*Node(V) = self.tree.root;
            while (current) |it| {
                const res = self.order(it.value, val);
                switch (res) {
                    Order.eq => {
                        return it;
                    },
                    Order.gt => {
                        current = it.left;
                    },
                    Order.lt => {
                        current = it.right;
                    },
                }
            }
            return null;
        }

        pub fn insert(self: *Self, val: V) !*Node(V) {
            const node = try self.allocator.create(Node(V));
            var current: ?*Node(V) = self.tree.root;
            var above: ?*Node(V) = null;
            while (current) |it| {
                if (self.order(it.value, val) == Order.gt) {
                    current = it.left;
                    if (current == null) it.left = node;
                } else {
                    current = it.right;
                    if (current == null) it.right = node;
                }
                if (current == null) above = it;
            }
            node.* = Node(V).new(val, above);
            return node;
        }

        pub fn delete(self: *Self, val: V) !void {
            self.tree.root = (try delete_rec(self, self.tree.root, val)).?;
        }

        fn delete_rec(self: *Self, pnode: ?*Node(V), val: V) !?*Node(V) {
            const node = pnode orelse return error.NotFound;
            var res: ?*Node(V) = node;
            switch (self.order(node.value, val)) {
                Order.gt => {
                    node.left = try self.delete_rec(node.left, val);
                },
                Order.lt => {
                    node.right = try self.delete_rec(node.right, val);
                },
                Order.eq => {
                    if (node.right == null) {
                        res = node.left;
                        self.allocator.destroy(node);
                    } else if (node.left == null) {
                        res = node.right;
                        self.allocator.destroy(node);
                    } else {
                        var current = node;
                        while (current.left) |it| : (current = it) {}
                        res.?.value = current.value;
                        self.allocator.destroy(current);
                    }
                },
            }
            return res;
        }
    };
}

pub fn order_int(a: i64, b: i64) Order {
    return std.math.order(a, b);
}

pub fn order_uint(a: u64, b: u64) Order {
    return std.math.order(a, b);
}

pub fn is_bst_rec(comptime V: type, comp: OrderFunction(V), pnode: ?*Node(V), pmin: ?V, pmax: ?V) bool {
    const node = pnode orelse return true;
    var valid = true;
    if (pmin) |min| valid = valid and comp(node.value, min) == Order.gt;
    if (pmax) |max| valid = valid and comp(node.value, max) == Order.lt;
    if (!valid) return false;
    return is_bst_rec(V, comp, node.left, pmin, node.value) and is_bst_rec(V, comp, node.right, node.value, pmax);
}

pub fn is_bst(comptime V: type, comp: OrderFunction(V), tree: *btree.BinaryTree(V)) bool {
    return is_bst_rec(V, comp, tree.root, null, null);
}

test "initializing a single value binary search tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BST(u64).new(allocator, order_uint, 0);

    const expect = std.testing.expect;

    try expect(tree.binary_tree().size() == 1);
    try expect(tree.binary_tree().height() == 1);
}

test "updating values in binary trees" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BST(u64).new(allocator, order_uint, 0);

    const expect = std.testing.expect;

    _ = try tree.insert(2);
    _ = try tree.insert(4);
    _ = try tree.insert(6);

    try expect(is_bst(u64, order_uint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 4);
    try expect(tree.binary_tree().height() == 4);

    tree = try BST(u64).new(allocator, order_uint, 9);

    _ = try tree.insert(3);
    _ = try tree.insert(7);
    _ = try tree.insert(10);
    _ = try tree.insert(1);
    _ = try tree.insert(14);
    _ = try tree.insert(4);

    try expect(is_bst(u64, order_uint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.binary_tree().height() == 4);

    try tree.delete(7);
    try expect(tree.delete(100) == error.NotFound);

    try expect(is_bst(u64, order_uint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 6);
    try expect(tree.binary_tree().height() == 3);

    tree = try BST(u64).new(allocator, order_uint, 1);

    _ = try tree.insert(3);
    _ = try tree.insert(4);
    _ = try tree.insert(7);
    _ = try tree.insert(9);
    _ = try tree.insert(10);
    _ = try tree.insert(14);

    try expect(is_bst(u64, order_uint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.binary_tree().height() == 7);
}
