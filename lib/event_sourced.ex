defmodule EventSourced do
  @moduledoc """
  Defines a single macro that is used to build an event-sourced aggregate root.

  Using the macro you must define the fields that comprise the aggregates state.

  Three functions are included into your module.

  - `new` used to create a new aggregate root struct given a unique identity
  - `load` to rebuild an aggregate's state from a given list of previously raised domain events.
  - `update` that receives a single event and is used to mutate the aggregate's internal state.

  ## Usage

    defmodule BankAccount do
      use EventSourced.AggregateRoot, fields: [account_number: nil, balance: nil]
    end

    account = BankAccount.new("ACC1234")
  """
end
