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

    defmodule MoneyDeposited do
      defstruct amount: nil, balance: nil
    end

    defmodule MoneyWithdrawn do
      defstruct amount: nil, balance: nil
    end
  end

  alias Events.{BankAccountOpened,MoneyDeposited,MoneyWithdrawn}

  def new(id) do
    %BankAccount{id: id, state: %BankAccount.State{}}
  end

  def load(id, events) do
    account = %BankAccount{id: id, state: %BankAccount.State{}}
    Enum.reduce(events, account, &apply(&2, &1))
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    account
    |> apply(%BankAccountOpened{account_number: account_number, initial_balance: initial_balance})
  end

  def deposit(%BankAccount{} = account, amount) do
    balance = account.state.balance + amount

    account
    |> apply(%MoneyDeposited{ amount: amount, balance: balance })
  end

  def withdraw(%BankAccount{} = account, amount) do
    balance = account.state.balance - amount

    account
    |> apply(%MoneyWithdrawn{ amount: amount, balance: balance })
  end

  defp apply(%BankAccount{} = account, %BankAccountOpened{} = account_opened) do
    apply_event(account, account_opened, fn state -> %{state |
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyDeposited{} = money_deposited) do
    apply_event(account, money_deposited, fn state -> %{state |
      balance: money_deposited.balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyWithdrawn{} = money_withdrawn) do
    apply_event(account, money_withdrawn, fn state -> %{state |
      balance: money_withdrawn.balance
    } end)
  end

  defp apply_event(%BankAccount{} = account, event, update_state_fn) do
    %BankAccount{account |
      events: [event | account.events],
      state: update_state_fn.(account.state),
      version: account.version + 1
    }
  end
end
