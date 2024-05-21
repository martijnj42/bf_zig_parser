const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    try stdout.print("Auto generated \n", .{});

    const max_iterations = 10000; // prevent infite loops

    var index: usize = 0;
    var array = [_]u8{0} ** 1024;
  
    // ensure all variables are used
    index += 0;
    array[0] = 0;
  
    // start bf program    
    array[index] +%= 6;
    for (0..max_iterations) |ii1|{if(ii1 >  max_iterations - 2){return error.InfiniteLoop;}else if(array[index] == 0){break;}
        index += 1;
        array[index] +%= 12;
        index -= 1;
        array[index] -%= 1;
    }
    index += 1;
    try stdout.print("{c}", .{array[index]});
    index -= 1;
    array[index] +%= 4;
    for (0..max_iterations) |ii1|{if(ii1 >  max_iterations - 2){return error.InfiniteLoop;}else if(array[index] == 0){break;}
        index += 1;
        array[index] +%= 7;
        index -= 1;
        array[index] -%= 1;
    }
    index += 1;
    array[index] +%= 1;
    try stdout.print("{c}", .{array[index]});
    array[index] +%= 7;
    try stdout.print("{c}", .{array[index]});
    try stdout.print("{c}", .{array[index]});
    array[index] +%= 3;
    try stdout.print("{c}", .{array[index]});
    index += 3;
    array[index] +%= 4;
    for (0..max_iterations) |ii1|{if(ii1 >  max_iterations - 2){return error.InfiniteLoop;}else if(array[index] == 0){break;}
        index += 1;
        array[index] +%= 8;
        index -= 1;
        array[index] -%= 1;
    }
    index += 1;
    try stdout.print("{c}", .{array[index]});
    index -= 4;
    array[index] +%= 8;
    try stdout.print("{c}", .{array[index]});
    array[index] -%= 8;
    try stdout.print("{c}", .{array[index]});
    array[index] +%= 3;
    try stdout.print("{c}", .{array[index]});
    array[index] -%= 6;
    try stdout.print("{c}", .{array[index]});
    array[index] -%= 8;
    try stdout.print("{c}", .{array[index]});

    // end bf code
    try stdout.print("\n", .{});
    const waste = max_iterations; //ensure variable usage;
    _ = waste;
}

fn ask_user() !u8 {
    var buf: [10]u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        return user_input[0];
    } else {
        return error.InvalidChar;
    }
}

const runTimeError = error{
    InfiniteLoop,
};