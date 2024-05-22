const std = @import("std");
const fs = std.fs;
const os = std.os;
const fmt = std.fmt;
const stdout = std.io.getStdOut().writer();
const parser_settings = @import("parser_settings.zig");
const ext_print = @import("./lib/extended_print.zig");
const builtin = @import("builtin");

pub fn main() !void {
    // get input args check and create parse command
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // get parse command, exit on fail
    const parse_command = getParseCommand(args) catch std.os.exit(1);
    if (parse_command.log) try ext_print.printSuccessfulMessage("Retieved parsing command", .{});

    // check settings for warnings
    if (parse_command.warnings) try initialCheckForWarnings();
    try initialCheckForErrors();

    // create output path and file
    try createOuputPathAndFile(parser_settings.output_folder_path, parser_settings.output_file_name_full);
    if (parse_command.log) try ext_print.printSuccessfulMessage("Created output file", .{});

    // read input file
    var input_file = try std.fs.cwd().openFile(parse_command.bf_path, .{ .mode = .read_only });
    defer input_file.close();

    // parse bf file
    if (parse_command.log) try ext_print.printStartingMessage("Parsing bf file", .{});
    try parseFile(input_file, parser_settings.output_file_path, parse_command, parser_settings.standard_parser_settings);
    if (parse_command.log) try ext_print.printSuccessfulMessage("Parsed file", .{});

    // compile the produced Zig code
    if (parse_command.log) try ext_print.printStartingMessage("Compiling output Zig file", .{});
    try runShellCommand(parser_settings.shell_build_command);
    if (parse_command.log) try ext_print.printSuccessfulMessage("Compiled Zig file", .{});

    // run produced exe if requested
    if (parse_command.run) {
        if (parse_command.log) try ext_print.printStartingMessage("Running bf program", .{});
        try runShellCommand(parser_settings.shell_run_command);
    }

    // rename exe
    const new_exe_name_len = parse_command.bf_path.len - parser_settings.input_file_extension.len;
    const new_exe_name = parse_command.bf_path[0..new_exe_name_len];
    try os.rename(parser_settings.output_file_name, new_exe_name);

    // delete cache file
    try fs.cwd().deleteFile(parser_settings.output_file_name ++ ".o");
}

/// check for non breaking initial values
fn initialCheckForWarnings() !void {
    // check zig_version
    if (!version_in_range) {
        try ext_print.printWarningMessage("Zig version not in range of known support: upper: '{d}.{d}', lower: '{d}.{d}', your version: '{d}.{d}'", .{ parser_settings.upper_major_version, parser_settings.upper_minor_version, parser_settings.lower_major_version, parser_settings.lower_minor_version, builtin.zig_version.major, builtin.zig_version.minor });
    }

    // check parse settings
    if (parser_settings.array_size > parser_settings.array_size_warning) {
        try ext_print.printWarningMessage("Array size very big: recommended upper maximum: '{d}', given: '{d}'", .{ parser_settings.array_size_warning, parser_settings.array_size });
    }
}

/// check for breaking initial values
fn initialCheckForErrors() !void {
    // ensure of type int
    if (@typeInfo(parser_settings.standard_parser_settings.intsize_type) != .Int) {
        @compileError("Parser settings 'intsize_type' is not an integer");
    }
}

/// check Zig version
const version_in_range: bool = blk: {
    const major_in_range = (parser_settings.lower_major_version <= builtin.zig_version.major) and (builtin.zig_version.major <= parser_settings.upper_major_version);
    const minor_in_range = (parser_settings.lower_minor_version <= builtin.zig_version.minor) and (builtin.zig_version.minor <= parser_settings.upper_minor_version);
    break :blk major_in_range and minor_in_range;
};

