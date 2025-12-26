const std = @import("std");
const hash_table = @import("hash_table.zig");

pub fn BloomFilter(comptime V: type) type {
    return struct {
        allocator: std.mem.Allocator,
        functions: []hash_table.HashFunction(V),
        list: []bool,

        const Self = @This();

        pub fn new(alloc: std.mem.Allocator, n: usize, hashFns: []hash_table.HashFunction(V)) !BloomFilter(V) {
            const list = try alloc.alloc(bool, n);
            return BloomFilter(V){ .allocator = alloc, .functions = hashFns, .list = list };
        }

        pub fn add(self: *Self, value: V) void {
            for (0..self.functions.len) |i| {
                const key = self.functions[i](value, self.list.len);
                self.list[key] = true;
            }
        }

        pub fn has(self: *Self, value: V) bool {
            for (0..self.functions.len) |i| {
                const key = self.functions[i](value, self.list.len);
                if (!self.list[key]) return false;
            }
            return true;
        }
    };
}
