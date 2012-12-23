-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local closure = require("rima.closure")
local add = require("rima.operators.add")
local expression = require("rima.expression")
local set_list = require("rima.sets.list")


------------------------------------------------------------------------------

local sum = expression:new_type({}, "sum")
sum.precedence = 1


function sum:simplify()
  local terms = proxy.O(self)
  local ti = object.typeinfo(terms[1])
  if ti.closure then
    return self
  elseif ti["sets.list"] then
    return expression:new_table(sum, { closure:new(terms[2], terms[1]) })
  else
    local term_count = #terms
    local sets = set_list:read(terms, term_count-1)
    return expression:new_table(sum, { closure:new(terms[term_count], sets) })
  end
end


------------------------------------------------------------------------------

local formats =
{
  dump = "sum(%s)",
  lua = "rima.sum%s",
  latex = "\\sum_%s",
  other = "sum%s"
}

function sum:__repr(format)
  local f = formats[format.format] or formats.other
  local terms = proxy.O(self)
  return f:format(lib.repr(terms[1], format))
end


------------------------------------------------------------------------------

function sum:__eval(S)
  local terms = proxy.O(self)
  local cl = terms[1]

  -- Iterate through all the elements of the sets, collecting defined and
  -- undefined terms
  local defined_terms, undefined_terms = {}, {}
  for S2, undefined in cl:iterate(S) do
    local z = core.eval(cl.exp+0, S2)  -- the +0 helps to "cast" e to a number (if it's a set element)
    if undefined and undefined[1] then
      -- Undefined terms are stored in groups based on the undefined sum
      -- indices (so we can group them back into sums over the same indices)
      local name = lib.concat(undefined, ",", lib.repr)
      local terms
      local udn = undefined_terms[name]
      if not udn then
        terms = {}
        undefined_terms[name] = { iterators=undefined, terms=terms }
      else
        terms = udn.terms
      end
      terms[#terms+1] = { 1, z }
    else
      -- Defined terms are just stored in a list
      defined_terms[#defined_terms+1] = { 1, z }
    end
  end

  -- Run through all the undefined terms, rebuilding the sums
  local total_terms = {}
  for n, t in pairs(undefined_terms) do
    local z
    if #t.terms > 1 then
      z = expression:new_table(add, t.terms)
    else
      z = t.terms[1][2]
    end
    total_terms[#total_terms+1] = {1, expression:new(sum, t.iterators, cl:undo(z, t.iterators)) }
  end

  -- Add the defined terms onto the end
  for _, t in ipairs(defined_terms) do
    total_terms[#total_terms+1] = t
  end

  if #total_terms == 1 then
    return total_terms[1][2]
  else
    return core.eval(expression:new_table(add, total_terms), S)
  end
end


------------------------------------------------------------------------------

function sum:__list_variables(S, list)
  local cl = proxy.O(self)[1]
  for S2, undefined in cl:iterate(S) do
    local S3 = cl:fake_iterate(S2, undefined)
    core.list_variables(core.eval(cl, S3), S3, list)
  end
end


------------------------------------------------------------------------------

function sum.build(x)
  local term_count, terms = 1, { x }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      return next_term
    else
      return expression:new_table(sum, terms)
    end
  end
  return next_term
end


------------------------------------------------------------------------------

return sum

------------------------------------------------------------------------------