/// parse given commands and return a the ParseCommand format
fn getParseCommand(args: [][]u8) ParseCommandError!ParseCommand {
    // validate input args
    const EXPECTED_AMOUNT_ARGS: u8 = 3;

    // check amount of input args
    if (args.len < EXPECTED_AMOUNT_ARGS) {
        try ext_print.printErrorMessage("Too little input arguments provided: expected: '{d}'', given: '{d}'", .{ EXPECTED_AMOUNT_ARGS, args.len });
        try printHelpMessage();
        return error.NotEnoughArguments;
    }
    if (args.len > EXPECTED_AMOUNT_ARGS) {
        try ext_print.printErrorMessage("Too many input arguments provided: expected: '{d}'', given: '{d}'", .{ EXPECTED_AMOUNT_ARGS, args.len });
        try printHelpMessage();
        return error.TooManyArguments;
    }

    // get the parse mode
    var run = false;
    var test_mode = false;
    var no_warnings = false;
    var no_logs = false;

    // TODO make more elegant
    var it = std.mem.split(u8, args[1], parser_settings.command_delimiter);
    while (it.next()) |x| {
        if (std.mem.eql(u8, x, parser_settings.build_command)) {
            continue;
        } else if (std.mem.eql(u8, x, parser_settings.run_command)) {
            run = true;
        } else if (std.mem.eql(u8, x, parser_settings.test_command)) {
            test_mode = true;
        } else if (std.mem.eql(u8, x, parser_settings.no_warnings_command)) {
            no_warnings = true;
        } else if (std.mem.eql(u8, x, parser_settings.no_log_command)) {
            no_logs = true;
        } else if (std.mem.eql(u8, x, parser_settings.help_command)) {
            try printHelpMessage();
        } else {
            try ext_print.printErrorMessage("Build command invalid: '{s}'", .{x});
            try printHelpMessage();
            return error.BuildCommandInvalid;
        }
    }

    // check file extention
    if (args[2].len < parser_settings.input_file_extension.len) {
        try ext_print.printErrorMessage("File extention not valid: expected '{s}', got '{s}'", .{ parser_settings.input_file_extension, args[2] });
        try printHelpMessage();
        return error.FileExtentionInvalid;
    } else if (args[2].len == parser_settings.input_file_extension.len) {
        try ext_print.printErrorMessage("No file name provided", .{});
        try printHelpMessage();
        return error.InvalidFileName;
    }

    const file_extension_start_index = args[2].len - parser_settings.input_file_extension.len;
    if (!std.mem.eql(u8, args[2][file_extension_start_index..], parser_settings.input_file_extension)) {
        try ext_print.printErrorMessage("File extention not valid: expected '{s}', got '{s}'", .{ parser_settings.input_file_extension, args[2][file_extension_start_index..] });
        try printHelpMessage();
        return error.FileExtentionInvalid;
    }

    return ParseCommand{
        .run = run,
        .test_mode = test_mode,
        .warnings = !no_warnings,
        .log = !no_logs,
        .bf_path = args[2],
    };
}

const ParseCommandError = error{
    NotEnoughArguments,
    TooManyArguments,
    FileExtentionInvalid,
    InvalidFileName,
    BuildCommandInvalid,
} || std.os.WriteError;

const ParseCommand = struct {
    run: bool, // run after build
    test_mode: bool, // test mode
    warnings: bool, // ignore warnings
    log: bool, // ignore log
    bf_path: []const u8, // path to BrainFuck file
};

/// help command input help message, formatted
fn printHelpMessage() !void {
    try stdout.print(
        \\ --------------------------------------------------------------------
        \\Usage: bf_zig_parser [{s}-option-option...] [file path]
        \\
        \\The possible {s} options are:
        \\  -{s}            runs the Zig file after building
        \\  -{s}           adds test commands to parsed file
        \\  -{s}     add to ignore warnings
        \\  -{s}          add disable log statements
        \\  -{s}           print all available commands
        \\
        \\The filepath has to end with {s}
        \\
    , .{
        parser_settings.build_command,
        parser_settings.build_command,
        parser_settings.run_command,
        parser_settings.test_command,
        parser_settings.no_warnings_command,
        parser_settings.no_log_command,
        parser_settings.help_command,
        parser_settings.input_file_extension,
    });
}

/// create a new output folder and a granteed clean file
fn createOuputPathAndFile(output_folder_path: []const u8, file_name: []const u8) !void {
    // get working dir
    var cwd = fs.cwd();
    // create path
    const folder = try cwd.makeOpenPath(output_folder_path, .{});
    // create empty file
    var output_file = try folder.createFile(file_name, .{});
    output_file.close();
}

