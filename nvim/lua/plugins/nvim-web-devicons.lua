local util = require("config.util")

return {
  name = "nvim-web-devicons",
  dir = util.vendor("nvim-web-devicons"),
  config = function()
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
      vim.notify("nvim-web-devicons failed to load", vim.log.levels.WARN)
      return
    end

    devicons.setup({
      color_icons = true,
      default = true,
      override_by_extension = {
        lua = {
          icon = "",
          color = "#51a0cf",
          name = "Lua",
        },
        py = {
          icon = "",
          color = "#ffbc03",
          name = "Python",
        },
        rs = {
          icon = "",
          color = "#dea584",
          name = "Rust",
        },
        go = {
          icon = "",
          color = "#00add8",
          name = "Go",
        },
        ts = {
          icon = "",
          color = "#519aba",
          name = "TypeScript",
        },
        js = {
          icon = "",
          color = "#f7df1e",
          name = "JavaScript",
        },
        jsx = {
          icon = "",
          color = "#519aba",
          name = "JavaScriptReact",
        },
        tsx = {
          icon = "",
          color = "#519aba",
          name = "TypeScriptReact",
        },
        json = {
          icon = "",
          color = "#cbcb41",
          name = "Json",
        },
        lock = {
          icon = "",
          color = "#c678dd",
          name = "Lock",
        },
        md = {
          icon = "",
          color = "#519aba",
          name = "Markdown",
        },
        sh = {
          icon = "",
          color = "#4d5a5e",
          name = "Shell",
        },
        toml = {
          icon = "",
          color = "#6d8086",
          name = "Toml",
        },
        yml = {
          icon = "",
          color = "#6d8086",
          name = "Yaml",
        },
        yaml = {
          icon = "",
          color = "#6d8086",
          name = "Yaml",
        },
      },
      override_by_filename = {
        ["Dockerfile"] = {
          icon = "",
          color = "#0db7ed",
          name = "Dockerfile",
        },
        [".gitignore"] = {
          icon = "",
          color = "#f14c28",
          name = "GitIgnore",
        },
        ["Makefile"] = {
          icon = "",
          color = "#6d8086",
          name = "Makefile",
        },
        ["LICENSE"] = {
          icon = "",
          color = "#cfcfcf",
          name = "License",
        },
        ["README.md"] = {
          icon = "",
          color = "#519aba",
          name = "Readme",
        },
      },
    })
  end,
}

