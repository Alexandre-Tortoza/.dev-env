return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "notes",
        path = "~/.wisdom/",
        overrides = {
          notes_subdir = "05-fleeting",
        },
      },
    },
    templates = {
      folder = ".templates/",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },
    ui = {
      enable = false,
    },
    note_id_func = function(title)
      local note_name = ""
      
      if title ~= nil then
        note_name = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        note_name = tostring(os.time())
      end
      
      return note_name
    end,
    note_frontmatter_func = function(note)
      local current_date = os.date("%Y-%m-%d")
      local frontmatter = {
        id = note.id,
        title = note.title,
        tags = note.tags or {},
      }
      
      if note.metadata then
        frontmatter.created = note.metadata.created or current_date
        frontmatter.updated = current_date
      else
        frontmatter.created = current_date
        frontmatter.updated = current_date
      end
      
      return frontmatter
    end,
  },
  keys = {
    {
      "<leader>On",
      function()
        vim.ui.input({ prompt = "Note title: " }, function(title)
          if title and title ~= "" then
            local obsidian = require("obsidian").get_client()
            local note = obsidian:create_note({ title = title })
            
            if note then
              vim.cmd("edit " .. tostring(note.path))
              vim.bo.modifiable = true
              vim.cmd("normal! G")
            end
          end
        end)
      end,
      desc = "New fleeting note",
    },
    {
      "<leader>Oo",
      function()
        local obsidian = require("obsidian").get_client()
        obsidian:open()
      end,
      desc = "Open Obsidian vault",
    },
    {
      "<leader>Os",
      "<cmd>ObsidianSearch<cr>",
      desc = "Search in Obsidian vault",
    },
    {
      "<leader>Oq",
      "<cmd>ObsidianQuickSwitch<cr>",
      desc = "Quick switch notes",
    },
    {
      "<leader>Of",
      "<cmd>ObsidianFollowLink<cr>",
      desc = "Follow link under cursor",
    },
    {
      "<leader>Ob",
      "<cmd>ObsidianBacklinks<cr>",
      desc = "Show backlinks",
    },
    {
      "<leader>Ot",
      "<cmd>ObsidianTags<cr>",
      desc = "Search by tags",
    },
    {
      "<leader>Ol",
      function()
        vim.ui.input({ prompt = "Literature note title: " }, function(title)
          if title and title ~= "" then
            local obsidian = require("obsidian").get_client()
            local note = obsidian:create_note({
              title = title,
              dir = obsidian:vault_root() / "06-literature",
              template = "literature.md"
            })
            
            if note then
              vim.cmd("edit " .. tostring(note.path))
              vim.bo.modifiable = true
              -- Posiciona cursor no primeiro campo vazio (author)
              vim.fn.search("author(s): $")
              vim.cmd("startinsert!")
            end
          end
        end)
      end,
      desc = "New literature note",
    },
  
  },
}
