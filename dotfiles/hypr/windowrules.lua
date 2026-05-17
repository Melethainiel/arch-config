local centered_tools = {
  "impala",
  "btop",
  "lazydocker",
  "wiremix",
  "bluetui",
  "editor",
  "dns",
  "ssh-usb",
}

hl.window_rule({
  name = "workspace-web-and-comms",
  match = { class = "^(firefox|zen|zen-browser|LibreWolf|librewolf|Brave-browser|brave-browser|google-chrome|chromium|discord|vesktop|WebCord|teams-for-linux|Microsoft Teams.*|microsoft teams.*)$" },
  workspace = "1",
})

hl.window_rule({
  name = "workspace-games",
  match = { class = "^(steam|Steam|steam_app_[0-9]+|lutris|net\\.lutris\\.Lutris|heroic|Heroic|com\\.heroicgameslauncher\\.hgl|bottles|com\\.usebottles\\.bottles)$" },
  workspace = "2",
})

hl.window_rule({
  name = "workspace-dev",
  match = { class = "^(Alacritty|kitty|foot|com\\.mitchellh\\.ghostty.*|code|Code|code-oss|Code - OSS|codium|VSCodium)$" },
  workspace = "3",
})

hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = "20 monitor_h-120",
  float = true,
})

hl.window_rule({
  name = "terminal-opacity",
  match = { class = "^(Alacritty|kitty|foot|com\\.mitchellh\\.ghostty.*)$" },
  opacity = "0.97 0.9",
})

for _, tool in ipairs(centered_tools) do
  hl.window_rule({
    name = "float-center-" .. tool,
    match = { class = "^com\\.mitchellh\\.ghostty\\." .. tool .. "$" },
    float = true,
    center = true,
  })
end

hl.window_rule({
  name = "float-center-about",
  match = { class = "^com\\.mitchellh\\.ghostty\\.about$" },
  float = true,
  center = true,
  size = "900 620",
})
