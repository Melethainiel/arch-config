import QtQuick

QtObject {
  property color bg: Qt.rgba({{ colors.surface.dark.red }} / 255, {{ colors.surface.dark.green }} / 255, {{ colors.surface.dark.blue }} / 255, 0.86)
  property color surface: Qt.rgba({{ colors.surface_container.dark.red }} / 255, {{ colors.surface_container.dark.green }} / 255, {{ colors.surface_container.dark.blue }} / 255, 0.95)
  property color surfaceDim: Qt.rgba({{ colors.on_surface.dark.red }} / 255, {{ colors.on_surface.dark.green }} / 255, {{ colors.on_surface.dark.blue }} / 255, 0.05)
  property color surfaceHover: Qt.rgba({{ colors.on_surface.dark.red }} / 255, {{ colors.on_surface.dark.green }} / 255, {{ colors.on_surface.dark.blue }} / 255, 0.10)
  property color text: "{{ colors.on_surface.dark.hex }}"
  property color textStrong: "{{ colors.on_background.dark.hex }}"
  property color muted: "{{ colors.outline.dark.hex }}"
  property color primary: "{{ colors.primary.dark.hex }}"
  property color primaryText: "{{ colors.on_primary.dark.hex }}"
  property color secondary: "{{ colors.secondary.dark.hex }}"
  property color tertiary: "{{ colors.tertiary.dark.hex }}"
  property color error: "{{ colors.error.dark.hex }}"
  property color errorText: "{{ colors.on_error.dark.hex }}"
}