/// main function to parse the bf file
fn parseFile(file: fs.File, output_file_path: []const u8, parse_command: ParseCommand, comptime parse_settings: parser_settings.ParserSettings) !void {
    // init input file reader
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // open output file
    const output_file = try fs.cwd().openFile(output_file_path, .{ .mode = .write_only });
    defer output_file.close();

    // write header
    try writeStringToFile(output_file, parse_settings.header_string);

    // initialise loop variables
    var indent_number: parse_settings.intsize_type = 1;
    var lastChar: AsciiCharCodes = AsciiCharCodes.new_line;
    var combine: parse_settings.intsize_type = 0;

    var finished_flag = true;

    // parser loop
    while (true) {
        // read char by char, break at end of file
        const readChar = in_stream.readByte() catch blk: {
            // insert '\n' as filler after last char
            if (finished_flag) {
                finished_flag = false;
                break :blk @as(u8, 10);
            }
            break;
        };

        // skip if char not in enum with char codes
        const char = charToEnum(readChar, parse_command.test_mode) catch {
            continue;
        };

        // prevent integer 'combine' from overflow
        const combine_overflow_protection = combine +% 1;
        if (combine_overflow_protection <= 0) {
            try ext_print.printErrorMessage("Integer overflow. Increase the size of 'intsize_type' in parse_settings to allow for more combined characters\n", .{});
            return error.IntergerOverFlow;
        }
        combine += 1;

        // if char same as last and (> or < or + or -), combine and skip. else reset
        const combined = combinableChar(lastChar, char);
        if (combined and finished_flag) {
            // handle multi line combine
            if (char == AsciiCharCodes.new_line) {
                combine -= 1;
            }
            continue;
        }

        // match char
        switch (lastChar) {
            AsciiCharCodes.arrow_right => { // > operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try std.fmt.format(output_file.writer(), "index += {d};\n", .{combine});
            },
            AsciiCharCodes.arrow_left => { // < operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try std.fmt.format(output_file.writer(), "index -= {d};\n", .{combine});
            },

            AsciiCharCodes.plus => { // + operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try std.fmt.format(output_file.writer(), "array[index] +%= {d};\n", .{combine});
            },
            AsciiCharCodes.minus => { // - operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try std.fmt.format(output_file.writer(), "array[index] -%= {d};\n", .{combine});
            },

            AsciiCharCodes.comma => { // , operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try writeStringToFile(output_file, "array[index] = try ask_user();\n");
            },
            AsciiCharCodes.period => { // . operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try writeStringToFile(output_file, "try stdout.print(\"{c}\", .{array[index]});\n");
            },

            AsciiCharCodes.square_bracket_open => { // [ operator
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try std.fmt.format(output_file.writer(), "for (0..max_iterations) |ii{d}|{{if(ii{d} >  max_iterations - 2){{return error.InfiniteLoop;}}else if(array[index] == 0){{break;}}\n", .{ indent_number, indent_number });

                // prevent integer overflow
                const indent_overflow_protection = indent_number +% 1;
                if (indent_overflow_protection <= 0) {
                    try ext_print.printErrorMessage("Integer overflow. Increase the size of 'intsize_type' in parse_settings to allow for more combined characters\n", .{});
                    return error.IntergerOverFlow;
                }
                indent_number += 1;
            },
            AsciiCharCodes.square_bracket_close => { // ] operator
                // catch negative indent error
                if ((indent_number - 1) < 1) {
                    try ext_print.printErrorMessage("Brackets not matching, too many ']' closing brackets", .{});
                    return error.NegativeIndent;
                }
                indent_number -= 1;
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try writeStringToFile(output_file, "}\n");
            },
            AsciiCharCodes.new_line => { // \n operator new line
                try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                try writeStringToFile(output_file, "\n");
            },
            AsciiCharCodes.question_mark => { // ? operator print current location
                if (parse_command.test_mode) {
                    try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                    try writeStringToFile(output_file, "try stdout.print(\"{d}\", .{index});\n");
                }
            },
            AsciiCharCodes.exclamation_mark => { // ! operator print current value as number
                if (parse_command.test_mode) {
                    try writeIndentation(output_file, indent_number, parse_settings.indent_spacing);
                    try writeStringToFile(output_file, "try stdout.print(\"{d}\", .{array[index]});\n");
                }
            },
        }

        // if not combined reset
        if (!combined) {
            combine = 0;
        }

        lastChar = char;
    }

    // if indent not 1 brackets didn't match
    if (indent_number != 1) {
        try ext_print.printErrorMessage("Unmatched brackets\n", .{});
        return error.UnmatchingBrackets;
    }

    // write footer
    try writeStringToFile(output_file, parse_settings.footer_string);
}

/// write string to file
fn writeStringToFile(file: fs.File, string_to_write: []const u8) os.WriteError!void {
    try file.writeAll(string_to_write);
}

/// write repeating string to file
fn writeIndentation(file: fs.File, number_of_indent: usize, indent: []const u8) os.WriteError!void {
    for (0..number_of_indent) |_| {
        try writeStringToFile(file, indent);
    }
}

const AsciiCharCodes = enum(u8) {
    new_line = 10,
    exclamation_mark = 33,
    plus = 43,
    comma = 44,
    minus = 45,
    period = 46,
    arrow_left = 60,
    arrow_right = 62,
    question_mark = 63,
    square_bracket_open = 91,
    square_bracket_close = 93,
};

