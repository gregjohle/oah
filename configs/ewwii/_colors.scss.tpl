// ============================================================================
// Core SCSS Variables
// This file will eventually be auto-generated or overridden by our 
// theme generator (Phase 4) so we keep it strictly variable-driven.
// ============================================================================

// Base Colors
$bg-color: {{ background }};
$bg-color-transparent: rgba({{ background_rgb }}, 0.97);
$fg-color: {{ foreground }};
$accent-color: {{ accent }};
$border-color: {{ color8 }};


// Popups & OSDs
$popup-bg: $bg-color-transparent;
$popup-border: $border-color;
$popup-text: $fg-color;

// Sizing & Radii
$border-radius: 12px;
$border-width: 2px;
$bar-height: 35px;
$padding: 8px;
$spacing: 16px;

// Theme Switcher
.theme-switcher-container {
  background-color: $popup-bg;
  border: $border-width solid $popup-border;
  border-radius: $border-radius;
  padding: 20px;
}
.theme-switcher-title {
  color: $accent-color;
  font-size: 24px;
  font-weight: bold;
}
.theme-switcher-preview {
  border-radius: 8px;
  border: 1px solid $border-color;
}
.theme-btn {
  padding: 8px 16px;
  background-color: $border-color;
  color: $fg-color;
  border-radius: 4px;
}
.theme-btn:hover {
  background-color: $accent-color;
  color: $bg-color;
}
.theme-btn-apply {
  padding: 8px 32px;
  background-color: $accent-color;
  color: $bg-color;
  font-weight: bold;
  border-radius: 4px;
}

// Theme Creator
.theme-creator-container {
  background-color: $popup-bg;
  border: $border-width solid $popup-border;
  border-radius: $border-radius;
  padding: 20px;
}
.theme-creator-title {
  color: $accent-color;
  font-size: 24px;
  font-weight: bold;
}
.theme-creator-preview {
  border-radius: 8px;
  border: 1px solid $border-color;
}
.theme-creator-input {
  background-color: $bg-color;
  color: $fg-color;
  border: 1px solid $border-color;
  border-radius: 4px;
  padding: 8px;
}
.color-swatch {
  min-width: 40px;
  min-height: 40px;
  border-radius: 20px;
  border: 1px solid $border-color;
}
