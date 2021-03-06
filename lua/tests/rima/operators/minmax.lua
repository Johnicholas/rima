-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local minmax = require("rima.operators.minmax")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R
  local U = interface.unwrap

  -- min
  T:test(object.typeinfo(U(interface.min(1, {1, 1}))).min, "typeinfo(min).min")
  T:check_equal(object.typename(U(interface.min(1, {1, 1}))), "min", "typename(min) == 'min'")
  
  do
    local a, b, c, d = R"a, b, c, d"
    local C = interface.min(a, b, c, d)

    T:check_equal(C, "min(a, b, c, d)")
    T:check_equal(E(C, {a = 1}), "min(b, c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2}), "min(c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2, c = 3, d = 4}), 1)
  end

  -- max
  T:test(object.typeinfo(U(interface.max(1, {1, 1}))).max, "typeinfo(max).max")
  T:check_equal(object.typename(U(interface.max(1, {1, 1}))), "max", "typename(max) == 'max'")
  
  do
    local a, b, c, d = R"a, b, c, d"
    local C = interface.max(a, b, c, d)

    T:check_equal(C, "max(a, b, c, d)")
    T:check_equal(E(C, {a = 1}), "max(b, c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2}), "max(c, d, 2)")
    T:check_equal(E(C, {a = 1, b = 2, c = 3, d = 4}), 4)
  end
end


------------------------------------------------------------------------------

