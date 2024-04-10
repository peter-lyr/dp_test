local M = {}

-- local sta, B = pcall(require, 'dp_base')
--
-- if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

-- if B.check_plugins {
--       'git@github.com:peter-lyr/dp_init',
--     } then
--   return
-- end

vim.api.nvim_create_user_command('LazyUpdateDp', function()
  for _, dp in ipairs(vim.fn.getcompletion('Lazy update dp_', 'cmdline')) do
    vim.cmd('Lazy update ' .. dp)
  end
end, {
  nargs = 0,
  desc = 'LazyUpdateDp',
})

-- vim.api.nvim_create_user_command('GuiOn', function()
--   vim.cmd 'GuiAdaptiveColor 1'
--   vim.cmd 'GuiAdaptiveFont 1'
--   vim.cmd 'GuiAdaptiveStyle Fusion'
--   vim.cmd 'GuiTreeviewShow'
-- end, {
--   nargs = 0,
--   desc = 'GuiOn',
-- })
--
-- vim.api.nvim_create_user_command('GuiOff', function()
--   vim.cmd 'GuiAdaptiveColor 0'
--   vim.cmd 'GuiAdaptiveFont 0'
--   vim.cmd 'GuiTreeviewHide'
-- end, {
--   nargs = 0,
--   desc = 'GuiOff',
-- })

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

return M
