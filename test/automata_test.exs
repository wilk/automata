defmodule AutomataTest do
  use ExUnit.Case
  doctest Automata

  setup do
    machine = Automata.factory(%{
      init: "solid",
      transitions: [
        %{ name: "melt", from: "solid", to: "liquid" },
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "vaporize", from: "liquid", to: "gas" },
        %{ name: "condense", from: "gas", to: "liquid" }
      ]
    })

    {:ok, machine: machine}
  end

  test "It should be an Automata.State module", state do
    machine = state[:machine]
    assert machine == Automata.State
  end

  test "It should start with a solid state", state do
    machine = state[:machine]
    assert machine.get_state() == "solid"
  end
  
  test "It should change state from solid to liquid", state do
    machine = state[:machine]
    assert machine.melt() == {:ok, "liquid"}
    assert machine.get_state() == "liquid"
  end

  test "It should change state from liquid back to solid", state do
    machine = state[:machine]
    machine.melt()
    assert machine.freeze() == {:ok, "solid"}
    assert machine.get_state() == "solid"
  end

  test "It should change state from liquid to gas", state do
    machine = state[:machine]
    machine.melt()
    assert machine.vaporize() == {:ok, "gas"}
    assert machine.get_state() == "gas"
  end

  test "It should change state from gas to liquid", state do
    machine = state[:machine]
    machine.melt()
    machine.vaporize()
    assert machine.condense() == {:ok, "liquid"}
    assert machine.get_state() == "liquid"
  end
end
