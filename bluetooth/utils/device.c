//
//  device.c
//  bluetooth
//
//  Created by Ray chai on 2024/7/11.
//

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "nrf.h"
#include "nrf_gpio.h"
#include "nrf_delay.h"
#include "ble.h"
#include "ble_hci.h"
#include "ble_srv_common.h"
#include "nrf_sdh.h"
#include "nrf_sdh_ble.h"
#include "nrf_sdh_soc.h"
#include "app_timer.h"
#include "ble_advertising.h"
#include "ble_conn_params.h"
#include "nrf_ble_gatt.h"
#include "app_uart.h"
#include "app_error.h"
#include "boards.h"
#include "bsp_btn_ble.h"
#include "nrf_pwr_mgmt.h"
#include "nrf_dfu.h"
#include "nrf_dfu_settings.h"
#include "nrf_dfu_transport.h"
#include "nrf_dfu_utils.h"
#include "nrf_dfu_req_handler.h"

// BLE stack parameters
#define APP_BLE_CONN_CFG_TAG            1
#define DEVICE_NAME                     "MD123456"
#define NUS_SERVICE_UUID_TYPE           BLE_UUID_TYPE_VENDOR_BEGIN

// Custom Service UUID: 7610
#define CUSTOM_SERVICE_UUID             0x7610
// Custom Characteristic UUID: 0x7613
#define CUSTOM_CHAR_UUID                0x7613

// APA102C LED Control Pins
#define APA102C_CLK_PIN                 4   // Example GPIO pin for clock
#define APA102C_DATA_PIN                5   // Example GPIO pin for data
#define NUM_LEDS                        30  // Number of LEDs in the strip

// Function prototypes
void led_strip_init(void);
void led_strip_set_color(uint8_t red, uint8_t green, uint8_t blue, bool is_enabled, bool is_speed_enabled, uint8_t speed);

// BLE-related variables
BLE_ADVERTISING_DEF(m_advertising);
NRF_BLE_GATT_DEF(m_gatt);

static uint16_t   m_conn_handle = BLE_CONN_HANDLE_INVALID;
static ble_uuid_t m_adv_uuids[] = { {CUSTOM_SERVICE_UUID, NUS_SERVICE_UUID_TYPE} };

// Custom service structure
typedef struct {
    uint16_t                    service_handle;
    ble_gatts_char_handles_t    char_handles;
    uint8_t                     uuid_type;
} ble_cust_service_t;

static ble_cust_service_t m_cust_service;

// Function to initialize the LED strip
void led_strip_init(void) {
    nrf_gpio_cfg_output(APA102C_CLK_PIN);
    nrf_gpio_cfg_output(APA102C_DATA_PIN);
}

