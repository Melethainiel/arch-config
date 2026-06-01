hl.monitor({
  output = "DP-2",
  mode = "3440x1440@59.97Hz",
  position = "0x0",
  scale = 1,
  transform = 1,
  cm = "srgb",
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "3440x1440@49.99Hz",
  position = "1440x1090",
  scale = 1,
  cm = "hdr",
})

hl.workspace_rule({
  workspace = "1",
  monitor = "DP-2",
  default = true,
})

hl.workspace_rule({
  workspace = "2",
  monitor = "HDMI-A-1",
  default = true,
})

hl.workspace_rule({
  workspace = "3",
  monitor = "HDMI-A-1",
  default = true,
})
