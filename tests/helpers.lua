local M = {}

function M.test(name, run)
  return { name = name, run = run }
end

function M.eq(expected, actual)
  if not vim.deep_equal(expected, actual) then
    error(
      string.format("expected:\n%s\nactual:\n%s", vim.inspect(expected), vim.inspect(actual)),
      2
    )
  end
end

function M.truthy(value)
  if not value then
    error("expected a truthy value, got " .. vim.inspect(value), 2)
  end
end

function M.matches(pattern, value)
  if type(value) ~= "string" or not value:match(pattern) then
    error(string.format("expected %s to match %q", vim.inspect(value), pattern), 2)
  end
end

function M.tmpdir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, "p")
  return vim.fs.normalize(path)
end

function M.write_file(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

function M.remove(path)
  vim.fn.delete(path, "rf")
end

return M
