local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

M.source = B.getsource(debug.getinfo(1)['source'])

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

M.temp_mes_dir = DepeiTemp .. '\\mes\\'

M.dp_lazy_py_name = 'dp_lazy.py'

M.dp_lazy_py = B.get_file(B.get_source_dot_dir(M.source), M.dp_lazy_py_name)

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
      print 'Canceled, commit info is Empty'
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
      'git checkout -- .',
      'git checkout main',
      'git pull',
    }
  end

  function M.dp_lazy_run()
    B.system_run_histadd(
      'start',
      'copy /y %s %s && python %s',
      M.dp_lazy_py, DataLazyPlugins, DataLazyPlugins .. '\\' .. M.dp_lazy_py_name
    )
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
    B.echo('source %s', file)
    B.cmd('source %s', file)
  end
end

function M.nvim_qt()
  function M.start_nvim_qt(flag)
    if flag == 'restart' then
      require 'dp_vimleavepre'.leave()
    elseif flag == 'start' then
      require 'dp_vimleavepre'.save()
    end
    local rtp = vim.fn.expand(string.match(vim.fn.execute 'set rtp', ',([^,]+)\\share\\nvim\\runtime'))
    if not B.is(rtp) then
      print 'rtp is nil, returned'
      return
    end
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
      string.format('print(r"cd %s\\bin")', rtp),
      string.format('os.system(r"cd %s\\bin")', rtp),
      -- string.format('print(r"start /d %s nvim-qt.exe")', vim.loop.cwd()),
      string.format('os.system(r"start /d %s nvim-qt.exe")', vim.loop.cwd()),
      -- 'os.system(r"pause")',
    }, RestartNvimQtPy)
    vim.cmd(string.format([[silent !start cmd /c "%s"]], RestartNvimQtPy))
    if flag == 'restart' then
      pcall(vim.fn.writefile, { 0, }, RestartReadyTxt)
      B.aucmd({ 'VimLeave', }, 'start_nvim_qt.VimLeave', {
        callback = function()
          pcall(vim.fn.writefile, { 1, }, RestartReadyTxt)
        end,
      })
    else
      pcall(vim.fn.writefile, { 1, }, RestartReadyTxt)
    end
    return 1
  end

  function M.quit_nvim_qt()
    vim.cmd 'qa!'
  end

  function M.restart_nvim_qt_sessionload()
    pcall(vim.fn.writefile, { 1, }, RestartFlagTxt)
    local temp = M.start_nvim_qt 'restart'
    if temp then
      M.quit_nvim_qt()
    end
  end

  function M.restart_nvim_qt_opencurfile()
    pcall(vim.fn.writefile, { 2, vim.api.nvim_buf_get_name(0), }, RestartFlagTxt)
    local temp = M.start_nvim_qt 'restart'
    if temp then
      M.quit_nvim_qt()
    end
  end

  function M.restart_nvim_qt_opennothing()
    pcall(vim.fn.writefile, {}, RestartFlagTxt)
    local temp = M.start_nvim_qt 'restart'
    if temp then
      M.quit_nvim_qt()
    end
  end

  function M.start_nvim_qt_sessionload()
    pcall(vim.fn.writefile, { 1, }, RestartFlagTxt)
    M.start_nvim_qt 'start'
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

  function M.show_info_startup()
    if StartTimeList then
      B.notify_info_append(B.merge_tables({ 'startup', }, StartTimeList), 1000 * 60 * 60 * 24)
    end
  end
end

function M.mes()
  if vim.fn.isdirectory(M.temp_mes_dir) == 0 then
    vim.fn.mkdir(M.temp_mes_dir)
  end
  function M.mes_output_to_file()
    local lines = vim.fn.split(vim.fn.trim(vim.fn.execute 'mes'), '\n')
    if #lines == 0 then
      return
    end
    local file = M.temp_mes_dir .. vim.fn.strftime 'mes-%Y%m%d%H%M%S.txt'
    B.wingoto_file_or_open(file)
    lines = vim.tbl_filter(function(line)
      return #line > 0
    end, lines)
    local sep = { '========= mes below =========', '', }
    lines = B.merge_tables(sep, lines)
    vim.fn.append(vim.fn.line '$', lines)
  end

  function M.notifications_output_to_file()
    local lines = vim.fn.split(vim.fn.trim(vim.fn.execute 'Notifications'), '\n')
    if #lines == 0 then
      return
    end
    local file = M.temp_mes_dir .. vim.fn.strftime 'notifications-%Y%m%d%H%M%S.txt'
    B.wingoto_file_or_open(file)
    local sep = { '========= Notifications below =========', '', }
    lines = B.merge_tables(sep, lines)
    vim.fn.append(vim.fn.line '$', lines)
  end

  function M.mes_notifications_output_to_file()
    local lines = vim.fn.split(vim.fn.trim(vim.fn.execute 'mes'), '\n')
    local lines_2 = vim.fn.split(vim.fn.trim(vim.fn.execute 'Notifications'), '\n')
    if #lines == 0 and #lines_2 == 0 then
      return
    end
    local file = M.temp_mes_dir .. vim.fn.strftime 'mes-notifications-%Y%m%d%H%M%S.txt'
    B.wingoto_file_or_open(file)
    lines = vim.tbl_filter(function(line)
      return #line > 0
    end, lines)
    local sep = { '========= mes below =========', '', }
    local sep_2 = { '', '========= Notifications below =========', '', }
    lines = B.merge_tables(sep, lines, sep_2, lines_2)
    vim.fn.append(vim.fn.line '$', lines)
  end
