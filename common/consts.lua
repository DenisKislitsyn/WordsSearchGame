DEVICE_INFO = sys.get_sys_info()
IS_DEBUG = sys.get_engine_info().is_debug

-- значения порядка для разных окон (используются в gui.set_render_order)
ORDER_FOR_SCREEN = 8
ORDER_FOR_MENU = 9
ORDER_FOR_HIDE_POPUP = 10
ORDER_FOR_POPUP = 11
ORDER_FOR_MSGBOX = 12
ORDER_FOR_HINT = 13
ORDER_FOR_SPINNER = 14
ORDER_FOR_NOSTACK = 15
