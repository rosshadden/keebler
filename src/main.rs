#![no_std]
#![no_main]

use defmt::*;
use embassy_executor::Spawner;
use embassy_rp::{bind_interrupts, pio::InterruptHandler, peripherals::PIO0};
use {defmt_rtt as _, panic_probe as _};

bind_interrupts!(struct Irqs {
	PIO0_IRQ_0 => InterruptHandler<PIO0>;
});

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
	info!("hi there");
}
