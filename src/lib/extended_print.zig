const std = @import("std");
const stdout = std.io.getStdOut().writer();
const builtin = @import("builtin");

/// select print colours per operating system
pub const print_colors: PrintColors = blk: {
    switch (builtin.os.tag) {
        .macos, .linux, .windows => {
            break :blk print_colors_ansi_code;
        },
        else => {
            //TODO implement colours for differents platforms
            stdout.print("Note: Color prints are not yet supported for this os\n", .{});
            break :blk print_colors_unsupported;
        },
    }
};

/// terminal colour commands
const PrintColors = struct {
    red: []const u8,
    green: []const u8,
    yellow: []const u8,
    blue: []const u8,
    magenta: []const u8,
    cyan: []const u8,
    reset: []const u8,
};

/// terminal colour commands for ANSI
const print_colors_ansi_code = PrintColors{
    .red = "\x1b[91m",
    .green = "\x1b[92m",
    .yellow = "\x1b[93m",
    .blue = "\x1b[94m",
    .magenta = "\x1b[95m",
    .cyan = "\x1b[96m",
    .reset = "\x1b[0m",
};

/// terminal colour commands for unsupported platforms
const print_colors_unsupported = PrintColors{
    .red = "",
    .green = "",
    .yellow = "",
    .blue = "",
    .magenta = "",
    .cyan = "",
    .reset = "",
};

/// prints 'Error: ' in red than the string
pub fn printErrorMessage(comptime error_string: []const u8, args: anytype) !void {
    try stdout.print(print_colors.red ++ "Error: " ++ print_colors.reset ++ error_string ++ "\n", args);
}

/// prints 'Warning: ' in yellow than the string
pub fn printWarningMessage(comptime warning_string: []const u8, args: anytype) !void {
    try stdout.print(print_colors.yellow ++ "Warning: " ++ print_colors.reset ++ warning_string ++ "\n", args);
}

/// prints 'Successful: ' in green than the string
pub fn printSuccessfulMessage(comptime succes_string: []const u8, args: anytype) !void {
    try stdout.print(print_colors.green ++ "Successfully: " ++ print_colors.reset ++ succes_string ++ "\n", args);
}

/// prints 'Starting: ' in blue than the string
pub fn printStartingMessage(comptime start_string: []const u8, args: anytype) !void {
    try stdout.print(print_colors.blue ++ "Started: " ++ print_colors.reset ++ start_string ++ "\n", args);
}
