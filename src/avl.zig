const std = @import("std");
const bstree = @import("binary_search_tree.zig");
const Order = std.math.Order;
const OrderFunction = bstree.OrderFunction;
const btree = @import("binary_tree.zig");
const BT = btree.BinaryTree;
const Node = btree.Node;

pub fn AVL(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        tree: *BT(V),
        order: OrderFunction(V),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, orderFn: OrderFunction(V), val: V) !Self {
            const t = try alloc.create(BT(V));
            t.* = try BT(V).new(alloc, val);
            return AVL(V){
                .allocator = alloc,
                .tree = t,
                .order = orderFn,
            };
        }

        pub fn binary_tree(self: *Self) *btree.BinaryTree(V) {
            return self.tree;
        }

        pub fn bst(self: *Self) !*bstree.BST(V) {
            const target = try self.allocator.create(bstree.BST(V));
            target.* = .{
                .allocator = self.allocator,
                .order = self.order,
                .tree = self.tree,
            };
            return target;
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

        pub fn height(self: *Self) u32 {
            return self.tree.root.height;
        }

        fn rotate_right(current: *Node(V)) *Node(V) {
            const new_node = current.left.?;
            current.left = new_node.right;
            new_node.right = current;
            current.update_height_fast();
            new_node.update_height_fast();
            return new_node;
        }

        fn rotate_left(current: *Node(V)) *Node(V) {
            const new_node = current.right.?;
            current.right = new_node.left;
            new_node.left = current;
            current.update_height_fast();
            new_node.update_height_fast();
            return new_node;
        }

        fn rotate(self: *Self, node: *Node(V), val: V) *Node(V) {
            var left: u32 = 0;
            if (node.left) |it| left = it.height;
            var right: u32 = 0;
            if (node.right) |it| right = it.height;
            switch (@as(i64, @intCast(left)) - @as(i64, @intCast(right))) {
                2 => {
                    const L = node.left.?;
                    if (self.order(L.value, val) == Order.lt) node.left = rotate_left(L);
                    return rotate_right(node);
                },
                -2 => {
                    const R = node.right.?;
                    if (self.order(R.value, val) == Order.gt) node.right = rotate_right(R);
                    return rotate_left(node);
                },
                -1...1 => {
                    return node;
                },
                else => {
                    unreachable;
                },
            }
        }

        pub fn insert(self: *Self, val: V) !void {
            self.tree.root = try insert_rec(self, self.binary_tree().root, self.binary_tree().root, val);
        }

        pub fn insert_rec(self: *Self, pnode: ?*Node(V), prec: *Node(V), val: V) !*Node(V) {
            const node = pnode orelse {
                const node = try self.allocator.create(Node(V));
                node.* = Node(V).new(val, prec);
                return node;
            };
            if (self.order(node.value, val) == Order.gt) {
                node.left = try self.insert_rec(node.left, node, val);
            } else {
                node.right = try self.insert_rec(node.right, node, val);
            }
            node.update_height_fast();
            return self.rotate(node, val);
        }

        pub fn delete(self: *Self, val: V) !void {
            self.tree.root = (try self.delete_rec(self.binary_tree().root, val)).?;
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
            if (res) |it| {
                it.update_height_fast();
                return self.rotate(it, val);
            }
            return res;
        }
    };
}

test "initializing a single value AVL" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = try AVL(u64).new(allocator, bstree.order_uint, 0);

    try std.testing.expect(tree.binary_tree().size() == 1);
    try std.testing.expect(tree.binary_tree().height() == 1);
}

test "updating values in AVL" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const is_bst = bstree.is_bst;
    const order = bstree.order_uint;
    var tree = try AVL(u64).new(allocator, order, 0);

    const expect = std.testing.expect;

    _ = try tree.insert(2);
    _ = try tree.insert(4);
    _ = try tree.insert(6);

    try expect(is_bst(u64, order, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 4);
    try expect(tree.height() == 3);

    tree = try AVL(u64).new(allocator, order, 9);

    _ = try tree.insert(3);
    _ = try tree.insert(7);
    _ = try tree.insert(10);
    _ = try tree.insert(1);
    _ = try tree.insert(14);
    _ = try tree.insert(4);

    try expect(is_bst(u64, order, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.height() == 3);

    //try tree.delete(7);
    try expect(tree.delete(100) == error.NotFound);
    
    //try expect(is_bst(u64, order, tree.binary_tree()));
    //try expect(tree.binary_tree().size() == 6);
    //try expect(tree.binary_tree().height() == 3);

    tree = try AVL(u64).new(allocator, order, 1);

    _ = try tree.insert(3);
    _ = try tree.insert(4);
    _ = try tree.insert(7);
    _ = try tree.insert(9);
    _ = try tree.insert(10);
    _ = try tree.insert(14);

    try expect(is_bst(u64, order, tree.binary_tree()));
    try expect(tree.binary_tree().size() == 7);
    try expect(tree.height() == 3);
}
