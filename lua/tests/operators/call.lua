-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local call = require("rima.operators.call")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(call:new(), call), "isa(call:new(), call)")
  T:check_equal(object.type(call:new()), "call", "type(call:new()) == 'call'")

  local S = scope.create{ a = rima.free(), b = rima.free(), x = rima.free() }

  T:check_equal(expression.dump(S.a(S.b)), "call(ref(a), ref(b))")
  T:check_equal(S.a(S.b), "a(b)")

  -- The a here ISN'T in the global scope, it's in the function scope
  S.f = rima.F({rima.R"a"}, 2 * rima.R"a")

  local c = rima.R"f"(3 + S.x)
  T:check_equal(c, "f(3 + x)")

  T:check_equal(expression.dump(c), "call(ref(f), +(1*number(3), 1*ref(x)))")
  T:check_equal(expression.eval(c, S), "2*(3 + x)")
  S.x = 5
  T:check_equal(expression.eval(c, S), 16)

  local c2 = expression:new(call, rima.R"f")
  T:expect_error(function() expression.eval(c2, S) end,
    "error while evaluating 'f%(%)':\n  the function needs to be called with at least")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

