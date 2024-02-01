const std = @import("std");
const microzig = @import("microzig");

const usb = @import("usb.zig");
const interface = @import("interface.zig");

const rp2040 = microzig.hal;
const time = rp2040.time;
const gpio = rp2040.gpio;

const key1 = gpio.num(14);
const key2 = gpio.num(15);
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
    key1.set_function(.sio);
    key1.set_pull(.up);
    key1.set_direction(.in);

    key2.set_function(.sio);
    key2.set_pull(.up);
    key2.set_direction(.in);

    uart.apply(.{
        .baud_rate = 115_200,
        .tx_pin = gpio.num(0),
        .rx_pin = gpio.num(1),
        .clock_config = rp2040.clock_config,
    });

    rp2040.uart.init_logger(uart);

    try usb.init();
    interface.init();

    var last_key1: bool = false;
    var last_key2: bool = false;

    while (true) {
        try usb.process();
        interface.process();

        if (!last_key1 and key1.read() == 0) {
            interface.pushKeyEvent(0, true);
            last_key1 = true;
        } else if (last_key1 and key1.read() == 1) {
            interface.pushKeyEvent(0, false);
            last_key1 = false;
        }

        if (!last_key2 and key2.read() == 0) {
            interface.pushKeyEvent(1, true);
            last_key2 = true;
        } else if (last_key2 and key2.read() == 1) {
            interface.pushKeyEvent(1, false);
            last_key2 = false;
        }

        time.sleep_ms(50);
    }
}
