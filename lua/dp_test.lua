local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'git@github.com:peter-lyr/dp_init',
      'folke/which-key.nvim',
      'natecraddock/sessions.nvim',
      'git@github.com:peter-lyr/dp_lsp',
      'git@github.com:peter-lyr/dp_vimleavepre',
    } then
  return
end

M.source_fts = { 'lua', 'vim', }

M.show_info_en = 1

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

  function M.run_multi_do(cmd_list, check)
    local dp_plugins = B.get_dp_plugins()
    for _, dp in ipairs(dp_plugins) do
      local t = string.format('%s && %s', B.system_cd(dp), check)
      local result = vim.fn.trim(vim.fn.system(t))
      if #result > 0 then
        local temp = vim.fn.join(cmd_list, ' && ')
        B.system_run('start', string.format('%s & echo. & echo %s & %s', B.system_cd(dp), dp, temp))
      end
    end
  end

  function M.branch_status()
    M.run_one_do {
      'git branch -v',
      'git status -s',
    }
  end

  function M.add_commit_push_dot()
    local info = vim.fn.input('commit info: ', '.')
    if not B.is(info) then
      print('Canceled, commit info is Empty')
      return
    end
    M.run_multi_do({
      'git add .',
      string.format('git commit -m "%s"', info),
      'git push',
    }, 'git status -s')
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
  function M.start_nvim_qt(restart)
    if restart then
      require 'dp_vimleavepre'.leave()
    end
    local rtp = vim.fn.expand(string.match(vim.fn.execute 'set rtp', ',([^,]+)\\share\\nvim\\runtime'))
    vim.fn.writefile({
      'import os',
      'import time',
      'time.sleep(0.001)',
      'for _ in range(50*2):',
      string.format('  with open(r"%s", "rb") as f:', RestartReadyTxt),
      '    c = f.read().strip()',
      -- '    print(c)',
      '    if c == b"1":',
      '      break',
      '  time.sleep(0.02)',
      string.format('os.system(r"cd %s\\bin")', rtp),
      string.format('os.system(r"start /d %s nvim-qt.exe")', vim.loop.cwd()),
      -- 'os.system(r"pause")',
    }, RestartNvimQtPy)
    vim.cmd(string.format([[silent !start cmd /c "%s"]], RestartNvimQtPy))
    if restart then
      pcall(vim.fn.writefile, { 0, }, RestartReadyTxt)
      B.aucmd({ 'VimLeave', }, 'start_nvim_qt.VimLeave', {
        callback = function()
          pcall(vim.fn.writefile, { 1, }, RestartReadyTxt)
        end,
      })
    else
      pcall(vim.fn.writefile, { 1, }, RestartReadyTxt)
    end
  end

  function M.quit_nvim_qt()
    vim.cmd 'qa'
  end

  function M.restart_nvim_qt_sessionload()
    pcall(vim.fn.writefile, { 1, }, RestartFlagTxt)
    M.start_nvim_qt(1)
    M.quit_nvim_qt()
  end

  function M.restart_nvim_qt_opencurfile()
    pcall(vim.fn.writefile, { 2, vim.api.nvim_buf_get_name(0), }, RestartFlagTxt)
    M.start_nvim_qt(1)
    M.quit_nvim_qt()
  end

  function M.restart_nvim_qt_opennothing()
    pcall(vim.fn.writefile, {}, RestartFlagTxt)
    M.start_nvim_qt(1)
    M.quit_nvim_qt()
  end
end