end

M.dp_plugins()
M.map_lazy_whichkey()
M.test1()
M.nvim_qt()
M.show()
M.mes()

function M._map()
  require 'which-key'.register {
    ['<leader>ts'] = { name = 'test', },
  }

  require 'which-key'.register {
    ['<leader>tsd'] = { name = 'test.more', },
    ['<leader>tsdp'] = { name = 'test.more.dp_plugins', },
    ['<leader>tsdpb'] = { function() M.branch_status() end, 'test.more.dp_plugins: branch_status', mode = { 'n', 'v', }, silent = true, },
    ['<leader>tsdpa'] = { function() M.add_commit_push_dot() end, 'test.more.dp_plugins: add_commit_push_dot', mode = { 'n', 'v', }, silent = true, },
    ['<leader>tsdpc'] = { function() M.checkout_main_pull() end, 'test.more.dp_plugins: checkout_main_pull', mode = { 'n', 'v', }, silent = true, },
    ['<leader>tsdpr'] = { function() M.dp_lazy_run() end, 'test.more.dp_plugins: dp_lazy_run', mode = { 'n', 'v', }, silent = true, },
  }

  require 'which-key'.register {
    ['<leader>tsdm'] = { name = 'test.more.map_lazy_whichkey', },
    ['<leader>tsdmt'] = { name = 'test.more.map_lazy_whichkey.to', },
    ['<leader>tsdmtw'] = { function() M.map_from_lazy_to_whichkey() end, 'test.more.map_lazy_whichkey: map_from_lazy_to_whichkey', mode = { 'n', 'v', }, silent = true, },
    ['<leader>tsdmtl'] = { function() M.map_from_whichkey_to_lazy() end, 'test.more.map_lazy_whichkey: map_from_whichkey_to_lazy', mode = { 'n', 'v', }, silent = true, },
  }

  require 'which-key'.register {
    ['<leader>tsa'] = { function() M.source_file() end, 'test: source_file', mode = { 'n', 'v', }, silent = true, },
  }

  require 'which-key'.register {
    ['<leader>tsn'] = { name = 'nvim_qt', },
    ['<leader>tsnr'] = { name = 'nvim_qt.restart', mode = { 'n', 'v', }, },
    ['<leader>tsnrs'] = { function() M.restart_nvim_qt_sessionload() end, 'nvim_qt.restart: sessionsload', mode = { 'n', 'v', }, },
    ['<leader>tsnrc'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
    ['<leader>tsnrn'] = { function() M.restart_nvim_qt_opennothing() end, 'nvim_qt.restart: opennothing', mode = { 'n', 'v', }, },
    ['<leader>tsns'] = { function() M.restart_nvim_qt_sessionload() end, 'nvim_qt.restart: sessionsload', mode = { 'n', 'v', }, },
    ['<leader>tsnc'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
    ['<leader>tsnn'] = { function() M.restart_nvim_qt_opennothing() end, 'nvim_qt.restart: opennothing', mode = { 'n', 'v', }, },
    ['<leader>tsnj'] = { name = 'nvim_qt.just', mode = { 'n', 'v', }, },
    ['<leader>tsnjq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
    ['<leader>tsnjs'] = { function() M.start_nvim_qt() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
    ['<leader>tsnq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
    ['<leader>tsn<leader>'] = { function() M.start_nvim_qt() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
    ['<leader>tsno'] = { function() M.start_nvim_qt_sessionload() end, 'nvim_qt.just: start', mode = { 'n', 'v', }, },
  }

  require 'which-key'.register {
    ['<leader>tsm'] = { name = 'mes', },
    ['<leader>tsmm'] = { '<cmd>mes<cr>', 'mes', mode = { 'n', 'v', }, },
    ['<leader>tsmn'] = { '<cmd>Notifications<cr>', 'Notifications', mode = { 'n', 'v', }, },
    ['<leader>tsmc'] = { '<cmd>mes clear<cr>', 'mes: clear', mode = { 'n', 'v', }, },
    ['<leader>tsms'] = { name = 'mes.split', },
    ['<leader>tsmsm'] = { function() M.mes_output_to_file() end, 'mes.split: mes_output_to_file', mode = { 'n', 'v', }, },
    ['<leader>tsmsn'] = { function() M.notifications_output_to_file() end, 'mes.split: notifications_output_to_file', mode = { 'n', 'v', }, },
    ['<leader>tsmsa'] = { function() M.mes_notifications_output_to_file() end, 'mes.split: mes_notifications_output_to_file', mode = { 'n', 'v', }, },
  }

  require 'which-key'.register {
    ['<leader>tss'] = { name = 'show', },
    ['<leader>tssi'] = { function() M.show_info() end, 'show: info', mode = { 'n', 'v', }, },
    ['<leader>tsss'] = { function() M.show_info_startup() end, 'show: info', mode = { 'n', 'v', }, },
  }
end

return M
