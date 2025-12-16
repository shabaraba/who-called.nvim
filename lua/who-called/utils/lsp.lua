-- LSP: LSPクライアント情報を取得

local M = {}

function M.get_clients(buf)
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients == 0 then
    return nil
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return names
end

function M.has_clients(buf)
  local clients = vim.lsp.get_clients({ bufnr = buf })
  return #clients > 0
end

return M
