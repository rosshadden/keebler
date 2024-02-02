const std = @import("std");
const microzig = @import("microzig");

const usb = @import("usb.zig");
const interface = @import("interface.zig");

const rp2040 = microzig.hal;
const time = rp2040.time;
const gpio = rp2040.gpio;

const col0 = gpio.num(14);
const col1 = gpio.num(15);
const row0 = gpio.num(16);
const row1 = gpio.num(17);

const uart = rp2040.uart.num(0);

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = rp2040.uart.log;
};

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    std.log.err("panic: {s}", .{message});
    @breakpoint();
    while (true) {}
}

pub fn main() !void {
    row0.set_function(.sio);
    row0.set_pull(.up);
    row0.set_direction(.in);
    row1.set_function(.sio);
    row1.set_pull(.up);
    row1.set_direction(.in);

    col0.set_function(.sio);
    col0.set_direction(.out);
    col1.set_function(.sio);
    col1.set_direction(.out);

    uart.apply(.{
        .baud_rate = 115_200,
        .tx_pin = gpio.num(0),
        .rx_pin = gpio.num(1),
        .clock_config = rp2040.clock_config,
    });

    rp2040.uart.init_logger(uart);

    try usb.init();
    interface.init();

    var last_a = false;
    var last_b = false;
    var last_c = false;
    var last_d = false;

    while (true) {
        try usb.process();
        interface.process();

        col0.put(0);
        if (!last_a and row0.read() == 0) {
            interface.pushKeyEvent(0, true);
            last_a = !last_a;
        } else if (last_a and row0.read() == 1) {
            interface.pushKeyEvent(0, false);
            last_a = !last_a;
        }
        if (!last_c and row1.read() == 0) {
            interface.pushKeyEvent(2, true);
            last_c = !last_c;
        } else if (last_c and row1.read() == 1) {
            interface.pushKeyEvent(2, false);
            last_c = !last_c;
        }
        col0.put(1);

        col1.put(0);
        if (!last_b and row0.read() == 0) {
            interface.pushKeyEvent(1, true);
            last_b = !last_b;
        } else if (last_b and row0.read() == 1) {
            interface.pushKeyEvent(1, false);
            last_b = !last_b;
        }
        if (!last_d and row1.read() == 0) {
            interface.pushKeyEvent(3, true);
            last_d = !last_d;
        } else if (last_d and row1.read() == 1) {
            interface.pushKeyEvent(3, false);
            last_d = !last_d;
        }
        col1.put(1);
    }
}
