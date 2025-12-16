-- Treesitter: treesitter情報を取得

local M = {}

function M.get_info(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if ok and parser then
    return {
      lang = parser:lang(),
      parser = parser,
    }
  end
  return nil
end

function M.has_parser(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  return ok and parser ~= nil
end

function M.get_lang(buf)
  local info = M.get_info(buf)
  return info and info.lang or nil
end

return M
