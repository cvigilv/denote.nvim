local root = vim.g.denote_test_root
local specs = vim.fn.globpath(root .. "/tests", "*_spec.lua", false, true)
table.sort(specs)

local passed = 0
local failed = 0

for _, spec in ipairs(specs) do
  local loaded, cases = pcall(dofile, spec)
  if not loaded then
    failed = failed + 1
    print(string.format("FAIL %s\n%s", vim.fs.basename(spec), cases))
  else
    for _, case in ipairs(cases) do
      local ok, err = xpcall(case.run, debug.traceback)
      if ok then
        passed = passed + 1
        print("PASS " .. case.name)
      else
        failed = failed + 1
        print(string.format("FAIL %s\n%s", case.name, err))
      end
    end
  end
end

print(string.format("\n%d passed, %d failed", passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