function M.show()
  function M._get_human_fsize(fsize)
    local suffixes = { 'B', 'K', 'M', 'G', }
    local i = 1
    while fsize > 1024 and i < #suffixes do
      fsize = fsize / 1024
      i = i + 1
    end
    local format = i == 1 and '%d%s' or '%.1f%s'
    return string.format(format, fsize, suffixes[i])
  end

  function M._format(size, human)
    return string.format('%-10s %6s', string.format('%s', size), string.format('`%s`', human))
  end

  function M._filesize()
    local file = vim.fn.expand '%:p'
    if file == nil or #file == 0 then
      return ''
    end
    local size = vim.fn.getfsize(file)
    if size <= 0 then
      return ''
    end
    return M._format(size, M._get_human_fsize(size))
  end

  function M.get_git_added_file_total_fsize()
    local total_fsize = 0
    for fname in string.gmatch(vim.fn.system 'git ls-files', '([^\n]+)') do
      total_fsize = total_fsize + vim.fn.getfsize(fname)
    end
    return M._format(total_fsize, M._get_human_fsize(total_fsize))
  end

  function M.get_git_ignore_file_total_fsize()
    local total_fsize = 0
    for fname in string.gmatch(vim.fn.system 'git ls-files -o', '([^\n]+)') do
      total_fsize = total_fsize + vim.fn.getfsize(fname)
    end
    return M._format(total_fsize, M._get_human_fsize(total_fsize))
  end

  function M.show_info_allow()
    M.show_info_en = 1
  end

  function M._show_info_do(temp, start_index)
    if not start_index then
      start_index = 0
    end
    local items = {}
    -- local width = 0
    -- for _, v in ipairs(temp) do
    --   if width < #v[1] then
    --     width = #v[1]
    --   end
    -- end
    -- local str = '# %2d. [%-' .. width .. 's]: %s'
    local str = '# %2d. [%-s]: %s'
    for k, v in ipairs(temp) do
      local k2, v2 = unpack(v)
      v2 = vim.fn.trim(v2())
      table.insert(items, 1, string.format(str, k + start_index, k2, v2))
    end
    return items
  end

  function M._show_info_one_do(temp, start_index)
    if not start_index then
      start_index = 0
    end
    local start_time = vim.fn.reltime()
    local items = M._show_info_do(temp, start_index)
    local end_time = vim.fn.reltimefloat(vim.fn.reltime(start_time))
    local timing = string.format('timing: %.3f ms', end_time * 1000)
    if start_index == 0 then
      B.notify_info({ timing, vim.fn.join(items, '\n'), }, 1000 * 60 * 60 * 24)
    else
      B.notify_info_append({ timing, vim.fn.join(items, '\n'), }, 1000 * 60 * 60 * 24)
    end
    return #items
  end

  function M._show_info_one(temp)
    M.len = M.len + M._show_info_one_do(temp, M.len)
  end

  function M.show_info()
    if not M.show_info_en then
      B.echo 'please wait'
      return
    end
    M.show_info_en = nil
    B.set_timeout(1000, function()
      M.show_info_en = 1
    end)
    M.len = 0
    M._show_info_one {
      { '当前目录', function() return string.format('`%s`', vim.loop.cwd()) end, },
      { '日期时间', function() return vim.fn.strftime '%Y-%m-%d %H:%M:%S `%a`' end, },
      { '文件编码', function() return string.format('`%s`', vim.opt.fileencoding:get()) end, },
      { '文件格式', function() return string.format('%s', vim.bo.fileformat) end, },
      { '文件名称', function() return string.format('`%s`', vim.fn.bufname()) end, },
      { '占用内存', function() return string.format('%dM', vim.loop.resident_set_memory() / 1024 / 1024) end, },
      { '上电时长', function() return string.format('`%.3f` ms', EndTime * 1000) end, },
    }
    M._show_info_one {
      { '当前的文件所占的大小', M._filesize, },
      { '仓库已提交文件总大小', M.get_git_added_file_total_fsize, },
      { '仓库已忽略文件总大小', M.get_git_ignore_file_total_fsize, },
    }
    M._show_info_one {
      { '仓库当前分支的名称', vim.fn['gitbranch#name'], },
      { '仓库已提交的总次数', function() return '`' .. vim.fn.trim(vim.fn.system 'git rev-list --count HEAD') .. '` commits' end, },
      { '仓库已提交文件总数', function() return '`' .. vim.fn.trim(vim.fn.system 'git ls-files | wc -l') .. '` files added' end, },
      { '仓库已忽略文件总数', function() return '`' .. vim.fn.trim(vim.fn.system 'git ls-files -o | wc -l') .. '` files ignored' end, },
    }
  end
end

M.dp_plugins()
M.map_lazy_whichkey()
M.test1()
M.nvim_qt()
M.show()

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
  ['<leader>anrc'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
  ['<leader>anrn'] = { function() M.restart_nvim_qt_opennothing() end, 'nvim_qt.restart: opennothing', mode = { 'n', 'v', }, },
  ['<leader>ans'] = { function() M.restart_nvim_qt_sessionload() end, 'nvim_qt.restart: sessionsload', mode = { 'n', 'v', }, },
  ['<leader>anc'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
  ['<leader>ann'] = { function() M.restart_nvim_qt_opennothing() end, 'nvim_qt.restart: opennothing', mode = { 'n', 'v', }, },
  ['<leader>anj'] = { name = 'nvim_qt.just', mode = { 'n', 'v', }, },
  ['<leader>anjq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
  ['<leader>anjs'] = { function() M.start_nvim_qt() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
  ['<leader>anq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
  ['<leader>an<leader>'] = { function() M.start_nvim_qt() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>as'] = { name = 'show', },
  ['<leader>asi'] = { function() M.show_info() end, 'show: info', mode = { 'n', 'v', }, },
}

return M