/// convert char to enum, based on the set mode
fn charToEnum(char: u8, test_mode: bool) CharToEnumError!AsciiCharCodes {
    switch (char) {
        @intFromEnum(AsciiCharCodes.arrow_right) => { // > operator
            return AsciiCharCodes.arrow_right;
        },
        @intFromEnum(AsciiCharCodes.arrow_left) => { // < operator
            return AsciiCharCodes.arrow_left;
        },

        @intFromEnum(AsciiCharCodes.plus) => { // + operator
            return AsciiCharCodes.plus;
        },
        @intFromEnum(AsciiCharCodes.minus) => { // - operator
            return AsciiCharCodes.minus;
        },

        @intFromEnum(AsciiCharCodes.comma) => { // , operator
            return AsciiCharCodes.comma;
        },
        @intFromEnum(AsciiCharCodes.period) => { // . operator
            return AsciiCharCodes.period;
        },

        @intFromEnum(AsciiCharCodes.square_bracket_open) => { // [ operator
            return AsciiCharCodes.square_bracket_open;
        },
        @intFromEnum(AsciiCharCodes.square_bracket_close) => { // ] operator
            return AsciiCharCodes.square_bracket_close;
        },
        @intFromEnum(AsciiCharCodes.new_line) => { // \n operator new line
            return AsciiCharCodes.new_line;
        },
        @intFromEnum(AsciiCharCodes.question_mark) => { // ? operator print current location
            if (test_mode) {
                return AsciiCharCodes.question_mark;
            }
            return error.NotInEnum;
        },
        @intFromEnum(AsciiCharCodes.exclamation_mark) => { // ! operator print current value as number
            if (test_mode) {
                return AsciiCharCodes.exclamation_mark;
            }
            return error.NotInEnum;
        },
        else => {
            return error.NotInEnum;
        },
    }
}

const CharToEnumError = error{
    NotInEnum,
};

/// check if char is combinable, ignoring '\n' chars
fn combinableChar(lastChar: AsciiCharCodes, char: AsciiCharCodes) bool {
    if ((lastChar != char) and (char != AsciiCharCodes.new_line)) {
        return false;
    }

    switch (char) {
        AsciiCharCodes.arrow_right, AsciiCharCodes.arrow_left, AsciiCharCodes.plus, AsciiCharCodes.minus, AsciiCharCodes.new_line => return true,
        else => return false,
    }
}

/// run a shell command
fn runShellCommand(comptime command_string: []const u8) !void {
    // check if input string fits inside buffer
    if (command_string.len == 0) {
        try stdout.print("No input string provided\n", .{});
        return error.InputCommandEmpty;
    }

    // fill buffer with input string and add new line at the end
    var input_buffer: [command_string.len + 1]u8 = undefined;
    var ii: usize = 0;
    for (command_string) |c| {
        input_buffer[ii] = c;
        ii += 1;
    }
    input_buffer[ii] = 10;

    const max_args = countCharInString(command_string, ' ') + 1;

    // heavily inspired by https://ratfactor.com/zig/forking-is-cool

    // The command and arguments are null-terminated strings. These arrays are
    // storage for the strings and pointers to those strings.
    var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

    // split by a single space, turn spaces and the final LF into null bytes
    var i: usize = 0;
    var n: usize = 0;
    var ofs: usize = 0;
    while (i <= command_string.len) : (i += 1) {
        if (input_buffer[i] == 0x20 or input_buffer[i] == 0xa) { //0x20 = space, 0xa = '\n'
            input_buffer[i] = 0;
            args_ptrs[n] = @as(*align(1) const [*:0]u8, @ptrCast(&input_buffer[ofs..i :0])).*;
            n += 1;
            ofs = i + 1;
        }
    }
    args_ptrs[n] = null; // add ending null

    // split process into two: child and parent
    const fork_pid = try std.os.fork();

    // 0 for child fork, else parent
    if (fork_pid == 0) {
        // create a null environment
        const env = [_:null]?[*:0]u8{null};

        // execute command, in child
        const result = std.os.execvpeZ(args_ptrs[0].?, &args_ptrs, &env);

        // fork has failed
        try ext_print.printErrorMessage("{}\n", .{result});
        return error.ForkError;
    } else {
        // wait for result
        const wait_result = std.os.waitpid(fork_pid, 0);

        // anything but 0 is an error
        if (wait_result.status != 0) {
            try ext_print.printErrorMessage("Shell command failed, command returned: {}.\n", .{wait_result.status});
            return error.ShellCommandFailed;
        }
    }
}

// count amount of 'char_to_count' in string
fn countCharInString(comptime string: []const u8, comptime char_to_count: u8) comptime_int {
    if (string.len == 0) return 0;

    var counted = 0;
    for (string) |char| {
        if (char == char_to_count) {
            counted += 1;
        }
    }

    return counted;
}
