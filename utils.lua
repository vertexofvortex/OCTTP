local utils = {}

function utils.tprint(tbl, indent)
  if not indent then indent = 0 end

  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "

    if type(v) == "table" then
      print(formatting)
      utils.tprint(v, indent + 2)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

function utils.spliturl(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

function utils.stripslash(url)
  if string.sub(url, 1, 1) == "/" then
    url = string.sub(url, 2, #url)
  end

  return url
end

function utils.matchurl(url, url_pattern)
  url = utils.spliturl(utils.stripslash(url), "/")
  url_pattern = utils.spliturl(utils.stripslash(url_pattern), "/")

  if #url ~= #url_pattern then
    return false
  end

  for i = 1, #url, 1 do
    if (string.sub(url_pattern[i], 1, 1) ~= "{"
          and string.sub(url_pattern[i], #url_pattern, #url_pattern) ~= "}")
    then
      if url[i] ~= url_pattern[i] then
        return false
      end
    end
  end

  return true
end

function utils.parseurlparams(url, url_pattern)
  url = utils.spliturl(utils.stripslash(url), "/")
  url_pattern = utils.spliturl(utils.stripslash(url_pattern), "/")

  local params = {}

  for i = 1, #url_pattern, 1 do
    if (string.sub(url_pattern[i], 1, 1) == "{"
          and string.sub(url_pattern[i], #url_pattern, #url_pattern) ~= "}")
    then
      params[string.sub(url_pattern[i], 2, #url_pattern[i] - 1)] = url[i]
    end
  end

  return params
end

return utils
