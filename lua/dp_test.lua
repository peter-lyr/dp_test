local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'folke/which-key.nvim',
      'git@github.com:peter-lyr/dp_lsp',
    } then
  return
end

M.source_fts = { 'lua', 'vim', }

-- M.restart_flag = B.read_table_from_file(RestartFlagTxt)
-- print("vim.inspect(M.restart_flag):", vim.inspect(M.restart_flag))

-- B.write_table_to_file(RestartFlagTxt, M.restart_flag)

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

  function M.branch_status()
    M.run_one_do {
      'git branch -v',
      'git status -s',
    }
  end

  function M.add_commit_push_dot()
    M.run_multi_do {
      'git add .',
      string.format('git commit -m "%s"', vim.fn.input('commit info: ', '.')),
      'git push',
    }
  end

  function M.checkout_main_pull()
    M.run_multi_do {
      'git checkout main',
      'git pull',
    }
  end
end

function M.map_lazy_whichkey()
  function M.map_from_lazy_to_whichkey()
    local fname = string.gsub(vim.api.nvim_buf_get_name(0), '/', '\\')
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

  function M.map_from_whichkey_to_lazy()
    local fname = string.gsub(vim.api.nvim_buf_get_name(0), '/', '\\')
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

function M.test1()
  function M.source_file(file)
    if not file then file = B.buf_get_name() end
    if not B.is_file_in_filetypes(file, M.source_fts) then
      B.echo('not a %s file', vim.fn.join(M.source_fts, ' or '))
      return
    end
    package.loaded[B.getlua(B.rep(file))] = nil
    B.print('source %s', file)
    B.cmd('source %s', file)
  end
end

function M.nvim_qt()
  function M.start_nvim_qt()
    pcall(vim.cmd, 'SessionsSave')
    pcall(vim.cmd, 'wshada!')
    local rtp = vim.fn.expand(string.match(vim.fn.execute 'set rtp', ',([^,]+)\\share\\nvim\\runtime'))
    vim.fn.writefile({
      string.format('cd %s\\bin', rtp),
      string.format('start /d %s nvim-qt.exe', vim.loop.cwd()),
    }, RestartNvimQtBat)
    vim.cmd(string.format([[silent !start cmd /c "%s"]], RestartNvimQtBat))
  end

  function M.quit_nvim_qt()
    vim.cmd 'qa'
  end

  function M.restart_nvim_qt_sessionload()
    pcall(vim.fn.writefile, { 1, }, RestartFlagTxt)
    M.start_nvim_qt()
    M.quit_nvim_qt()
  end

  function M.restart_nvim_qt_opencurfile()
    pcall(vim.fn.writefile, { 2, vim.api.nvim_buf_get_name(0), }, RestartFlagTxt)
    M.start_nvim_qt()
    M.quit_nvim_qt()
  end
end

M.dp_plugins()
M.map_lazy_whichkey()
M.test1()
M.nvim_qt()

require 'which-key'.register {
  ['<leader>a'] = { name = 'test', },
}

require 'which-key'.register {
  ['<leader>ad'] = { name = 'test.more', },
  ['<leader>adp'] = { name = 'test.more.dp_plugins', },
  ['<leader>adpb'] = { function() M.branch_status() end, 'test.more.dp_plugins: branch_status', mode = { 'n', 'v', }, silent = true, },
  ['<leader>adpa'] = { function() M.add_commit_push_dot() end, 'test.more.dp_plugins: add_commit_push_dot', mode = { 'n', 'v', }, silent = true, },
  ['<leader>adpc'] = { function() M.checkout_main_pull() end, 'test.more.dp_plugins: checkout_main_pull', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>adm'] = { name = 'test.more.map_lazy_whichkey', },
  ['<leader>admt'] = { name = 'test.more.map_lazy_whichkey.to', },
  ['<leader>admtw'] = { function() M.map_from_lazy_to_whichkey() end, 'test.more.map_lazy_whichkey: map_from_lazy_to_whichkey', mode = { 'n', 'v', }, silent = true, },
  ['<leader>admtl'] = { function() M.map_from_whichkey_to_lazy() end, 'test.more.map_lazy_whichkey: map_from_whichkey_to_lazy', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>aa'] = { function() M.source_file() end, 'test: source_file', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>an'] = { name = 'nvim_qt', },
  ['<leader>anr'] = { name = 'nvim_qt.restart', mode = { 'n', 'v', }, },
  ['<leader>anrs'] = { function() M.restart_nvim_qt_sessionload() end, 'nvim_qt.restart: sessionsload', mode = { 'n', 'v', }, },
  ['<leader>anro'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
  ['<leader>anj'] = { name = 'nvim_qt.just', mode = { 'n', 'v', }, },
  ['<leader>anjq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
  ['<leader>anjs'] = { function() M.start_nvim_qt() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
}

return M
