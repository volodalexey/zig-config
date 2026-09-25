const std = @import("std");
const Config = @import("../config.zig").Config;
const ConfigError = @import("../errors.zig").ConfigError;
const utils = @import("../utils.zig");
const valueToString = @import("../value.zig").valueToString;

const FileBufferSize = 8192;

/// Writes all config entries to a `.env`-style file.
///
/// - Each line is formatted as `KEY=value`, where the value is serialized to a string.
/// - Keys are written exactly as stored.
/// - Values are stringified using `valueToString`:
///   - `int`, `float`, `bool` → formatted literals
///   - `list` → comma-separated values
///   - `table` → inline TOML-style string like `{k="v"}`
///   - `string` → written as-is, without escaping or quotes
///
/// Overwrites the file at the given `path`.
pub fn writeEnvFile(self: *Config, path: []const u8, allocator: std.mem.Allocator, io: std.Io) !void {
    const file = std.Io.Dir.cwd().createFile(io, path, .{ .truncate = true }) catch return ConfigError.IoError;
    defer file.close(io);
    var buf: [FileBufferSize]u8 = undefined;
    var writer = file.writer(io, &buf);

    var it = self.map.iterator();
    while (it.next()) |entry| {
        const val_str = try valueToString(entry.value_ptr.*, self.map.allocator);
        defer allocator.free(val_str);
        try writer.interface.print("{s}={s}\n", .{ entry.key_ptr.*, val_str });
    }
    try writer.flush();
}
