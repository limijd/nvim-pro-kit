local util = require("config.util")

local function get_adapters_module()
  local ok, adapters = pcall(require, "codecompanion.adapters")
  if ok then
    return adapters
  end
end

local function is_ollama_ready()
  local disabled = vim.env.NVIM_PRO_KIT_CODECOMPANION_OLLAMA_DISABLE
  if disabled and disabled ~= "" and disabled ~= "0" and disabled:lower() ~= "false" then
    return false
  end

  if vim.fn.executable("ollama") ~= 1 then
    return false
  end

  local ok, _ = pcall(vim.fn.system, { "ollama", "list" })
  if not ok or vim.v.shell_error ~= 0 then
    return false
  end

  return true
end

local function env_nonempty(name)
  local value = vim.env[name]
  if not value then
    return nil
  end
  local trimmed = vim.trim(value)
  if trimmed == "" then
    return nil
  end
  return trimmed
end

local function build_ollama_adapter(adapters)
  if not adapters or type(adapters.extend) ~= "function" or not is_ollama_ready() then
    return nil
  end

  local model = vim.env.NVIM_PRO_KIT_CODECOMPANION_OLLAMA_MODEL or "deepseek-coder-v2:16b"
  local ok, adapter = pcall(adapters.extend, "ollama", {
    name = "ollama_deepseek",
    schema = {
      model = {
        default = model,
      },
    },
  })

  if not ok or not adapter then
    return nil
  end

  return adapter
end

local function build_deepseek_openapi_adapter(adapters)
  local base = env_nonempty("NVIM_PRO_KIT_CODECOMPANION_DEEPSEEK_BASE")
  local api_key = env_nonempty("NVIM_PRO_KIT_CODECOMPANION_DEEPSEEK_API_KEY") or env_nonempty("DEEPSEEK_API_KEY")
  local model = env_nonempty("NVIM_PRO_KIT_CODECOMPANION_DEEPSEEK_MODEL")

  if not base and not api_key and not model then
    return nil
  end

  local ok, deepseek = pcall(require, "codecompanion.adapters.http.deepseek")
  if not ok or type(deepseek) ~= "table" then
    return nil
  end

  if adapters and type(adapters.extend) == "function" then
    local ok_extend, extended = pcall(adapters.extend, deepseek)
    if ok_extend and extended then
      deepseek = extended
    end
  end

  local adapter = vim.deepcopy(deepseek)
  adapter.name = "deepseek"

  if base then
    adapter.url = base
  end

  if model then
    adapter.schema = adapter.schema or {}
    adapter.schema.model = adapter.schema.model or {}
    adapter.schema.model.choices = adapter.schema.model.choices or {}
    adapter.schema.model.choices[model] = adapter.schema.model.choices[model]
      or { formatted_name = model, opts = { can_use_tools = true } }
    adapter.schema.model.default = model
  end

  if api_key then
    adapter.env = {
      api_key = api_key,
    }
    adapter.headers = {
      ["Content-Type"] = "application/json",
      Authorization = "Bearer ${api_key}",
    }
  else
    adapter.env = nil
    adapter.headers = {
      ["Content-Type"] = "application/json",
    }
  end

  return adapter
end

local function choose_adapter()
  local adapters = get_adapters_module()
  if not adapters then
    return nil, nil
  end

  local ollama_adapter = build_ollama_adapter(adapters)
  if ollama_adapter then
    return "ollama_deepseek", {
      http = {
        ollama_deepseek = ollama_adapter,
      },
    }
  end

  local deepseek_adapter = build_deepseek_openapi_adapter(adapters)
  if deepseek_adapter then
    return "deepseek", {
      http = {
        deepseek = deepseek_adapter,
      },
    }
  end

  if env_nonempty("OPENAI_API_KEY") then
    return "openai", nil
  end

  return nil, nil
end

return {
  name = "codecompanion.nvim",
  dir = util.vendor("codecompanion.nvim"),
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  dependencies = {
    "plenary.nvim",
    "nvim-cmp",
    "nvim-treesitter",
  },
  keys = {
    {
      "<leader>ac",
      function()
        vim.cmd("CodeCompanionChat")
      end,
      desc = "CodeCompanion chat",
      mode = "n",
      silent = true,
    },
    {
      "<leader>aa",
      function()
        vim.cmd("CodeCompanionActions")
      end,
      desc = "CodeCompanion actions",
      mode = "n",
      silent = true,
    },
    {
      "<leader>ai",
      function()
        vim.cmd("CodeCompanion")
      end,
      desc = "CodeCompanion inline/chat",
      mode = { "n", "v" },
      silent = true,
    },
  },
  config = function()
    local ok, codecompanion = pcall(require, "codecompanion")
    if not ok then
      return
    end

    local preferred_adapter, adapters = choose_adapter()

    local opts = {}
    if adapters and adapters.http and next(adapters.http) then
      opts.adapters = adapters
    end
    if preferred_adapter then
      opts.interactions = {
        chat = { adapter = preferred_adapter },
        inline = { adapter = preferred_adapter },
      }
    end

    codecompanion.setup(opts)
  end,
}
