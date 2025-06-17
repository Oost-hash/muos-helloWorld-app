-- config.lua - muOS Button Debug App Configuration
-- All constants, settings, and configurations in one place

local config = {}

-- App Information
config.APP_NAME = "Button Debug Tool"
config.APP_VERSION = "1.0"
config.SCREEN_WIDTH = 640
config.SCREEN_HEIGHT = 480

-- App States
config.STATES = {
    SETUP = 1,
    MAIN = 2,
    DEBUG = 3
}

-- File Paths
config.MAPPING_FILE = "device_mapping.lua"

-- Input Settings
config.INPUT_COOLDOWN = 0.5  -- Seconds between mapping inputs
config.AXIS_THRESHOLD = 0.5  -- Threshold for axis mapping detection
config.AXIS_DISPLAY_THRESHOLD = 0.05  -- Threshold for showing axis values in debug

-- Color Scheme
config.COLORS = {
    BACKGROUND = {0.1, 0.1, 0.2},
    SUCCESS = {0, 1, 0},
    WARNING = {1, 1, 0},
    ERROR = {1, 0, 0},
    INFO = {0, 1, 1},
    UI_TEXT = {0.8, 0.8, 1},
    WHITE = {1, 1, 1},
    GRAY = {0.5, 0.5, 0.5},
    DARK_GRAY = {0.3, 0.3, 0.3},
    LIGHT_GRAY = {0.7, 0.7, 0.7},
    AXIS_POSITIVE = {0, 1, 0},
    AXIS_NEGATIVE = {1, 0, 0},
    BUTTON_ON = {0, 1, 0},
    BUTTON_OFF = {0.4, 0.4, 0.4}
}

-- Font Sizes
config.FONTS = {
    TITLE = 24,
    COUNTER = 48,
    INSTRUCTION = 18,
    DEBUG = 12
}

-- Button Mapping Sequence (16 steps total)
config.MAPPING_SEQUENCE = {
    -- Face Buttons (4)
    {key = "button_south", instruction = "Press SOUTH button\n(bottom face button)"},
    {key = "button_east", instruction = "Press EAST button\n(right face button)"},
    {key = "button_west", instruction = "Press WEST button\n(left face button)"},
    {key = "button_north", instruction = "Press NORTH button\n(top face button)"},
    
    -- D-Pad (4)
    {key = "dpad_up", instruction = "Press D-PAD UP"},
    {key = "dpad_down", instruction = "Press D-PAD DOWN"},
    {key = "dpad_left", instruction = "Press D-PAD LEFT"},
    {key = "dpad_right", instruction = "Press D-PAD RIGHT"},
    
    -- Triggers & Shoulders (4)
    {key = "trigger_l1", instruction = "Press L1 (left shoulder)"},
    {key = "trigger_l2", instruction = "Press L2 (left trigger)"},
    {key = "trigger_r1", instruction = "Press R1 (right shoulder)"},
    {key = "trigger_r2", instruction = "Press R2 (right trigger)"},
    
    -- System Buttons (3)
    {key = "button_start", instruction = "Press START button"},
    {key = "button_select", instruction = "Press SELECT button"},
    {key = "button_menu", instruction = "Press MENU button"},
    
    -- Joystick Clicks (2)
    {key = "joystick_left_click", instruction = "Press LEFT JOYSTICK\n(push stick down)"},
    {key = "joystick_right_click", instruction = "Press RIGHT JOYSTICK\n(push stick down)"},
    
    -- Joystick Movement (4) - Optimized to only up/left directions
    {key = "joystick_left_up", instruction = "Move LEFT JOYSTICK UP\n(hold position)"},
    {key = "joystick_left_left", instruction = "Move LEFT JOYSTICK LEFT\n(hold position)"},
    {key = "joystick_right_up", instruction = "Move RIGHT JOYSTICK UP\n(hold position)"},
    {key = "joystick_right_left", instruction = "Move RIGHT JOYSTICK LEFT\n(hold position)"}
}

-- Screen Layout Settings
config.LAYOUT = {
    TITLE_Y = 20,
    COUNTER_Y = 100,
    FPS_Y = 180,
    MEMORY_Y = 200,
    CONTROLS_Y = 250,
    DEVICE_Y = 280,
    DEBUG_TITLE_Y = 20,
    DEBUG_EXIT_Y = 60,
    DEBUG_INFO_Y = 100,
    DEBUG_BUTTONS_Y = 190,
    DEBUG_AXES_Y = 190,
    DEBUG_HATS_Y = 350,
    SETUP_PROGRESS_Y = 150,
    SETUP_INSTRUCTION_Y = 200,
    SETUP_WAIT_Y = 300
}

-- Debug Screen Layout
config.DEBUG_LAYOUT = {
    BUTTONS_COLUMN1_X = 20,
    BUTTONS_COLUMN2_X = 200,
    AXES_X = 380,
    AXES_BAR_X = 480,
    AXES_BAR_WIDTH = 100,
    AXES_BAR_HEIGHT = 10,
    HATS_X = 250,
    BUTTONS_PER_COLUMN = 12,
    LINE_HEIGHT = 15,
    AXIS_LINE_HEIGHT = 20
}

-- Control Hints
config.CONTROLS = {
    MAIN_SCREEN = "South = Counter+1 | East = Reset | West = Remap | North = Debug | Menu+Start = Exit",
    DEBUG_SCREEN = "North = Return to Main | L1+R1 = Alternative Exit",
    SETUP_SCREEN = "Follow the instructions to map each button"
}

-- Exit Combinations
config.EXIT_COMBOS = {
    MAIN = {"button_menu", "button_start"},
    DEBUG_ALT = {"trigger_l1", "trigger_r1"}
}

-- Performance Settings
config.PERFORMANCE = {
    FPS_UPDATE_INTERVAL = 1.0,  -- Update FPS counter every second
    MEMORY_UPDATE_INTERVAL = 1.0  -- Update memory counter every second
}

return config