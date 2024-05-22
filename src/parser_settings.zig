const std = @import("std");

// command settings
pub const build_command = "build";
pub const run_command = "run";
pub const test_command = "test";
pub const no_warnings_command = "noWarnings";
pub const no_log_command = "noLog";
pub const help_command = "help";
pub const command_delimiter = "-";
pub const input_file_extension = ".bf";

// output settings for intermediate zig file
pub const output_folder_path = "output";
pub const output_file_name = "out";
pub const output_file_extension = ".zig";
pub const output_file_name_full = output_file_name ++ output_file_extension;
pub const output_file_path = output_folder_path ++ "/" ++ output_file_name_full;

// shell command settings
//TODO use usage .env variables
pub const path_to_zig = "sudo ./../zig_install/zig";
pub const zig_build_command = "build-exe";
pub const shell_build_command = path_to_zig ++ " " ++ zig_build_command ++ " " ++ output_file_path;
pub const shell_run_command = "./" ++ output_file_name;

// known working zig versions
pub const upper_major_version = 0;
pub const lower_major_version = 0;
pub const upper_minor_version = 12;
pub const lower_minor_version = 12;

// parser settings
const maximum_iterations = 10000; // to prevent infine loops
pub const array_size = 1024;
pub const array_size_warning = 30001;

pub const standard_parser_settings = ParserSettings{
    // zig output header
    .header_string = std.fmt.comptimePrint(
        \\const std = @import("std");
        \\const stdout = std.io.getStdOut().writer();
        \\const stdin = std.io.getStdIn().reader();
        \\
        \\pub fn main() !void {{
        \\    try stdout.print("Auto generated \n", .{{}});
        \\
        \\    const max_iterations = {d}; // prevent infite loops
        \\
        \\    var index: usize = 0;
        \\    var array = [_]u8{{0}} ** {d};
        \\  
        \\    // ensure all variables are used
        \\    index += 0;
        \\    array[0] = 0;
        \\  
        \\    // start bf program
    , .{ maximum_iterations, array_size }),
    // zig output footer
    .footer_string =
    \\
    \\    // end bf code
    \\    try stdout.print("\n", .{});
    \\    const waste = max_iterations; //ensure variable usage;
    \\    _ = waste;
    \\}
    \\
    \\fn ask_user() !u8 {
    \\    var buf: [10]u8 = undefined;
    \\
    \\    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
    \\        return user_input[0];
    \\    } else {
    \\        return error.InvalidChar;
    \\    }
    \\}
    \\
    \\const runTimeError = error{
    \\    InfiniteLoop,
    \\};
    ,
    // the base indentation sie and shape
    .indent_spacing = "    ",
    // interger size to store maximum amount of combined characters and nested loops
    .intsize_type = u8,
};

pub const ParserSettings = struct {
    header_string: []const u8,
    footer_string: []const u8,
    indent_spacing: []const u8,
    intsize_type: type,
};
