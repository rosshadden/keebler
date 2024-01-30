const std = @import("std");
const rp2040 = @import("rp2040");

pub fn build(b: *std.Build) void {
    const microzig = @import("microzig").init(b, "microzig");
    const optimize = b.standardOptimizeOption(.{});

    const hana = b.createModule(.{ .source_file = .{ .path = "./lib/kirei/src/lib/hana/hana.zig" } });
    const umm = b.createModule(.{ .source_file = .{ .path = "./lib/kirei/src/lib/umm/umm.zig" } });
    const uuid = b.createModule(.{ .source_file = .{ .path = "./lib/kirei/src/lib/uuid/uuid.zig" } });

    const kirei = b.createModule(.{
        .source_file = .{ .path = "./lib/kirei/src/kirei/engine.zig" },
        .dependencies = &.{
            .{ .name = "hana", .module = hana },
        },
    });

    const platform = b.option(
        enum { local, rp2040 },
        "platform",
        "Platform to build for",
    ) orelse .local;

    const target = switch (platform) {
        else => b.standardTargetOptions(.{}),
    };
    _ = target;

    const firmware = microzig.addFirmware(b, .{
        .name = "keebler",
        .target = rp2040.boards.raspberry_pi.pico,
        .optimize = optimize,
        .source_file = .{ .path = "src/main.zig" },
    });

    firmware.addAppDependency("hana", hana, .{});
    firmware.addAppDependency("kirei", kirei, .{});
    firmware.addAppDependency("umm", umm, .{});
    firmware.addAppDependency("uuid", uuid, .{});

    microzig.installFirmware(b, firmware, .{});
    microzig.installFirmware(b, firmware, .{ .format = .elf });
}
