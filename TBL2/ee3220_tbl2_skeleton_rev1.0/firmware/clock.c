typedef unsigned int  uint32_t;
typedef unsigned char uint8_t;

#define REG32(addr) (*(volatile uint32_t *)(addr))

#define UART_BASE     0x40000000u
#define UART_TXDATA   REG32(UART_BASE + 0x00u)
#define UART_STATUS   REG32(UART_BASE + 0x04u)
#define UART_TX_READY 0x00000001u

#define TIMER_BASE    0x40000010u
#define TIMER_STATUS  REG32(TIMER_BASE + 0x00u)
#define TIMER_VALUE   REG32(TIMER_BASE + 0x04u)
#define TIMER_TICK    0x00000001u

struct mission_time {
    uint32_t hours;
    uint32_t minutes;
    uint32_t seconds;
};

static void uart_putc(char c)
{
    while ((UART_STATUS & UART_TX_READY) == 0u) {
    }

    UART_TXDATA = (uint32_t)(uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s != '\0') {
        uart_putc(*s++);
    }
}

static void uart_put_2digits(uint32_t value)
{
    uart_putc((char)('0' + ((value / 10u) % 10u)));
    uart_putc((char)('0' + (value % 10u)));
}

static int timer_tick_pending(void)
{
    return (TIMER_STATUS & TIMER_TICK) != 0u;
}

static void timer_clear_tick(void)
{
    TIMER_STATUS = TIMER_TICK;
}

static void mission_time_tick(struct mission_time *time)
{
    time->seconds += 1u;
    if (time->seconds != 60u) {
        return;
    }

    time->seconds = 0u;
    time->minutes += 1u;
    if (time->minutes != 60u) {
        return;
    }

    time->minutes = 0u;
    time->hours += 1u;
    if (time->hours == 24u) {
        time->hours = 0u;
    }
}

static void print_time(const struct mission_time *time)
{
    uart_put_2digits(time->hours);
    uart_putc(':');
    uart_put_2digits(time->minutes);
    uart_putc(':');
    uart_put_2digits(time->seconds);
    uart_puts("\r\n");
}

int main(void)
{
    struct mission_time time = {0u, 0u, 0u};

    print_time(&time);

    for (;;) {
        if (!timer_tick_pending()) {
            continue;
        }

        timer_clear_tick();
        mission_time_tick(&time);
        print_time(&time);
    }
}
