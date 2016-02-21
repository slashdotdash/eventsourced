defmodule BankAccount do
  import Kernel, except: [apply: 2]

  defstruct id: nil, state: nil, events: [], version: 0

  defmodule State do
    defstruct account_number: nil, balance: nil
  end

  defmodule Events do
    defmodule BankAccountOpened do
      defstruct account_number: nil, initial_balance: nil
    end
  end

  alias Events.BankAccountOpened

  def new do
    %BankAccount{id: UUID.uuid1(), state: %BankAccount.State{}}
  end

  def load(id, events) do
    account = %BankAccount{id: id, state: %BankAccount.State{}}    
    Enum.reduce(events, account, &apply(&2, &1))
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    account 
    |> apply(%BankAccountOpened {
      account_number: account_number,
      initial_balance: initial_balance
    })
  end

  defp apply(%BankAccount{} = account, %BankAccountOpened{} = account_opened) do
    apply_event(account, account_opened, %{
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    })
  end

  defp apply_event(%BankAccount{} = account, event, state) do
    Map.merge(account, %{
      events: [event | account.events],
      state: Map.merge(account.state, state)
    })
  end
end