// Function to send color data to APA102C LED strip with blink and breathing effects
void led_strip_set_color(uint8_t red, uint8_t green, uint8_t blue, bool is_enabled, bool is_speed_enabled, uint8_t speed) {
    if (!is_enabled) {
        red = 0;
        green = 0;
        blue = 0;
    }

    // Calculate delay based on speed (0 to 255 mapped to a reasonable delay range)
    uint32_t delay_ms = (255 - speed) * 5; // Adjust this multiplier for desired speed range

    if (is_speed_enabled) {
        // Breathing effect (gradually increase and decrease brightness)
        uint8_t brightness = 0;
        int8_t dir = 1; // Direction: 1 for increasing, -1 for decreasing

        while (true) {
            brightness += dir;

            // Reverse direction at brightness extremes
            if (brightness == 0 || brightness == 255) {
                dir = -dir;
            }

            // Send LED frames with current brightness
            nrf_gpio_pin_clear(APA102C_CLK_PIN);
            for (int led = 0; led < NUM_LEDS; led++) {
                // Global brightness
                for (int i = 0; i < 8; i++) {
                    nrf_gpio_pin_write(APA102C_DATA_PIN, (brightness >> (7 - i)) & 0x01);
                    nrf_gpio_pin_clear(APA102C_CLK_PIN);
                    nrf_gpio_pin_set(APA102C_CLK_PIN);
                }

                // Red
                for (int i = 0; i < 8; i++) {
                    nrf_gpio_pin_write(APA102C_DATA_PIN, (red >> (7 - i)) & 0x01);
                    nrf_gpio_pin_clear(APA102C_CLK_PIN);
                    nrf_gpio_pin_set(APA102C_CLK_PIN);
                }

                // Green
                for (int i = 0; i < 8; i++) {
                    nrf_gpio_pin_write(APA102C_DATA_PIN, (green >> (7 - i)) & 0x01);
                    nrf_gpio_pin_clear(APA102C_CLK_PIN);
                    nrf_gpio_pin_set(APA102C_CLK_PIN);
                }

                // Blue
                for (int i = 0; i < 8; i++) {
                    nrf_gpio_pin_write(APA102C_DATA_PIN, (blue >> (7 - i)) & 0x01);
                    nrf_gpio_pin_clear(APA102C_CLK_PIN);
                    nrf_gpio_pin_set(APA102C_CLK_PIN);
                }
            }

            // Delay between brightness changes
            nrf_delay_ms(delay_ms);
        }
    } else {
        // Static color
        // Send start frame
        for (int i = 0; i < 4; i++) {
            nrf_gpio_pin_clear(APA102C_CLK_PIN);
            nrf_gpio_pin_set(APA102C_DATA_PIN);
            nrf_gpio_pin_set(APA102C_CLK_PIN);
        }

        // Send LED frame for each LED in the strip
        for (int led = 0; led < NUM_LEDS; led++) {
            // Global brightness
            for (int i = 0; i < 8; i++) {
                nrf_gpio_pin_clear(APA102C_CLK_PIN);
                nrf_gpio_pin_write(APA102C_DATA_PIN, (0xFF >> (7 - i)) & 0x01); // Maximum brightness
                nrf_gpio_pin_set(APA102C_CLK_PIN);
            }

            // Red
            for (int i = 0; i < 8; i++) {
                nrf_gpio_pin_clear(APA102C_CLK_PIN);
                nrf_gpio_pin_write(APA102C_DATA_PIN, (red >> (7 - i)) & 0x01);
                nrf_gpio_pin_set(APA102C_CLK_PIN);
            }

            // Green
            for (int i = 0; i < 8; i++) {
                nrf_gpio_pin_clear(APA102C_CLK_PIN);
                nrf_gpio_pin_write(APA102C_DATA_PIN, (green >> (7 - i)) & 0x01);
                nrf_gpio_pin_set(APA102C_CLK_PIN);
            }

            // Blue
            for (int i = 0; i < 8; i++) {
                nrf_gpio_pin_clear(APA102C_CLK_PIN);
                nrf_gpio_pin_write(APA102C_DATA_PIN, (blue >> (7 - i)) & 0x01);
                nrf_gpio_pin_set(APA102C_CLK_PIN);
            }
        }

        // Send end frame
        for (int i = 0; i < 4; i++) {
            nrf_gpio_pin_clear(APA102C_CLK_PIN);
            nrf_gpio_pin_set(APA102C_DATA_PIN);
            nrf_gpio_pin_set(APA102C_CLK_PIN);
        }
    }
}

// Callback function for BLE write events
static void on_ble_write(ble_evt_t const * p_ble_evt) {
    ble_gatts_evt_write_t const * p_evt_write = &p_ble_evt->evt.gatts_evt.params.write;

    // Check if the write is to the custom characteristic
    if (p_evt_write->handle == m_cust_service.char_handles.value_handle) {
        // Expecting 8 bytes of data
        if (p_evt_write->len == 8) {
            uint8_t *data = p_evt_write->data;
            uint8_t red = data[2];
            uint8_t green = data[3];
            uint8_t blue = data[4];
            bool is_enabled = data[5];
            bool is_speed_enabled = data[6];
            uint8_t speed = data[7];

            // Set LED strip color and effects based on received data
            led_strip_set_color(red, green, blue, is_enabled, is_speed_enabled, speed);
        }
    }
}

