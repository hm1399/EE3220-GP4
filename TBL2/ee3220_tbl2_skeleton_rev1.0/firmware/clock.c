typedef unsigned int  uint32_t;
typedef unsigned char uint8_t;

#define REG32(addr) (*(volatile uint32_t *)(addr))

#define UART_BASE     0x40000000u
#define UART_TXDATA   REG32(UART_BASE + 0x00u)
#define UART_STATUS   REG32(UART_BASE + 0x04u)
#define UART_RXDATA   REG32(UART_BASE + 0x08u)
#define UART_TX_READY 0x00000001u
#define UART_RX_VALID 0x00000002u

#define TIMER_BASE    0x40000010u
#define TIMER_STATUS  REG32(TIMER_BASE + 0x00u)
#define TIMER_VALUE   REG32(TIMER_BASE + 0x04u)
#define TIMER_TICK    0x00000001u

#define BUTTON_BASE          0x40000020u
#define BUTTON_STATUS        REG32(BUTTON_BASE + 0x00u)
#define BUTTON_JUMP_SEC_55   0x00000001u
#define BUTTON_JUMP_MIN_5955 0x00000002u
#define BUTTON_JUMP_DAY_END  0x00000004u

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
    uint8_t tens = 0u;

    // Avoid division/modulus helpers so the bare-metal build does not depend
    // on libgcc runtime support for small integer formatting.
    while (value >= 10u) {
        value -= 10u;
        tens += 1u;
    }

    uart_putc((char)('0' + tens));
    uart_putc((char)('0' + (uint8_t)value));
}

static int uart_rx_ready(void)
{
    return (UART_STATUS & UART_RX_VALID) != 0u;
}

static uint8_t uart_getc(void)
{
    return (uint8_t)UART_RXDATA;
}

static int timer_tick_pending(void)
{
    return (TIMER_STATUS & TIMER_TICK) != 0u;
}

static void timer_clear_tick(void)
{
    TIMER_STATUS = TIMER_TICK;
}

static uint32_t button_rising_edges(uint32_t *previous_buttons)
{
    uint32_t current_buttons =
        BUTTON_STATUS & (BUTTON_JUMP_SEC_55 | BUTTON_JUMP_MIN_5955 | BUTTON_JUMP_DAY_END);
    uint32_t rising_edges = current_buttons & ~(*previous_buttons);

    *previous_buttons = current_buttons;
    return rising_edges;
}

static int is_ascii_digit(char c)
{
    return (c >= '0') && (c <= '9');
}

static uint32_t parse_2digits(const char *text)
{
    uint32_t tens = (uint32_t)(uint8_t)(text[0] - '0');
    uint32_t ones = (uint32_t)(uint8_t)(text[1] - '0');

    return (tens << 3) + (tens << 1) + ones;
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

static int try_set_time_from_text(struct mission_time *time, const char *text)
{
    uint32_t hours;
    uint32_t minutes;
    uint32_t seconds;

    if (!is_ascii_digit(text[0]) || !is_ascii_digit(text[1]) ||
        (text[2] != ':') ||
        !is_ascii_digit(text[3]) || !is_ascii_digit(text[4]) ||
        (text[5] != ':') ||
        !is_ascii_digit(text[6]) || !is_ascii_digit(text[7])) {
        return 0;
    }

    hours = parse_2digits(&text[0]);
    minutes = parse_2digits(&text[3]);
    seconds = parse_2digits(&text[6]);

    if ((hours >= 24u) || (minutes >= 60u) || (seconds >= 60u)) {
        return 0;
    }

    time->hours = hours;
    time->minutes = minutes;
    time->seconds = seconds;
    return 1;
}

static void apply_button_shortcut(struct mission_time *time, uint32_t button_edges)
{
    if ((button_edges & BUTTON_JUMP_DAY_END) != 0u) {
        time->hours = 23u;
        time->minutes = 59u;
        time->seconds = 55u;
        print_time(time);
        return;
    }

    if ((button_edges & BUTTON_JUMP_MIN_5955) != 0u) {
        time->minutes = 59u;
        time->seconds = 55u;
        print_time(time);
        return;
    }

    if ((button_edges & BUTTON_JUMP_SEC_55) != 0u) {
        time->seconds = 55u;
        print_time(time);
    }
}

static void poll_uart_set_time(struct mission_time *time, char *rx_buffer, uint32_t *rx_index)
{
    while (uart_rx_ready()) {
        char received = (char)uart_getc();

        if ((received == '\r') || (received == '\n')) {
            if ((*rx_index == 8u) && try_set_time_from_text(time, rx_buffer)) {
                print_time(time);
            }
            *rx_index = 0u;
            continue;
        }

        if (*rx_index < 8u) {
            rx_buffer[*rx_index] = received;
            *rx_index += 1u;
        } else {
            *rx_index = 9u;
        }
    }
}

int main(void)
{
    struct mission_time time = {0u, 0u, 0u};
    uint32_t previous_buttons = 0u;
    char rx_buffer[8];
    uint32_t rx_index = 0u;

    print_time(&time);

    for (;;) {
        poll_uart_set_time(&time, rx_buffer, &rx_index);

        uint32_t button_edges = button_rising_edges(&previous_buttons);

        if (button_edges != 0u) {
            apply_button_shortcut(&time, button_edges);
        }

        if (!timer_tick_pending()) {
            continue;
        }

        timer_clear_tick();
        mission_time_tick(&time);
        print_time(&time);
    }
}
