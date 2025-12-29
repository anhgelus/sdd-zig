const std = @import("std");
const btree = @import("binary_tree.zig");
const Node = btree.Node;

// Result is strictly above 0 if a > b, it is strictly under 0 if a < b, and returns 0 otherwise.
pub fn CompareFunction(comptime V: type) type {
    return *const fn (a: V, b: V) i64;
}

pub fn BST(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        tree: btree.BinaryTree(V),
        compare: CompareFunction(V),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, comp: CompareFunction(V), val: V) !Self {
            return BST(V){
                .allocator = alloc,
                .tree = try btree.BinaryTree(V).new(alloc, val),
                .compare = comp,
            };
        }

        pub fn binary_tree(self: *Self) *btree.BinaryTree(V) {
            return &self.tree;
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
                const res = self.compare(it.value, val);
                if (res == 0) {
                    return it;
                } else if (res < 0) {
                    current = it.right;
                } else {
                    current = it.left;
                }
            }
            return null;
        }

        pub fn insert(self: *Self, val: V) !*Node(V) {
            const node = try self.allocator.create(Node(V));
            var current: ?*Node(V) = self.tree.root;
            var above: ?*Node(V) = null;
            while (current) |it| {
                if (self.compare(it.value, val) > 0) {
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

        pub fn delete(self: *Self, val: V) void {
            self.tree.root = delete_rec(self, self.tree.root, val).?;
        }

        fn delete_rec(self: *Self, node: ?*Node(V), val: V) ?*Node(V) {
            if (node == null) return null;
            const comp = self.compare(node.?.value, val);
            var res = node;
            if (comp > 0) {
                node.?.left = self.delete_rec(node.?.left, val);
            } else if (comp < 0) {
                node.?.right = self.delete_rec(node.?.right, val);
            } else {
                if (node.?.right == null) {
                    res = node.?.left;
                    self.allocator.destroy(node.?);
                } else if (node.?.left == null) {
                    res = node.?.right;
                    self.allocator.destroy(node.?);
                } else {
                    var current = node;
                    while (current) |it| : (current = it.left) {
                        if (it.left == null) break;
                    }
                    res.?.value = current.?.value;
                    self.allocator.destroy(current.?);
                }
            }
            return res;
        }

        pub fn as_bst(self: *Self, node: ?*Node(V)) Self {
            return BST(V){
                .allocator = self.allocator,
                .tree = self.tree.as_btree(node),
                .compare = self.compare,
            };
        }
    };
}

pub fn compareInt(a: i64, b: i64) i64 {
    return a - b;
}

pub fn compareUint(a: u64, b: u64) i64 {
    return compareInt(@as(i64, @intCast(a)), @as(i64, @intCast(b)));
}

pub fn is_bst_rec(comptime V: type, comp: CompareFunction(V), pnode: ?*Node(V), pmin: ?V, pmax: ?V) bool {
    const node = pnode orelse return true;
    var valid = true;
    if (pmin) |min| valid = valid and comp(node.value, min) > 0;
    if (pmax) |max| valid = valid and comp(node.value, max) < 0;
    if (!valid) return false;
    return is_bst_rec(V, comp, node.left, pmin, node.value) and is_bst_rec(V, comp, node.right, node.value, pmax);
}

pub fn is_bst(comptime V: type, comp: CompareFunction(V), tree: *btree.BinaryTree(V)) bool {
    return is_bst_rec(V, comp, tree.root, null, null);
}

test "default comparison functions" {
    const expect = std.testing.expect;

    // int
    try expect(compareInt(2, 1) > 0);
    try expect(compareInt(1, 2) < 0);
    try expect(compareInt(2, 2) == 0);

    try expect(compareInt(2, -1) > 0);
    try expect(compareInt(-1, 2) < 0);
    try expect(compareInt(-2, -2) == 0);

    try expect(compareInt(-2, -1) < 0);
    try expect(compareInt(-1, -2) > 0);

    // uint
    try expect(compareUint(2, 1) > 0);
    try expect(compareUint(1, 2) < 0);
    try expect(compareUint(2, 2) == 0);
}

test "initializing a single value binary search tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BST(u64).new(allocator, compareUint, 0);

    const expect = std.testing.expect;

    try expect(tree.binary_tree().size() == 1);
    try expect(tree.binary_tree().height() == 1);
}

test "updating values in binary trees" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try BST(u64).new(allocator, compareUint, 0);

    const expect = std.testing.expect;

    _ = try tree.insert(2);
    _ = try tree.insert(4);
    _ = try tree.insert(6);

    try expect(is_bst(u64, compareUint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 4);
    try expect(tree.binary_tree().height() == 4);

    tree = try BST(u64).new(allocator, compareUint, 9);

    _ = try tree.insert(3);
    _ = try tree.insert(7);
    _ = try tree.insert(10);
    _ = try tree.insert(1);
    _ = try tree.insert(14);
    _ = try tree.insert(4);

    try expect(is_bst(u64, compareUint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.binary_tree().height() == 4);

    tree.delete(7);

    try expect(is_bst(u64, compareUint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 6);
    try expect(tree.binary_tree().height() == 3);

    tree = try BST(u64).new(allocator, compareUint, 1);

    _ = try tree.insert(3);
    _ = try tree.insert(4);
    _ = try tree.insert(7);
    _ = try tree.insert(9);
    _ = try tree.insert(10);
    _ = try tree.insert(14);

    try expect(is_bst(u64, compareUint, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.binary_tree().height() == 7);
}
