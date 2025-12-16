-- Float Detect: スクリーン座標からフローティングウィンドウを検出

local M = {}

function M.find_at_position(screenrow, screencol, exclude_win)
  local candidates = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= exclude_win then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        local row = config.row or 0
        local col = config.col or 0
        local width = config.width or 0
        local height = config.height or 0

        if type(row) == "table" then row = row[false] or 0 end
        if type(col) == "table" then col = col[false] or 0 end
        row = tonumber(row) or 0
        col = tonumber(col) or 0

        if config.border then
          row = row - 1
          col = col - 1
          width = width + 2
          height = height + 2
        end

        if screenrow >= row and screenrow < row + height and
           screencol >= col and screencol < col + width then
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          local zindex = config.zindex or 50
          table.insert(candidates, {
            win = win,
            buf = buf,
            ft = ft,
            zindex = zindex,
            config = config,
          })
        end
      end
    end
  end

  if #candidates == 0 then
    return nil
  end

  table.sort(candidates, function(a, b)
    local a_has_ft = (a.ft and a.ft ~= "") and 1 or 0
    local b_has_ft = (b.ft and b.ft ~= "") and 1 or 0
    if a_has_ft ~= b_has_ft then
      return a_has_ft > b_has_ft
    end
    return a.zindex > b.zindex
  end)

  return candidates[1]
end

function M.get_visible_floats(exclude_win)
  local floats = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= exclude_win then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        local buf = vim.api.nvim_win_get_buf(win)

        local title_str = nil
        if config.title then
          if type(config.title) == "string" then
            title_str = config.title
          elseif type(config.title) == "table" and #config.title > 0 then
            local first = config.title[1]
            if type(first) == "string" then
              title_str = first
            elseif type(first) == "table" and first[1] then
              title_str = first[1]
            end
          end
        end

        table.insert(floats, {
          win = win,
          buf = buf,
          title = title_str,
          config = config,
        })
      end
    end
  end

  return floats
end

function M.is_floating(win)
  local config = vim.api.nvim_win_get_config(win)
  return config.relative ~= ""
end

return M
