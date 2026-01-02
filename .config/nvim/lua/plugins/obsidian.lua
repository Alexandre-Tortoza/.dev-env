return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
        heading = {
          icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
        },
        bullet = {
          icons = { "●", "○", "◆", "◇" },
        },
        checkbox = {
          unchecked = { icon = "󰄱 " },
          checked = { icon = " " },
        },
        code = {
          sign = true,
          width = "block",
          right_pad = 1,
        },
      },
    },
    {
      "iamcco/markdown-preview.nvim",
      build = "cd app && npm install",
      ft = { "markdown" },
    },
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    -- Usa os novos comandos (Obsidian xxx) ao invés dos legados (ObsidianXxx)
    legacy_commands = false,

    workspaces = {
      {
        name = "wisdom",
        path = "~/.wisdom",
      },
    },

    -- Notas novas vão para fleeting por padrão (inbox do Zettelkasten)
    notes_subdir = "05-fleeting",
    new_notes_location = "notes_subdir",

    -- Função para gerar ID/nome das notas (slug amigável)
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        -- Transforma título em slug: lowercase, espaços para hífens
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-áéíóúâêîôûãõç]", ""):lower()
      else
        -- Fallback para timestamp se não tiver título
        suffix = tostring(os.time())
      end
      return suffix
    end,

    -- Função para gerar frontmatter automaticamente
    note_frontmatter_func = function(note)
      local out = {
        id = note.id,
        aliases = note.aliases,
        tags = note.tags,
        date = os.date("%Y-%m-%d"),
      }
      -- Preserva campos extras do frontmatter existente
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end
      return out
    end,

    -- Templates
    templates = {
      folder = ".templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- Substitutions customizadas para templates
      substitutions = {
        yesterday = function()
          return os.date("%Y-%m-%d", os.time() - 86400)
        end,
        tomorrow = function()
          return os.date("%Y-%m-%d", os.time() + 86400)
        end,
        week = function()
          return os.date("%V")
        end,
        weekday = function()
          local days = { "Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado" }
          return days[tonumber(os.date("%w")) + 1]
        end,
      },
    },

    -- Diário - usando a pasta 08-daily
    daily_notes = {
      folder = "08-daily",
      date_format = "%Y-%m-%d",
      template = "daily-note.md",
      -- Alias automático com data formatada
      alias_format = "%d/%m/%Y",
    },

    -- Completions
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    -- Configuração de links
    wiki_link_func = "use_alias_only",
    preferred_link_style = "wiki",

    -- Picker (telescope)
    picker = {
      name = "telescope.nvim",
      note_mappings = {
        new = "<C-n>",
        insert_link = "<C-l>",
      },
      tag_mappings = {
        tag_note = "<C-t>",
        insert_tag = "<C-i>",
      },
    },

    -- Callbacks para automação
    callbacks = {
      post_setup = function(client)
        vim.g.obsidian_client = client
      end,
    },

    -- Checkboxes - nova API com ordem definida
    checkbox = {
      order = { " ", "x", ">", "~", "!", "?", "/" },
      [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
      ["x"] = { char = "", hl_group = "ObsidianDone" },
      [">"] = { char = "", hl_group = "ObsidianRightArrow" },
      ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
      ["!"] = { char = "", hl_group = "ObsidianImportant" },
      ["?"] = { char = "", hl_group = "ObsidianQuestion" },
      ["/"] = { char = "󰡖", hl_group = "ObsidianHalfway" },
    },

    -- UI (renderização delegada ao render-markdown.nvim)
    ui = {
      enable = false,
    },

    -- Footer (desabilitado para evitar erros de backlinks)
    footer = {
      enabled = false,
    },

    -- Anexos
    attachments = {
      img_folder = ".attachments",
      img_name_func = function()
        return string.format("img-%s", os.date("%Y%m%d%H%M%S"))
      end,
    },

    -- Seguir URLs automaticamente
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url })
    end,
  },

  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Comandos customizados para criar notas em pastas específicas
    local function create_note_in_folder(folder, template)
      return function()
        local title = vim.fn.input("Título: ")
        if title == "" then
          return
        end
        local slug = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        local path = vim.fn.expand("~/.wisdom/" .. folder .. "/" .. slug .. ".md")

        -- Cria o arquivo
        vim.cmd("edit " .. path)

        -- Insere template se especificado (nova API: Obsidian template)
        if template then
          vim.cmd("Obsidian template " .. template)
        end
      end
    end

    -- Comandos para cada tipo de nota PARA
    vim.api.nvim_create_user_command("ObsidianProject", create_note_in_folder("01-project", "project.md"), {})
    vim.api.nvim_create_user_command("ObsidianArea", create_note_in_folder("02-area", nil), {})
    vim.api.nvim_create_user_command("ObsidianResource", create_note_in_folder("03-resource", nil), {})
    vim.api.nvim_create_user_command("ObsidianArchive", create_note_in_folder("04-archive", nil), {})
    vim.api.nvim_create_user_command("ObsidianFleeting", create_note_in_folder("05-fleeting", nil), {})
    vim.api.nvim_create_user_command("ObsidianLiterature", create_note_in_folder("06-literature", "iterature.md"), {})
    vim.api.nvim_create_user_command("ObsidianPermanent", create_note_in_folder("07-permanent", nil), {})

    -- Comandos para notas de estudo
    vim.api.nvim_create_user_command(
      "ObsidianAlgorithm",
      create_note_in_folder("03-resource/algorithms", "algorithm-note.md"),
      {}
    )
    vim.api.nvim_create_user_command(
      "ObsidianLeetCode",
      create_note_in_folder("03-resource/leetcode", "leetcode-problem.md"),
      {}
    )
    vim.api.nvim_create_user_command(
      "ObsidianCodeWars",
      create_note_in_folder("03-resource/codewars", "code-wars.md"),
      {}
    )

    -- Comando para mover nota atual para outra pasta PARA
    vim.api.nvim_create_user_command("ObsidianMoveTo", function()
      local folders = {
        "01-project",
        "02-area",
        "03-resource",
        "04-archive",
        "05-fleeting",
        "06-literature",
        "07-permanent",
        "08-daily",
      }
      vim.ui.select(folders, { prompt = "Mover para:" }, function(choice)
        if choice then
          local current_file = vim.fn.expand("%:t")
          local new_path = vim.fn.expand("~/.wisdom/" .. choice .. "/" .. current_file)
          vim.cmd("!mv '%' '" .. new_path .. "'")
          vim.cmd("edit " .. new_path)
          vim.cmd("bdelete #")
        end
      end)
    end, {})

    -- Comando para buscar por pasta específica
    vim.api.nvim_create_user_command("ObsidianSearchFolder", function()
      local folders = {
        { name = "Projetos", path = "01-project" },
        { name = "Áreas", path = "02-area" },
        { name = "Recursos", path = "03-resource" },
        { name = "Arquivo", path = "04-archive" },
        { name = "Fleeting", path = "05-fleeting" },
        { name = "Literatura", path = "06-literature" },
        { name = "Permanent", path = "07-permanent" },
        { name = "Diário", path = "08-daily" },
      }
      local names = vim.tbl_map(function(f)
        return f.name
      end, folders)
      vim.ui.select(names, { prompt = "Buscar em:" }, function(choice, idx)
        if choice then
          require("telescope.builtin").find_files({
            cwd = vim.fn.expand("~/.wisdom/" .. folders[idx].path),
            prompt_title = "Notas em " .. choice,
          })
        end
      end)
    end, {})
  end,

  keys = {
    -- Menu principal
    { "<leader>O", "", desc = "+Obsidian" },

    -- Navegação básica (novos comandos: Obsidian xxx)
    { "<leader>Oo", "<cmd>Obsidian quick_switch<cr>", desc = "Abrir nota" },
    { "<leader>Os", "<cmd>Obsidian search<cr>", desc = "Buscar conteúdo" },
    { "<leader>OS", "<cmd>ObsidianSearchFolder<cr>", desc = "Buscar por pasta" },
    { "<leader>Of", "<cmd>Obsidian follow_link<cr>", desc = "Seguir link" },
    { "<leader>Ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
    { "<leader>Ol", "<cmd>Obsidian links<cr>", desc = "Links da nota" },
    { "<leader>OT", "<cmd>Obsidian tags<cr>", desc = "Buscar por tags" },

    -- Notas diárias
    { "<leader>Od", "<cmd>Obsidian today<cr>", desc = "Hoje" },
    { "<leader>Oy", "<cmd>Obsidian yesterday<cr>", desc = "Ontem" },
    { "<leader>Ot", "<cmd>Obsidian tomorrow<cr>", desc = "Amanhã" },
    { "<leader>OD", "<cmd>Obsidian dailies<cr>", desc = "Lista de diários" },

    -- Criar notas (submenu n)
    { "<leader>On", "", desc = "+Nova nota" },
    { "<leader>Onn", "<cmd>Obsidian new<cr>", desc = "Nova (fleeting)" },
    { "<leader>Onp", "<cmd>ObsidianProject<cr>", desc = "Novo projeto" },
    { "<leader>Ona", "<cmd>ObsidianAlgorithm<cr>", desc = "Novo algoritmo" },
    { "<leader>Onl", "<cmd>ObsidianLeetCode<cr>", desc = "Novo LeetCode" },
    { "<leader>Onc", "<cmd>ObsidianCodeWars<cr>", desc = "Novo CodeWars" },
    { "<leader>OnL", "<cmd>ObsidianLiterature<cr>", desc = "Nova literatura" },
    { "<leader>OnP", "<cmd>ObsidianPermanent<cr>", desc = "Nova permanente" },
    { "<leader>Ont", "<cmd>Obsidian new_from_template<cr>", desc = "Nova de template" },

    -- Templates e edição
    { "<leader>Oe", "<cmd>Obsidian template<cr>", desc = "Inserir template" },
    { "<leader>Oc", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle checkbox" },
    { "<leader>Op", "<cmd>Obsidian paste_img<cr>", desc = "Colar imagem" },
    { "<leader>Or", "<cmd>Obsidian rename<cr>", desc = "Renomear nota" },
    { "<leader>Om", "<cmd>ObsidianMoveTo<cr>", desc = "Mover para pasta" },
    { "<leader>Oi", "<cmd>Obsidian toc<cr>", desc = "Índice (TOC)" },

    -- Visual mode
    { "<leader>Ox", "<cmd>Obsidian extract_note<cr>", desc = "Extrair para nota", mode = "v" },
    { "<leader>OL", "<cmd>Obsidian link_new<cr>", desc = "Link para nova nota", mode = "v" },
    { "<leader>Ol", "<cmd>Obsidian link<cr>", desc = "Link para nota", mode = "v" },

    -- Workspace e app
    { "<leader>Ow", "<cmd>Obsidian workspace<cr>", desc = "Trocar workspace" },
    { "<leader>Oa", "<cmd>Obsidian open<cr>", desc = "Abrir no Obsidian app" },
  },
}