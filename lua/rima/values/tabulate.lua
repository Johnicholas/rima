-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, ipairs = error, ipairs

local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Tabulation ------------------------------------------------------------------

local tabulate_type = object:new(_M, "tabulate")


function tabulate_type:new(indexes, e)
  local new_indexes = {}
  for i, v in ipairs(indexes) do
    if type(v) == "string" then
      new_indexes[i] = rima.R(v)
    elseif isa(v, rima.ref) then
      if rima.ref.is_simple(v) then
        new_indexes[i] = v
      else
        error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s)"):
          format(i, rima.repr(v), type(v)), 0)
      end
    else
      error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s)"):
        format(i, rima.repr(v), type(v)), 0)
    end
  end

  return object.new(self, { expression=e, indexes=new_indexes})
end


function tabulate_type:__repr(format)
  return ("tabulate({%s}, %s)"):format(expression.concat(self.indexes, format), rima.repr(self.expression, format))
end
__tostring = __repr


function tabulate_type:handle_address(S, a)
  if #a ~= #self.indexes then
    error(("the tabulation needs %d indexes, got %d"):format(#self.indexes, #a), 0)
  end
  S2 = scope.spawn(S, nil, {overwrite=true})

  for i, j in ipairs(self.indexes) do
    S2[rima.repr(j)] = expression.eval(a[i], S)
  end

  return expression.eval(self.expression, S2)
end


-- EOF -------------------------------------------------------------------------

