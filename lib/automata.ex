# todo: add doc string
# todo: add linting
# todo: add typespecs
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
    random_seed = :rand.uniform(100000)
    module_name = "AutomataStateMachineModule#{random_seed}"
    module_state_name = "automata_state_#{random_seed}"

    cond do
      !is_bitstring(init_state) or String.length(init_state) == 0 ->
        {:error, "init_state field is required and must be a string"}
      !is_list(transitions) or length(transitions) == 0 ->
        {:error, "transitions field is required and must be a filled list"}
      true -> 
        module = quote do
          defmodule unquote(:"#{module_name}") do
            use Agent

            def start_link(store) do
              Agent.start_link(fn -> store end, name: unquote(:"#{module_state_name}"))
            end

            def get_state() do
              Agent.get(unquote(:"#{module_state_name}"), &(&1[:state]))
            end

            def get_data() do
              Agent.get(unquote(:"#{module_state_name}"), &(&1[:data]))
            end

            var!(transitions) |> Enum.each(fn(transition) ->
              module_state_name = var!(module_state_name)
              method = quote do
                module_state_name = var!(module_state_name)
                def unquote(:"#{transition[:name]}")(data \\ nil) do
                  state_machine = Agent.get(unquote(:"#{module_state_name}"), &(&1))
                  state = state_machine[:state]
                  state_from = unquote("#{transition[:from]}")
                  state_to = unquote("#{transition[:to]}")

                  if state == state_from do
                    state_guard = unquote(transition[:guard])
                    if is_function(state_guard) do
                      case state_guard.(state_machine, state_to, data) do
                        {:ok, true} -> 
                          Agent.update(unquote(:"#{module_state_name}"), &(%{&1 | state: state_to}))
                          {:ok, state_to}
                        {:error, cause} -> {:error, cause}
                      end
                    else
                      Agent.update(unquote(:"#{module_state_name}"), &(%{&1 | state: state_to}))
                      {:ok, state_to}
                    end
                  else
                    {:error, "Cannot change state from #{state} to #{state_to}"}
                  end
                end
              end

              {{method, _}, _} = Code.eval_quoted method, [transition: transition, module_state_name: module_state_name], __ENV__
              method
            end)
          end
        end

        {{_, state_machine, _, _}, _} = Code.eval_quoted module, [transitions: transitions, module_state_name: module_state_name], __ENV__
        state_machine.start_link(%{state: init_state, data: init_data})
        {:ok, state_machine}
    end
  end

  def factory(config) do
    builder(config)
  end

  def factory(config, name) do
    case builder(config) do
      {:ok, state_machine} ->
        Agent.update(:automata_store, fn(store) -> Map.put(store, name, state_machine) end)
        {:ok, state_machine}
      {:error, reason} -> {:error, reason}
    end
  end
end
