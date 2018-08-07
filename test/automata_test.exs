defmodule AutomataTest do
  # run test in parallel
  use ExUnit.Case, async: true
  doctest Automata

  setup do
    Automata.start_link(nil)
    {:ok, machine} = Automata.factory(%{
      init_state: "solid",
      transitions: [
        %{ name: "melt", from: "solid", to: "liquid" },
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "vaporize", from: "liquid", to: "gas" },
        %{ name: "condense", from: "gas", to: "liquid" }
      ]
    })

    {:ok, machine: machine}
  end

  test "It should not create a machine state without an initial state" do
    result = Automata.factory(%{
      transitions: [
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "sublimate", from: "solid", to: "gas" }
      ]
    })

    assert result == {:error, "init_state field is required and must be a string"}
  end

  test "It should not create a machine state without transitions" do
    result = Automata.factory(%{
      init_state: "solid"
    })

    assert result == {:error, "transitions field is required and must be a filled list"}
  end

  test "It should create a state machine with an initial dataset" do
    my_data = %{something: ["foo", "bar", 10]}
    {:ok, machine} = Automata.factory(%{
      init_state: "liquid",
      init_data: my_data,
      transitions: [
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "sublimate", from: "solid", to: "gas" }
      ]
    })

    # todo: this does not work. it collides with another state machine in memory... damn
    assert machine.get_data() == my_data
  end

  test "It should change state from solid to gas on a different machine" do
    {:ok, machine} = Automata.factory(%{
      init_state: "liquid",
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
    {:ok, machine} = Automata.factory(%{
      init_state: "liquid",
      transitions: [
        %{ name: "freeze", from: "liquid", to: "solid" },
        %{ name: "sublimate", from: "solid", to: "gas" }
      ]
    }, :my_machine)

    my_machine = Automata.fetch(:my_machine)

    assert machine == my_machine
  end

  test "It should not fetch a machine state not already registered", state do
    machine = Automata.fetch(:non_existing_machine)

    assert machine == nil
  end
end
