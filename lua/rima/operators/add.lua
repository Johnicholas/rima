-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local math, table = require("math"), require("table")
local error, require, unpack = error, require, unpack
local ipairs, pairs = ipairs, pairs

local proxy = require("rima.proxy")
require("rima.private")
local rima = rima

module(...)

local mul = require("rima.operators.mul")
local expression = require("rima.expression")

-- Addition --------------------------------------------------------------------

local add = rima.object:new(_M, "add")
add.precedence = 5


-- Argument Checking -----------------------------------------------------------

function add:check(args)
  for i, a in ipairs(args) do
    if not expression.result_type_match(a[2], rima.free()) then
      error(("argument %d (%s, '%s') to add expression '%s' is not in %s"):
        format(i, rima.tostring(a[2]), type(a[2]), self:_tostring(args), rima.tostring(rima.free())), 0)
    end
  end
end

function add:result_type(args)
  return rima.free()
end

-- String Representation -------------------------------------------------------

function add:dump(args)
  return "+("..
    table.concat(rima.imap(
      function(a) return rima.tostring(a[1]).."*"..expression.dump(a[2]) end, args), ", ")..
    ")"
end


function add:_tostring(args)
  local s = ""
  for i, a in ipairs(args) do
    local c, e = a[1], a[2]
    
    -- If it's the first argument and it's negative, put a "-" out front
    if i == 1 then
      if c < 0 then
        s = "-"
      end
    else
      s = s..((c < 0 and " - ") or " + ")
    end

    -- If the coefficient's not 1, make a sub-expression with a multiplication
    local ac = math.abs(c)
    e = ac == 1 and e or ac * e

    -- If the constant's not 1 then we need to parenthise (almost) like a multiplication
    s = s..expression.parenthise(e, (c == 1 and 5) or 4)
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function add:eval(S, raw_args)
  -- Sum all the arguments, keeping track of the sum of any constants,
  -- and of all remaining unresolved terms.
  -- If any subexpressions are sums, we dive into them, and if any are
  -- products, we try to hoist out the constant and see if what's left is a
  -- sum.

  -- evaluate all arguments
  local args = {} 
  for i, a in ipairs(raw_args) do
    args[i] = { a[1], expression.eval(a[2], S) }
  end

  local constant, terms = 0, {}
  
  local function add_term(c, e)
    local s = rima.tostring(e)
    local t = terms[s]
    if t then
      t.coeff = t.coeff + c
    else
      terms[s] = { coeff=c, expression=e }
    end
  end

  -- Run through all the terms in a sum
  local function sum(args, multiplier)
    multiplier = multiplier or 1
    for _, a in ipairs(args) do
      local c, e = multiplier * a[1], a[2]

      -- Simplify a single term
      local function simplify(c, e)
        e = proxy.O(e)
        if type(e) == "number" then             -- if the term evaluated to a number, then add it to the constant
          constant = constant + e * c
        elseif e.op == add then                 -- if the term is another sum, hoist its terms
          sum(e, c)
        elseif e.op == mul then                 -- if the term is a multiplication, try to hoist any constant
          local new_c, new_e = extract_constant(e)
          if new_c then                         -- if we did hoist a constant, re-simplify the resulting expression
            simplify(c * new_c, new_e)
          else                                  -- otherwise just add it
            add_term(c, e)
          end
        else                                    -- if there's nothing else to do, add the term
          add_term(c, e)
        end
      end
      simplify(c, e)

    end
  end
  sum(args)

  -- sort the terms alphabetically, so that when we group by a string representation,
  -- like terms look alike
  local ordered_terms = {}
  for name, t in pairs(terms) do
    if t.coeff ~= 0 then
      ordered_terms[#ordered_terms+1] = { name=name, coeff=t.coeff, expression=t.expression }
    end
  end
  table.sort(ordered_terms, function(a, b) return a.name < b.name end)

  if not ordered_terms[1] then                  -- if there's no terms, we're just a constant
    return constant
  elseif constant == 0 and                      -- if there's no constant, and one term without a coefficent,
         #ordered_terms == 1 and                -- we're the identity, so return the term
         ordered_terms[1].coeff == 1 then
    return ordered_terms[1].expression
  else                                          -- return the constant and the terms
    local new_args = {}
    if constant ~= 0 then new_args[1] = {1, constant} end
    for i, t in ipairs(ordered_terms) do
      new_args[#new_args+1] = { t.coeff, t.expression }
    end
    return expression:new_table(add, new_args)
  end
end


-- Extract the constant from an add or mul (if there is one)
function extract_constant(e)
  if type(e[1][2]) == "number" then
    local constant = e[1][2]
    local new_args = {}
    for i = 2, #e do
      new_args[i-1] = e[i]
    end
    if #new_args == 1 and new_args[1][1] == 1 then
      -- there's a constant and only one other argument with a coefficient/exponent of 1 - hoist the other argument
      return constant, new_args[1][2]
    else
      return constant, expression:new_table(e.op, new_args)
    end
  else                                          -- there's no constant to extract
    return nil
  end
end


-- EOF -------------------------------------------------------------------------

