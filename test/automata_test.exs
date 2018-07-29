defmodule AutomataTest do
  use ExUnit.Case
  doctest Automata

  test "Generic state change test" do
    machine = Automata.factory(%{
      init: "solid",
      transitions: [
        %{ name: "melt", from: "solid", to: "liquid" },
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "vaporize", from: "liquid", to: "gas" },
        %{ name: "condense", from: "gas", to: "liquid" }
      ]
    })

    assert machine == Automata.State
    assert machine.get_state() == "solid"

    assert machine.melt() == {:ok, "liquid"}
    assert machine.get_state() == "liquid"
    
    assert machine.freeze() == {:ok, "solid"}
    assert machine.get_state() == "solid"

    assert machine.melt() == {:ok, "liquid"}
    assert machine.get_state() == "liquid"
    
    assert machine.vaporize() == {:ok, "gas"}
    assert machine.get_state() == "gas"

    assert machine.condense() == {:ok, "liquid"}
    assert machine.get_state() == "liquid"
  end
end
