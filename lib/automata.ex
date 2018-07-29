defmodule Automata do
  def factory(config) do
    init_state = config[:init]
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
            def unquote(:"#{transition[:name]}")() do
              state = Agent.get(:automata_state, &((&1[:state])))
              state_from = unquote("#{transition[:from]}")
              state_to = unquote("#{transition[:to]}")

              if state == state_from do
                Agent.update(:automata_state, &(%{&1 | state: state_to}))
                {:ok, state_to}
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
    state_machine.start_link(%{state: init_state})
    state_machine
  end
end
