local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'git@github.com:peter-lyr/dp_lsp',
    } then
  return
end

M.tbl = {}
M.flag = nil
M.show_on_key = 1

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
  function M.test()
    --   240410-00h15m
    --   vim.g.temp_start = 0
    --   vim.on_key(function(c)
    --     vim.g.c = c
    --     vim.cmd [[
    --       python << EOF
    -- import vim
    -- import time
    -- with open(r'C:\w.txt', 'ab') as f:
    --   temp_end = time.time()
    --   temp_start = float(vim.eval('g:temp_start'))
    --   f.write(str(temp_end-temp_start).encode('utf-8') + b'\n')
    --   vim.command(f'let g:temp_start = {temp_end}')
    --   c = vim.eval('g:c')
    --   for i in c:
    --     f.write((hex(ord(i)) + '|').encode('utf-8'))
    --   f.write(b'\n')
    --   for i in c:
    --     t = ord(i)
    --     r = chr(t & 0xff)
    --     f.write(r.encode('utf-8'))
    --     t >>= 8
    --     while t > 0x100:
    --       f.write(r.encode('utf-8'))
    --       r = chr(t & 0xff) + r
    --       t >>= 8
    --     f.write(b'|')
    --   f.write(b'\n\n')
    -- EOF
    -- ]]
    --   end)
  end

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

function M.charstr()
  function M.getcharstr(charstr)
    if not charstr then
      charstr = vim.fn.getcharstr()
    end
    local temp = {}
    for i in string.gmatch(charstr, '.') do
      temp[#temp + 1] = string.byte(i, 1)
    end
    return temp
  end

  function M.getkeyhex()
    local charstr = vim.fn.getcharstr()
    print(charstr, M.getcharstr(charstr))
  end

  vim.api.nvim_create_user_command('GetKeyHex', function()
    M.getkeyhex()
  end, {
    nargs = 0,
    desc = 'GetKeyHex',
  })
end

function M.on_key()
  vim.on_key(function(c)
    if M.flag then
      return
    end
    local temp = {}
    for i in string.gmatch(c, '.') do
      temp[#temp + 1] = string.byte(i, 1)
    end
    if M.show_on_key then
      B.notify_info_append(c .. '|' .. vim.inspect(temp))
    end
    for _, val in pairs(M.tbl) do
      print(vim.inspect(temp), vim.inspect(val[1]))
      if B.is_tbl_equal(temp, val[1]) then
        M.flag = 1
        val[2]()
        B.set_timeout(100, function()
          M.flag = nil
        end)
        return
      end
    end
    if B.is_tbl_equal(temp, { 128, 253, 103, }) then
      M.tbl = {}
    end
  end)

  function M.register(tbl)
    M.tbl = vim.deepcopy(tbl)
  end

  function M.h()
    vim.cmd [[call feedkeys("\<c-h>")]]
  end

  function M.l()
    vim.cmd [[call feedkeys("\<c-l>")]]
  end

  function M.tt()
    M.register {
      ['l'] = { { 108, }, function() M.l() end, },
      ['h'] = { { 104, }, function() M.h() end, },
    }
  end

  B.lazy_map {
    { '<c-f12>',   function() M.show_on_key = 1 end,   mode = { 'n', 'v', }, silent = true, desc = 'test', },
    { '<c-s-f12>', function() M.show_on_key = nil end, mode = { 'n', 'v', }, silent = true, desc = 'test', },
    { '<c-f11>',   function() M.tt() end,              mode = { 'n', 'v', }, silent = true, desc = 'test', },
    { '<c-s-f11>', function() M.tbl = {} end,          mode = { 'n', 'v', }, silent = true, desc = 'test', },
  }
end

function M.on_map()
  vim.on_key(function(c)
    if #vim.tbl_keys(M.tbl) == 0 then
      return
    end
    local temp = {}
    for i in string.gmatch(c, '.') do
      temp[#temp + 1] = string.byte(i, 1)
    end
    if #temp > 1 then
      return
    end
    for hex, _ in pairs(M.tbl) do
      if B.is_tbl_equal(temp, hex) then
        return
      end
    end
    for _, val in pairs(M.tbl) do
      local mode = val['mode']
      local lhs = val[1]
      B.set_timeout(100, function()
        B.del_map(mode, lhs)
      end)
    end
    M.tbl = {}
  end)

  function M.register(tbl)
    M.tbl = vim.deepcopy(tbl)
    for _, map in pairs(tbl) do
      B.lazy_map { map, }
    end
  end

  function M.h()
    require 'dp_tabline'.b_prev_buf()
  end

  function M.l()
    require 'dp_tabline'.b_next_buf()
  end

  function M.tt()
    M.register {
      [{ 108, }] = { 'l', function() M.l() end, mode = { 'n', 'v', }, silent = true, desc = 'nvim.treesitter: go_to_context', },
      [{ 104, }] = { 'h', function() M.h() end, mode = { 'n', 'v', }, silent = true, desc = 'nvim.treesitter: go_to_context', },
    }
  end

  B.lazy_map {
    { '<c-f11>', function() M.tt() end, mode = { 'n', 'v', }, silent = true, desc = 'test', },
  }
end

M.dp_plugins()
M.map()
M.charstr()
-- M.on_key()
M.on_map()

return M
