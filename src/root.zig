//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const hash_table = @import("hash_table.zig");

pub const LinkedList = @import("linked_list.zig").LinkedList;
pub const Queue = @import("queue.zig").Queue;
pub const Stack = @import("stack.zig").Stack;
pub const Hash = struct {
    pub const uint = hash_table.uintHash;
    pub const Table = hash_table.HashTable;
};

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test {
    //std.options.log_level = .debug;
    std.testing.refAllDeclsRecursive(@This());
}
