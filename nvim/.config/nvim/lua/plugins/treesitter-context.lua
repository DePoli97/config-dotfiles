return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>uS",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "Toggle Sticky Context",
      },
    },
    opts = {
      enable = true,
      max_lines = 4,
      multiline_threshold = 20,
      min_window_height = 0,
      separator = "-",
    },
  },
}
