# 放到'~\AppData\Local\nvim-data\lazy\plugins\'目录下
import os

# import re


cnt = 0
root = os.path.dirname(os.path.abspath(__file__))
print(root)

for dir in os.listdir(root):
    if dir[:3] != "dp_":
        continue
    D = os.path.join(root, dir)
    if os.path.isfile(D):
        continue
    lua = os.path.join(D, "lua")
    try:
        os.makedirs(lua)
    except:
        pass
    lua_file = os.path.join(lua, dir + ".lua")
    if not os.path.exists(lua_file):
        with open(lua_file, "wb") as f:
            f.write(b"")

    # with open(lua_file, "rb") as f:
    #     content = f.read()
    # if re.findall(rb"function M\._map\(\)", content):
    #     continue

    cnt += 1
    print(f'{cnt:3}. {dir}')

    plugin = os.path.join(D, "plugin")
    try:
        os.makedirs(plugin)
    except:
        pass
    with open(os.path.join(plugin, "." + dir + ".lua"), "w") as f:
        f.write(
            f"""
local starttime = vim.fn.reltime()
require '{dir}'
local t1 = vim.fn.reltimefloat(vim.fn.reltime(starttime))
local t2 = vim.fn.reltimefloat(vim.fn.reltime(StartTime))
if not StartTimeList then
  StartTimeList = {{}}
end
StartTimeList[#StartTimeList+1] = string.format("`%.3f` `%.3f` [%s]", t2, t1, vim.fn.fnamemodify(debug.getinfo(1)['source'], ':t:r'))
""".strip()
        )

os.system("pause")
