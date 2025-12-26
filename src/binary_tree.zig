const std = @import("std");

pub fn Node(comptime V: type) type {
    return struct {
        value: V,
        left: ?*Node(V),
        right: ?*Node(V),
        above: ?*Node(V),
    };
}

pub fn BinaryTree(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        root: *Node(V),

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator) !BinaryTree(V) {
            const node = try alloc.create(Node(V));
            return BinaryTree(V){ .allocator = alloc, .root = node };
        }
    };
}
