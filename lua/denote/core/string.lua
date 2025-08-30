---@module "denote.core.string"
---@author Carlos Vigil-Vásquez
---@license MIT 2025

local M = {}

--- Normalizes diacritics (accented characters) in a string by replacing them with their base ASCII
--- equivalents. Handles common diacritics for vowels (a, e, i, o, u, y) and consonants (c, n, s, z),
--- as well as special characters like æ, œ, and ß. Both lowercase and uppercase variants are supported.
--- @param str string|nil The input string to normalize
--- @return string|nil normalized The normalized string
function M.normalize_diacritics(str)
  if not str then
    return str
  end
  local diacritic_map = {
    -- Vowels
    ["à"] = "a",
    ["á"] = "a",
    ["â"] = "a",
    ["ã"] = "a",
    ["ä"] = "a",
    ["å"] = "a",
    ["ā"] = "a",
    ["ă"] = "a",
    ["ą"] = "a",
    ["À"] = "A",
    ["Á"] = "A",
    ["Â"] = "A",
    ["Ã"] = "A",
    ["Ä"] = "A",
    ["Å"] = "A",
    ["Ā"] = "A",
    ["Ă"] = "A",
    ["Ą"] = "A",
    ["è"] = "e",
    ["é"] = "e",
    ["ê"] = "e",
    ["ë"] = "e",
    ["ē"] = "e",
    ["ĕ"] = "e",
    ["ė"] = "e",
    ["ę"] = "e",
    ["ě"] = "e",
    ["È"] = "E",
    ["É"] = "E",
    ["Ê"] = "E",
    ["Ë"] = "E",
    ["Ē"] = "E",
    ["Ĕ"] = "E",
    ["Ė"] = "E",
    ["Ę"] = "E",
    ["Ě"] = "E",
    ["ì"] = "i",
    ["í"] = "i",
    ["î"] = "i",
    ["ï"] = "i",
    ["ĩ"] = "i",
    ["ī"] = "i",
    ["ĭ"] = "i",
    ["į"] = "i",
    ["ı"] = "i",
    ["Ì"] = "I",
    ["Í"] = "I",
    ["Î"] = "I",
    ["Ï"] = "I",
    ["Ĩ"] = "I",
    ["Ī"] = "I",
    ["Ĭ"] = "I",
    ["Į"] = "I",
    ["İ"] = "I",
    ["ò"] = "o",
    ["ó"] = "o",
    ["ô"] = "o",
    ["õ"] = "o",
    ["ö"] = "o",
    ["ø"] = "o",
    ["ō"] = "o",
    ["ŏ"] = "o",
    ["ő"] = "o",
    ["Ò"] = "O",
    ["Ó"] = "O",
    ["Ô"] = "O",
    ["Õ"] = "O",
    ["Ö"] = "O",
    ["Ø"] = "O",
    ["Ō"] = "O",
    ["Ŏ"] = "O",
    ["Ő"] = "O",
    ["ù"] = "u",
    ["ú"] = "u",
    ["û"] = "u",
    ["ü"] = "u",
    ["ũ"] = "u",
    ["ū"] = "u",
    ["ŭ"] = "u",
    ["ů"] = "u",
    ["ű"] = "u",
    ["ų"] = "u",
    ["Ù"] = "U",
    ["Ú"] = "U",
    ["Û"] = "U",
    ["Ü"] = "U",
    ["Ũ"] = "U",
    ["Ū"] = "U",
    ["Ŭ"] = "U",
    ["Ů"] = "U",
    ["Ű"] = "U",
    ["Ų"] = "U",
    ["ý"] = "y",
    ["ÿ"] = "y",
    ["ỳ"] = "y",
    ["ỹ"] = "y",
    ["ȳ"] = "y",
    ["ŷ"] = "y",
    ["Ý"] = "Y",
    ["Ÿ"] = "Y",
    ["Ỳ"] = "Y",
    ["Ỹ"] = "Y",
    ["Ȳ"] = "Y",
    ["Ŷ"] = "Y",

    -- Consonants
    ["ç"] = "c",
    ["ć"] = "c",
    ["ĉ"] = "c",
    ["ċ"] = "c",
    ["č"] = "c",
    ["Ç"] = "C",
    ["Ć"] = "C",
    ["Ĉ"] = "C",
    ["Ċ"] = "C",
    ["Č"] = "C",
    ["ń"] = "n",
    ["ņ"] = "n",
    ["ň"] = "n",
    ["ŉ"] = "n",
    ["ŋ"] = "n",
    ["ñ"] = "n",
    ["Ń"] = "N",
    ["Ņ"] = "N",
    ["Ň"] = "N",
    ["Ŋ"] = "N",
    ["Ñ"] = "N",
    ["ś"] = "s",
    ["ŝ"] = "s",
    ["ş"] = "s",
    ["š"] = "s",
    ["Ś"] = "S",
    ["Ŝ"] = "S",
    ["Ş"] = "S",
    ["Š"] = "S",
    ["ž"] = "z",
    ["ź"] = "z",
    ["ż"] = "z",
    ["Ž"] = "Z",
    ["Ź"] = "Z",
    ["Ż"] = "Z",

    -- Special characters
    ["æ"] = "ae",
    ["œ"] = "oe",
    ["ß"] = "ss",
    ["Æ"] = "AE",
    ["Œ"] = "OE",
  }
  local normalized = str
  for diacritic, replacement in pairs(diacritic_map) do
    normalized = normalized:gsub(diacritic, replacement)
  end

  return normalized
end

---Trim whitespace on either end of string
---@param str string
function M.trim(str)
  local from = str:match("^%s*()")
  return from > #str and "" or str:match(".*%S", from)
end

---Make lowercase, remove special chars & diacritics, remove extraneous spaces
---@param str string
---@return string str Plain string
function M.sanitize(str)
  if str == nil then
    return ""
  end
  str = M.normalize_diacritics(str) --[[@as string]]
  str = str:gsub("[^%w%s]", "")
  str = str:lower()
  str = M.trim(str)
  str = str:gsub("%s+", " ")
  return str
end

return M
