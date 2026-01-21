-- ============================================================================
-- UI Constants
-- ============================================================================
-- Centralized UI dimension constants for consistent styling across all views.
-- All UI components should reference this module instead of defining their own.

local UIConstants = {}

-- ============================================================================
-- Viewport (matching shove/FlexLove baseScale)
-- ============================================================================
UIConstants.VIEWPORT_WIDTH = 400
UIConstants.VIEWPORT_HEIGHT = 300

-- ============================================================================
-- Spacing
-- ============================================================================
UIConstants.PADDING = 2
UIConstants.GAP = 10
UIConstants.BORDER_WIDTH = 2

-- ============================================================================
-- Slot Dimensions
-- ============================================================================
UIConstants.SLOT_SIZE = 16
UIConstants.COLUMNS = 10
UIConstants.INV_ROWS = 4
UIConstants.TOOLBAR_ROWS = 1

-- ============================================================================
-- Typography
-- ============================================================================
UIConstants.HEADER_TEXT_SIZE = 8
UIConstants.TEXT_SIZE = 6
UIConstants.QUANTITY_OFFSET = UIConstants.SLOT_SIZE / 2 + 1

-- ============================================================================
-- Colors (using tables for compatibility with both Color.new and raw LÖVE)
-- ============================================================================
UIConstants.BACKGROUND_COLOR = {0.5, 0.45, 0.5, 1}
UIConstants.BORDER_COLOR = {1, 1, 1, 1}
UIConstants.TEXT_COLOR = {1, 1, 1, 1}
UIConstants.TEXT_COLOR_DARK = {0.2, 0.2, 0.2, 1}

-- Machine-specific colors
UIConstants.BUTTON_BACKGROUND_COLOR = {0.2, 0.2, 0.2, 1}
UIConstants.MANA_BACKGROUND_COLOR = {0.2, 0.2, 0.3, 1}
UIConstants.MANA_FILL_COLOR = {0.3, 0.5, 0.9, 1}
UIConstants.PROGRESS_BACKGROUND_COLOR = {0.2, 0.2, 0.2, 1}
UIConstants.PROGRESS_FILL_COLOR = {0.2, 0.8, 0.9, 1}

-- ============================================================================
-- Derived Dimensions (calculated from base constants)
-- ============================================================================
UIConstants.INV_WIDTH = UIConstants.COLUMNS * UIConstants.SLOT_SIZE + UIConstants.PADDING * 2
UIConstants.INV_HEIGHT = UIConstants.INV_ROWS * UIConstants.SLOT_SIZE + UIConstants.PADDING * 2
UIConstants.TOOLBAR_HEIGHT = UIConstants.TOOLBAR_ROWS * UIConstants.SLOT_SIZE + UIConstants.PADDING * 2

-- Machine view defaults
UIConstants.MACHINE_WIDTH = 160
UIConstants.MACHINE_HEIGHT = 120

return UIConstants