// BLE event handler
static void ble_evt_handler(ble_evt_t const * p_ble_evt, void * p_context) {
    switch (p_ble_evt->header.evt_id) {
        case BLE_GAP_EVT_CONNECTED:
            m_conn_handle = p_ble_evt->evt.gap_evt.conn_handle;
            break;

        case BLE_GAP_EVT_DISCONNECTED:
            m_conn_handle = BLE_CONN_HANDLE_INVALID;
            break;

        case BLE_GATTS_EVT_WRITE:
            on_ble_write(p_ble_evt);
            break;

        default:
            break;
    }
}

// Function to initialize BLE stack
static void ble_stack_init(void) {
    ret_code_t err_code;
    nrf_sdh_ble_cfg_t ble_cfg;
    memset(&ble_cfg, 0x00, sizeof(ble_cfg));

    // Configure the connection count and the number of UUIDs
    ble_cfg.gap_cfg.role_count_cfg.periph_role_count = 1;
    err_code = sd_ble_cfg_set(BLE_GAP_CFG_ROLE_COUNT, &ble_cfg, BLE_CONN_CFG_TAG);
    APP_ERROR_CHECK(err_code);

    // Enable BLE stack
    err_code = nrf_sdh_ble_default_cfg_set(APP_BLE_CONN_CFG_TAG, &ble_cfg);
    APP_ERROR_CHECK(err_code);

    err_code = nrf_sdh_ble_enable(&ble_cfg);
    APP_ERROR_CHECK(err_code);

    // Register handler for BLE events
    NRF_SDH_BLE_OBSERVER(m_ble_observer, APP_BLE_OBSERVER_PRIO, ble_evt_handler, NULL);
}

// Function to initialize GAP parameters
static void gap_params_init(void) {
    ret_code_t err_code;
    ble_gap_conn_params_t gap_conn_params;
    ble_gap_conn_sec_mode_t sec_mode;

    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&sec_mode);

    err_code = sd_ble_gap_device_name_set(&sec_mode, (const uint8_t *)DEVICE_NAME, strlen(DEVICE_NAME));
    APP_ERROR_CHECK(err_code);

    memset(&gap_conn_params, 0, sizeof(gap_conn_params));

    gap_conn_params.min_conn_interval = MSEC_TO_UNITS(100, UNIT_1_25_MS);
    gap_conn_params.max_conn_interval = MSEC_TO_UNITS(200, UNIT_1_25_MS);
    gap_conn_params.slave_latency     = 0;
    gap_conn_params.conn_sup_timeout  = MSEC_TO_UNITS(4000, UNIT_10_MS);

    err_code = sd_ble_gap_ppcp_set(&gap_conn_params);
    APP_ERROR_CHECK(err_code);
}

// Function to initialize GATT
static void gatt_init(void) {
    ret_code_t err_code = nrf_ble_gatt_init(&m_gatt, NULL);
    APP_ERROR_CHECK(err_code);
}

// Function to initialize advertising
static void advertising_init(void) {
    ret_code_t err_code;
    ble_advertising_init_t init;

    memset(&init, 0, sizeof(init));

    init.advdata.name_type               = BLE_ADVDATA_FULL_NAME;
    init.advdata.include_appearance      = false;
    init.advdata.flags                   = BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE;
    init.srdata.uuids_complete.uuid_cnt  = sizeof(m_adv_uuids) / sizeof(m_adv_uuids[0]);
    init.srdata.uuids_complete.p_uuids   = m_adv_uuids;

    init.config.ble_adv_fast_enabled  = true;
    init.config.ble_adv_fast_interval = APP_ADV_INTERVAL;
    init.config.ble_adv_fast_timeout  = APP_ADV_DURATION;

    init.evt_handler = NULL;

    err_code = ble_advertising_init(&m_advertising, &init);
    APP_ERROR_CHECK(err_code);

    ble_advertising_conn_cfg_tag_set(&m_advertising, APP_BLE_CONN_CFG_TAG);
}

