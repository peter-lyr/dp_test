local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'git@github.com:peter-lyr/dp_lsp',
    } then
  return
end

function M.dp_plugins()
  function M.run_one_do(cmd_list)
    local dp_plugins = B.get_dp_plugins()
    local cmd = {}
    for _, dp in ipairs(dp_plugins) do
      local temp = vim.fn.join(cmd_list, ' && ')
      cmd[#cmd + 1] = string.format('%s & echo. & echo %s & %s', B.system_cd(dp), dp, temp)
    end
    B.system_run('start', vim.fn.join(cmd, ' & ') .. ' & echo. & pause')
  end

  function M.run_multi_do(cmd_list)
    local dp_plugins = B.get_dp_plugins()
    for _, dp in ipairs(dp_plugins) do
      local temp = vim.fn.join(cmd_list, ' && ')
      B.system_run('start', string.format('%s & echo. & echo %s & %s', B.system_cd(dp), dp, temp))
    end
  end

  vim.api.nvim_create_user_command('DpBranchStatus', function()
    M.run_one_do {
      'git branch -v',
      'git status -s',
    }
  end, {
    nargs = 0,
    desc = 'DpShow',
  })

  vim.api.nvim_create_user_command('DpAddCommitPushDot', function()
    M.run_multi_do {
      'git add .',
      string.format('git commit -m "%s"', vim.fn.input('commit info: ', '.')),
      'git push',
    }
  end, {
    nargs = 0,
    desc = 'DpPushDot',
  })

  vim.api.nvim_create_user_command('DpCheckOutMainPull', function()
    M.run_multi_do {
      'git checkout main',
      'git pull',
    }
  end, {
    nargs = 0,
    desc = 'DpCheckOutMainPull',
  })
end

function M.map()
  vim.api.nvim_create_user_command('MapFromLazyToWhichkey', function(params)
    M.map_from_lazy_to_whichkey(unpack(params['fargs']))
  end, { nargs = 0, })
  function M.map_from_lazy_to_whichkey(fname)
    if not fname then
      fname = string.gsub(vim.api.nvim_buf_get_name(0), '/', '\\')
    end
    if #fname == 0 then
      return
    end
    local new_lines = {}
    for _, line in ipairs(vim.fn.readfile(fname)) do
      local res = string.match(line, '^ +({.*mode *= *.*}) *,')
      if not res then
        res = string.match(line, '^ +({.*name *= *.*}) *,')
      end
      if res then
        local temp = string.format([[
          local sta, B = pcall(require, 'dp_base')
          if not sta then return nil end
          local M = {}
          M.lua = B.getlua(vim.api.nvim_buf_get_name(0))
          return %s
        ]], res)
        local item = loadstring(temp)
        if item then
          local val = item()
          if type(val[2]) == 'function' then
            val[2] = string.match(res, '(function().+end),')
          end
          local lhs = table.remove(val, 1)
          if not val['name'] then
            val[#val + 1] = val['desc']
            val['desc'] = nil
          end
          temp = string.gsub(vim.inspect { [lhs] = val, }, '%s+', ' ')
          temp = string.gsub(temp, '"(function().+end)",', '%1,')
          temp = string.gsub(temp, '\\"', '"')
          temp = string.gsub(temp, '{(.+)}', '%1')
          temp = vim.fn.trim(temp) .. ','
          new_lines[#new_lines + 1] = '  ' .. temp
        else
          new_lines[#new_lines + 1] = line
        end
      else
        new_lines[#new_lines + 1] = line
      end
    end
    require 'plenary.path':new(fname):write(vim.fn.join(new_lines, '\r\n'), 'w')
    B.set_timeout(10, function()
      vim.cmd 'e!'
      require 'dp_lsp'.format()
    end)
  end

  vim.api.nvim_create_user_command('MapFromWhichkeyToLazy', function(params)
    M.map_from_whichkey_to_lazy(unpack(params['fargs']))
  end, { nargs = 0, })
  function M.map_from_whichkey_to_lazy(fname)
    if not fname then
      fname = string.gsub(vim.api.nvim_buf_get_name(0), '/', '\\')
    end
    if #fname == 0 then
      return
    end
    local new_lines = {}
    for _, line in ipairs(vim.fn.readfile(fname)) do
      local res = string.match(line, '^.+ *=.*{.*mode *=.+} *,')
      if res then
        local temp = string.format([[
          local sta, B = pcall(require, 'dp_base')
          if not sta then return nil end
          local M = {}
          M.lua = B.getlua(vim.api.nvim_buf_get_name(0))
          return {%s}
        ]], res)
        local item = loadstring(temp)
        if item then
          local val = item()
          for lhs, d in pairs(val) do
            if type(d[1]) == 'function' then
              d[1] = string.match(res, '(function().+end),')
            end
            table.insert(d, 1, lhs)
            d['desc'] = table.remove(d, 3)
            temp = string.gsub(vim.inspect(d), '%s+', ' ')
            temp = string.gsub(temp, '"(function().+end)",', '%1,')
            temp = string.gsub(temp, '\\"', '"')
            temp = vim.fn.trim(temp) .. ','
            new_lines[#new_lines + 1] = '  ' .. temp
          end
        else
          new_lines[#new_lines + 1] = line
        end
      else
        new_lines[#new_lines + 1] = line
      end
    end
    require 'plenary.path':new(fname):write(vim.fn.join(new_lines, '\r\n'), 'w')
    B.set_timeout(10, function()
      vim.cmd 'e!'
      require 'dp_lsp'.format()
    end)
  end
end

M.dp_plugins()
M.map()

return M
