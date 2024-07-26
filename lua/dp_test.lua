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

M.source_fts         = { 'lua', 'vim', }

M.show_info_en       = 1

M.temp_mes_dir       = DepeiTemp .. '\\mes\\'

M.dp_lazy_py_name    = 'dp_lazy.py'

M.dp_lazy_py         = B.get_file(B.get_source_dot_dir(M.source), M.dp_lazy_py_name)

M.programs_files_txt = DataSub .. 'programs-files.txt'

M.edit_sel_fts       = { 'norg', 'py', 'c', }

M.temp_info_dir      = DepeiTemp .. '\\info\\'

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
        B.system_run('start silent', string.format('%s && %s', B.system_cd(dp), temp))
      end
    end
    table.insert(dp_plugins, 1, 'total ' .. tostring(#dp_plugins) .. ' dp_plugins')
    B.notify_info(dp_plugins)
  end

  function M.branch_status()
    M.run_one_do {
      'git branch -v',
      'git status -s',
    }
  end

  function M.add_commit_push_dot()
    local info = vim.fn.input('commit info: ', '.')
    info = B.cmd_escape(info)
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
      -- string.format([[print(r'cd "%s\\bin"')]], rtp),
      -- string.format([[os.system(r'cd "%s\\bin"')]], rtp),
      -- string.format('os.system(r"set TEMP=%s&& start /d %s nvim-qt.exe")', DepeiTemp, vim.loop.cwd()),
      string.format('os.system(r"""start /d "%s" nvim-qt.exe""")', vim.loop.cwd()),
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

  function M.start_nvim_qt_opencurfile()
    pcall(vim.fn.writefile, { 2, vim.api.nvim_buf_get_name(0), }, RestartFlagTxt)
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

  if nil then
    function M.show_info_startup()
      if StartTimeList then
        B.notify_info_append(B.merge_tables({ 'startup', }, StartTimeList), 1000 * 60 * 60 * 24)
      end
    end
  end

  function M.show_info_cmd(cmd, fname)
    local temp = vim.fn.trim(vim.fn.execute('!' .. cmd))
    temp = string.gsub(temp, '\r', '')
    local lines = vim.fn.split(temp, '\n')
    if #lines == 0 then
      return
    end
    local file = M.temp_info_dir
    if not fname then
      fname = 'cmd'
    end
    file = file .. string.format('info-%s.txt', fname)
    B.wingoto_file_or_open(file)
    lines = vim.tbl_filter(function(line)
      return #line > 0
    end, lines)
    local sep = { '', string.format('========= %s below =========', fname), '', }
    lines = B.merge_tables(sep, lines)
    vim.cmd 'norm Gzz'
    vim.fn.append(vim.fn.line '$', lines)
    vim.cmd 'norm jVGV'
  end

  function M.show_info_svn()
    M.show_info_cmd('svn info', 'svn info')
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

function M.programs()
  function M.get_target_path(lnk_file)
    local ext = string.match(lnk_file, '%.([^.]+)$')
    if not B.is(vim.tbl_contains({ 'url', 'lnk', }, ext)) then
      return lnk_file
    end
    vim.g.lnk_file = lnk_file
    vim.g.target_path = nil
    vim.cmd [[
    python << EOF
try:
  import pythoncom
except:
  import os
  os.system('pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com pywin32')
  import pythoncom
from win32com.client import Dispatch
lnk_file = vim.eval('g:lnk_file')
pythoncom.CoInitialize()
shell = Dispatch("WScript.Shell")
try:
  shortcut = shell.CreateShortCut(lnk_file)
  target_path = shortcut.TargetPath
  vim.command(f"""let g:target_path = '{target_path}'""")
except:
  pass
EOF
  ]]
    return vim.g.target_path
  end

  function M.get_programs_files_uniq()
    local programs_files = B.get_programs_files()
    local path_programs_files = B.get_path_files()
    local programs_files_uniq = B.merge_tables(vim.deepcopy(programs_files), vim.deepcopy(path_programs_files))
    local programs_files_uniq_temp = vim.deepcopy(programs_files_uniq)
    for _, programs_file in pairs(programs_files_uniq_temp) do
      programs_file = M.get_target_path(programs_file)
      if not B.is_in_tbl(programs_file, programs_files_uniq) then
        programs_files_uniq[#programs_files_uniq + 1] = programs_file
      end
    end
    B.write_table_to_file(M.programs_files_txt, programs_files_uniq)
    return programs_files_uniq
  end

  function M.sel_open_programs_file()
    local programs_files_uniq = B.read_table_from_file(M.programs_files_txt)
    if not B.is(programs_files_uniq) or #programs_files_uniq == 0 then
      M.sel_open_programs_file_force(1)
      return
    end
    B.ui_sel(programs_files_uniq, 'sel_open_programs_file', function(programs_file)
      if programs_file then
        B.system_open_file_silent(programs_file)
      end
    end)
  end

  function M.sel_open_programs_file_force(force)
    local programs_files_uniq = {}
    if force then
      programs_files_uniq = M.get_programs_files_uniq()
    else
      local temp = B.read_table_from_file(M.programs_files_txt)
      if temp then
        if B.is_sure('%s has %d items, Sure to re run scanning all? It maybe timing a lot', M.programs_files_txt, #temp) then
          programs_files_uniq = M.get_programs_files_uniq()
        else
          programs_files_uniq = temp
        end
      end
    end
    B.ui_sel(programs_files_uniq, 'sel_open_programs_file_force', function(programs_file)
      if programs_file then
        B.system_open_file_silent(programs_file)
      end
    end)
  end

  function M.sel_kill_from_program_files()
    local programs_files_uniq = B.read_table_from_file(M.programs_files_txt)
    if not B.is(programs_files_uniq) or #programs_files_uniq == 0 then
      M.sel_kill_from_program_files_force(1)
      return
    end
    local running_executables = B.get_running_executables()
    local exes = {}
    for _, file in ipairs(programs_files_uniq) do
      for _, temp in ipairs(running_executables) do
        if B.is_in_str(temp, vim.fn.tolower(file)) and not B.is_in_tbl(temp, exes) then
          exes[#exes + 1] = temp
          break
        end
      end
    end
    B.ui_sel(exes, 'sel_kill_from_program_files', function(exe)
      if exe then
        B.system_run('start silent', 'taskkill /f /im %s', exe)
      end
    end)
  end

  function M.sel_kill_from_all_program_files()
    local running_executables = B.get_running_executables()
    B.ui_sel(running_executables, 'sel_kill_from_all_program_files', function(exe)
      if exe then
        B.system_run('start silent', 'taskkill /f /im %s', exe)
      end
    end)
  end

  function M.sel_kill_from_program_files_force(force)
    local programs_files_uniq = {}
    if force then
      programs_files_uniq = M.get_programs_files_uniq()
    else
      local temp = B.read_table_from_file(M.programs_files_txt)
      if temp then
        if B.is_sure('%s has %d items, Sure to re run scanning all? It maybe timing a lot', M.programs_files_txt, #temp) then
          programs_files_uniq = M.get_programs_files_uniq()
        else
          programs_files_uniq = temp
        end
      end
    end
    local running_executables = B.get_running_executables()
    local exes = {}
    for _, file in ipairs(programs_files_uniq) do
      for _, temp in ipairs(running_executables) do
        if B.is_in_str(temp, vim.fn.tolower(file)) and not B.is_in_tbl(temp, exes) then
          exes[#exes + 1] = temp
          break
        end
      end
    end
    B.ui_sel(exes, 'sel_kill_from_program_files_force', function(exe)
      if exe then
        B.system_run('start silent', 'taskkill /f /im %s', exe)
      end
    end)
  end

  function M.sel_open_startup_file()
    local startup_files = B.get_startup_files()
    B.ui_sel(startup_files, 'sel_open_startup_file', function(startup_file)
      if startup_file then
        B.system_open_file_silent(startup_file)
      end
    end)
  end
end

function M.edit()
  function M.edit_a()
    local file = DepeiTemp .. '\\a'
    B.touch(file)
    B.jump_or_edit(file)
  end

  function M.edit_b()
    local file = DepeiTemp .. '\\b'
    B.touch(file)
    B.jump_or_split(file)
  end

  function M.edit_sel()
    B.ui_sel(M.edit_sel_fts, 'Open as', function(ft)
      B.mkdir(DepeiTemp .. '\\' .. ft)
      local file = DepeiTemp .. '\\' .. ft .. '\\c.' .. ft
      B.touch(file)
      B.jump_or_edit(file)
    end)
  end
end

M.dp_plugins()
M.map_lazy_whichkey()
M.test1()
M.nvim_qt()
M.show()
M.mes()
M.programs()
M.edit()

require 'which-key'.register {
  ['<leader>z'] = { name = 'test', },
}

require 'which-key'.register {
  ['<leader>zd'] = { name = 'test.more', },
  ['<leader>zdp'] = { name = 'test.more.dp_plugins', },
  ['<leader>zdpb'] = { function() M.branch_status() end, 'test.more.dp_plugins: branch_status', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zdpa'] = { function() M.add_commit_push_dot() end, 'test.more.dp_plugins: add_commit_push_dot', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zdpc'] = { function() M.checkout_main_pull() end, 'test.more.dp_plugins: checkout_main_pull', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zdpr'] = { function() M.dp_lazy_run() end, 'test.more.dp_plugins: dp_lazy_run', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>zdm'] = { name = 'test.more.map_lazy_whichkey', },
  ['<leader>zdmt'] = { name = 'test.more.map_lazy_whichkey.to', },
  ['<leader>zdmtw'] = { function() M.map_from_lazy_to_whichkey() end, 'test.more.map_lazy_whichkey: map_from_lazy_to_whichkey', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zdmtl'] = { function() M.map_from_whichkey_to_lazy() end, 'test.more.map_lazy_whichkey: map_from_whichkey_to_lazy', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>za'] = { function() M.source_file() end, 'test: source_file', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>zn'] = { name = 'nvim_qt', },
  ['<leader>zn<leader>s'] = { function() M.restart_nvim_qt_sessionload() end, 'nvim_qt.restart: sessionsload', mode = { 'n', 'v', }, },
  ['<leader>zn<leader>c'] = { function() M.restart_nvim_qt_opencurfile() end, 'nvim_qt.restart: opencurfile', mode = { 'n', 'v', }, },
  ['<leader>zn<leader>n'] = { function() M.restart_nvim_qt_opennothing() end, 'nvim_qt.restart: opennothing', mode = { 'n', 'v', }, },
  ['<leader>znn'] = { function() M.start_nvim_qt() end, 'nvim_qt.start: opennothing', mode = { 'n', 'v', }, },
  ['<leader>znc'] = { function() M.start_nvim_qt_opencurfile() end, 'nvim_qt.start: opencurfile', mode = { 'n', 'v', }, },
  ['<leader>zns'] = { function() M.start_nvim_qt_sessionload() end, 'nvim_qt.start: sessionsload', mode = { 'n', 'v', }, },
  ['<leader>znq'] = { function() M.quit_nvim_qt() end, 'nvim_qt.just: quit', mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>zm'] = { name = 'mes', },
  ['<leader>zmm'] = { '<cmd>mes<cr>', 'mes', mode = { 'n', 'v', }, },
  ['<leader>zmn'] = { '<cmd>Notifications<cr>', 'Notifications', mode = { 'n', 'v', }, },
  ['<leader>zmc'] = { '<cmd>mes clear<cr>', 'mes: clear', mode = { 'n', 'v', }, },
  ['<leader>zms'] = { name = 'mes.split', },
  ['<leader>zmsm'] = { function() M.mes_output_to_file() end, 'mes.split: mes_output_to_file', mode = { 'n', 'v', }, },
  ['<leader>zmsn'] = { function() M.notifications_output_to_file() end, 'mes.split: notifications_output_to_file', mode = { 'n', 'v', }, },
  ['<leader>zmsa'] = { function() M.mes_notifications_output_to_file() end, 'mes.split: mes_notifications_output_to_file', mode = { 'n', 'v', }, },
}

-- require 'which-key'.register {
--   ['<leader>zss'] = { function() M.show_info_startup() end, 'show: info', mode = { 'n', 'v', }, },
-- }

require 'which-key'.register {
  ['<leader>zs'] = { name = 'show', },
  ['<leader>zsi'] = { function() M.show_info() end, 'show: info', mode = { 'n', 'v', }, },
  ['<leader>zss'] = { function() M.show_info_svn() end, 'show: svn info', mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>zp'] = { name = 'programs', },
  ['<leader>zp<leader>'] = { name = 'programs.more', },
  ['<leader>zpO'] = { function() M.sel_open_programs_file_force() end, 'sel open programs file force', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zpo'] = { function() M.sel_open_programs_file() end, 'sel open programs file', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zpk'] = { function() M.sel_kill_from_program_files() end, 'sel kill programs file', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zp<leader>k'] = { function() M.sel_kill_from_all_program_files() end, 'sel kill programs file', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zpK'] = { function() M.sel_kill_from_program_files_force() end, 'sel kill programs file force', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zps'] = { function() M.sel_open_startup_file() end, 'sel open startup file', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>ze'] = { name = 'edit', },
  ['<leader>zea'] = { function() M.edit_a() end, 'edit a', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zeb'] = { function() M.edit_b() end, 'edit b', mode = { 'n', 'v', }, silent = true, },
  ['<leader>zes'] = { function() M.edit_sel() end, 'edit sel', mode = { 'n', 'v', }, silent = true, },
}

return M
