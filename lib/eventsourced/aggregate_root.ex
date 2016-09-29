defmodule EventSourced.AggregateRoot do
  defmacro __using__(fields: fields) do
    quote do
      import Kernel, except: [apply: 2]

      defstruct uuid: nil, version: 0, pending_events: [], state: nil

      defmodule State do
        defstruct unquote(fields)
      end

      @doc """
      Create a new aggregate root struct given a unique identity
      """
      def new(uuid) do
        %__MODULE__{uuid: uuid, state: %__MODULE__.State{}}
      end

      @doc """
      Rebuild the aggregate's state from a given list of previously raised domain events
      """
      def load(uuid, events) when is_list(events) do
        state = Enum.reduce(events, %__MODULE__.State{}, &__MODULE__.apply(&2, &1))

        %__MODULE__{uuid: uuid, state: state, version: length(events), pending_events: []}
      end

      # Receives a single event and is used to mutate the aggregate's internal state.
      defp update(%__MODULE__{uuid: uuid, version: version, pending_events: pending_events, state: state} = aggregate, event) do
        version = version + 1
        state = __MODULE__.apply(state, event)
        pending_events = [event | pending_events] |> Enum.reverse

        %__MODULE__{aggregate |
          pending_events: pending_events,
          state: state,
          version: version
        }
      end
    end
  end
end
