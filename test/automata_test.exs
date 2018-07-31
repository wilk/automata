defmodule AutomataTest do
  # run test in parallel
  use ExUnit.Case, async: true
  doctest Automata

  setup do
    Automata.start_link(nil)
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

  test "It should change state from solid to gas on a different machine" do
    machine = Automata.factory(%{
      init: "liquid",
      transitions: [
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "sublimate", from: "solid", to: "gas" }
      ]
    })

    machine.freeze()
    assert machine.get_state() == "solid"
    machine.sublimate()
    assert machine.get_state() == "gas"
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
  
  test "It should not change state from solid to gas", state do
    machine = state[:machine]
    assert machine.vaporize() == {:error, "Cannot change state from solid to gas"}
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

  test "It should store the machine state with a given name", state do
    machine = Automata.factory(%{
      init: "liquid",
      transitions: [
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "sublimate", from: "solid", to: "gas" }
      ]
    }, :my_machine)

    my_machine = Automata.fetch(:my_machine)

    assert machine == my_machine
  end
end