// Function to initialize connection parameters
static void conn_params_init(void) {
    ret_code_t err_code;
    ble_conn_params_init_t cp_init;

    memset(&cp_init, 0, sizeof(cp_init));

    cp_init.p_conn_params                  = NULL;
    cp_init.first_conn_params_update_delay = APP_TIMER_TICKS(5000);
    cp_init.next_conn_params_update_delay  = APP_TIMER_TICKS(30000);
    cp_init.max_conn_params_update_count   = 3;
    cp_init.start_on_notify_cccd_handle    = BLE_GATT_HANDLE_INVALID;
    cp_init.disconnect_on_fail             = false;
    cp_init.evt_handler                    = NULL;
    cp_init.error_handler                  = NULL;

    err_code = ble_conn_params_init(&cp_init);
    APP_ERROR_CHECK(err_code);
}

// Function to initialize the power management module
static void power_management_init(void) {
    ret_code_t err_code = nrf_pwr_mgmt_init();
    APP_ERROR_CHECK(err_code);
}

// Function to start advertising
static void advertising_start(void) {
    ret_code_t err_code = ble_advertising_start(&m_advertising, BLE_ADV_MODE_FAST);
    APP_ERROR_CHECK(err_code);
}

// Function to initialize the custom service
static void cust_service_init(void) {
    ret_code_t err_code;
    ble_uuid_t service_uuid;
    ble_uuid128_t base_uuid = {CUSTOM_SERVICE_UUID};

    err_code = sd_ble_uuid_vs_add(&base_uuid, &m_cust_service.uuid_type);
    APP_ERROR_CHECK(err_code);

    service_uuid.type = m_cust_service.uuid_type;
    service_uuid.uuid = CUSTOM_SERVICE_UUID;

    err_code = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY, &service_uuid, &m_cust_service.service_handle);
    APP_ERROR_CHECK(err_code);

    // Add custom characteristic
    ble_gatts_char_md_t char_md;
    memset(&char_md, 0, sizeof(char_md));
    char_md.char_props.write = 1;
    char_md.char_props.write_wo_resp = 0; // write with response

    ble_gatts_attr_md_t attr_md;
    memset(&attr_md, 0, sizeof(attr_md));
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
    attr_md.vloc = BLE_GATTS_VLOC_STACK;

    ble_uuid_t char_uuid;
    char_uuid.type = m_cust_service.uuid_type;
    char_uuid.uuid = CUSTOM_CHAR_UUID;

    ble_gatts_attr_t    attr_char_value;
    memset(&attr_char_value, 0, sizeof(attr_char_value));
    attr_char_value.p_uuid    = &char_uuid;
    attr_char_value.p_attr_md = &attr_md;
    attr_char_value.init_len  = sizeof(uint8_t);
    attr_char_value.init_offs = 0;
    attr_char_value.max_len   = 8; // Expecting 8 bytes for this characteristic

    err_code = sd_ble_gatts_characteristic_add(m_cust_service.service_handle, &char_md, &attr_char_value, &m_cust_service.char_handles);
    APP_ERROR_CHECK(err_code);
}

// Main function
int main(void) {
    // Initialize BLE stack
    ble_stack_init();

    // Initialize GAP parameters
    gap_params_init();

    // Initialize GATT
    gatt_init();

    // Initialize advertising
    advertising_init();

    // Initialize connection parameters
    conn_params_init();

    // Initialize power management
    power_management_init();

    // Initialize LED strip
    led_strip_init();

    // Initialize custom service
    cust_service_init();

    // Initialize DFU service
    ble_dfu_init();

    // Check if we need to enter DFU mode
    check_for_dfu_mode();

    // Start advertising
    advertising_start();

    // Enter main loop
    while (true) {
        nrf_pwr_mgmt_run();
    }
}
