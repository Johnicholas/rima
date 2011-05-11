-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs, getmetatable, pairs, select, tostring, type, unpack =
      ipairs, getmetatable, pairs, select, tostring, type, unpack
local table = require("table")

local object = require("rima.lib.object")

local typename = object.typename

module(...)


--------------------------------------------------------------------------------

function append(t, ...)
  local l = #t+1
  for i = 1, select("#", ...) do
    t[l] = select(i, ...)
    l = l + 1
  end
end


function imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


function concat(t, s, f)
  if f then
    return table.concat(imap(f, t), s)
  else
    return table.concat(t, s)
  end
end


function packn(...)
  return { n=select("#", ...), ... }
end


function packs(status, ...)
  return status, { n=select("#", ...), ... }
end


function unpackn(t)
  return unpack(t, 1, t.n)
end


function getmetamethod(obj, methodname)
  local mt = getmetatable(obj)
  return mt and mt[methodname]
end


-- String representation -------------------------------------------------------

local number_format = "%.4g"
function set_number_format(f)
  number_format = f
end


function is_identifier(v)
  return v:match("^[_%a][_%w]*$")
end


function is_identifier_string(v)
  return type(v) == "string" and is_identifier(v)
end


function simple_repr(o, format)
  local t = typename(o)
  if t == "number" then
    local nf = format.numbers or number_format
    return nf:format(o)
  elseif format.format == "dump" then
    if t == "string" then
      return ("%q"):format(o)
    elseif t == "boolean" then
      return tostring(o)
    elseif t == "table" then
      local s = "table"..": { "
      local count = 0
      for k, v in pairs(o) do
        if count == 3 then s = s..",..." break end
        if count > 0 then s = s..", " end
        s = s..tostring(k).."="..tostring(v)
        count = count + 1
      end
      s = s.." }"
      return s
    elseif t == "nil" then
      return "nil"
    else
      return t.."("..tostring(o)..")"
    end
  elseif format.format == "latex" then
    if t == "table" then
      return "\\text{table}"
    elseif t == "boolean" then
      return "\\text{"..tostring(o).."}"
    elseif t == "nil" then
      return "\\text{nil}"
    elseif t == "string" then
      if o:len() == 1 then
        return o
      elseif is_identifier(o) then
        return "\\text{"..o:gsub("_", "\\_").."}"
      else
        return "\\text{``"..o:gsub("_", "\\_").."''}"
      end
    else
      return tostring(o)
    end
  else
    if t == "table" then
      return "table"
    else
      return tostring(o)
    end
  end
end


local no_format = {}

function repr(o, format)
  format = format or no_format

  local f = getmetamethod(o, "__repr")
  if f then
    return f(o, format)
  else
    return simple_repr(o, format)
  end
end


function __tostring(o)
  return getmetatable(o).__repr(o, no_format)
end


function concat_repr(t, format)
  return concat(t, ", ", function(i) return repr(i, format) end)
end


local dump_format = { format="dump" }
function dump(e)
  return repr(e, dump_format)
end


-- EOF -------------------------------------------------------------------------

