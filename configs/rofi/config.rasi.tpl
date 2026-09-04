* {
    background-color: {{ background }};
    text-color: {{ foreground }};
    border-color: {{ accent }};
    selected-background: {{ selection }};
    selected-text: {{ foreground }};
}
window {
    border: 2px;
    border-color: @border-color;
    background-color: @background-color;
}
element selected {
    background-color: @selected-background;
    text-color: @selected-text;
}
