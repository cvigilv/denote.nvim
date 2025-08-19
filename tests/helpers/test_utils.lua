-- Test utilities for denote.nvim tests
local M = {}

-- Mock logging to reduce noise during tests
function M.mock_logging()
  local log_mock = {}
  local function noop() end
  
  log_mock.trace = noop
  log_mock.debug = noop
  log_mock.info = noop
  log_mock.warn = noop
  log_mock.error = noop
  log_mock.fatal = noop
  
  package.loaded["denote.logging"] = log_mock
  return log_mock
end

-- Restore real logging
function M.restore_logging()
  package.loaded["denote.logging"] = nil
end

-- Setup test environment
function M.setup_test_env()
  M.mock_logging()
  
  -- Mock vim functions commonly used in tests
  if not vim.fn then
    vim.fn = {}
  end
  
  if not vim.fn.expand then
    vim.fn.expand = function(path)
      return path:gsub("^~/", "/tmp/test/")
    end
  end
  
  if not vim.fn.fnamemodify then
    vim.fn.fnamemodify = function(path, modifier)
      if modifier == ":t" then
        return path:match("([^/]+)$") or path
      elseif modifier == ":h" then
        return path:match("(.+)/[^/]*$") or "."
      end
      return path
    end
  end
  
  if not vim.tbl_deep_extend then
    vim.tbl_deep_extend = function(behavior, ...)
      local result = {}
      for _, tbl in ipairs({...}) do
        for k, v in pairs(tbl) do
          if type(v) == "table" and type(result[k]) == "table" then
            result[k] = vim.tbl_deep_extend(behavior, result[k], v)
          else
            result[k] = v
          end
        end
      end
      return result
    end
  end
end

-- Teardown test environment
function M.teardown_test_env()
  M.restore_logging()
end

return M