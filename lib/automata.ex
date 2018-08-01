defmodule Automata do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: :automata_store)
  end

  def fetch(name) do
    Agent.get(:automata_store, &(&1[name]))
  end

  defp builder(config) do
    init_state = config[:init_state]
    init_data = config[:init_data]
    transitions = config[:transitions]

    module = quote do
      defmodule State do
        use Agent

        def start_link(store) do
          Agent.start_link(fn -> store end, name: :automata_state)
        end

        def get_state() do
          Agent.get(:automata_state, &((&1[:state])))
        end

        var!(transitions) |> Enum.each(fn(transition) ->
          method = quote do
            transition = var!(transition)
            def unquote(:"#{transition[:name]}")(data) do
              state_machine = Agent.get(:automata_state, &(&1))
              state_from = unquote("#{transition[:from]}")
              state_to = unquote("#{transition[:to]}")

              if state_machine[:state] == state_from do
                state_guard = transition[:guard]
                if is_function(state_guard) do
                  case state_guard(state_machine, state_to, data) do
                    {:ok, true} -> 
                      Agent.update(:automata_state, &(%{&1 | state: state_to}))
                      {:ok, state_to}
                    {:error, cause} -> {:error, cause}
                  end
                else
                  Agent.update(:automata_state, &(%{&1 | state: state_to}))
                  {:ok, state_to}
                end
              else
                {:error, "Cannot change state from #{state} to #{state_to}"}
              end
            end
          end

          {{method, _}, _} = Code.eval_quoted method, [transition: transition], __ENV__
          method
        end)
      end
    end

    {{_, state_machine, _, _}, _} = Code.eval_quoted module, [transitions: transitions], __ENV__
    state_machine.start_link(%{state: init_state, data: init_data})
    state_machine
  end

  def factory(config) do
    builder(config)
  end

  def factory(config, name) do
    state_machine = builder(config)
    Agent.update(:automata_store, fn(store) -> Map.put(store, name, state_machine) end)
    state_machine
  end
end
