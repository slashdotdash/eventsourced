defmodule BankAccount do
  @moduledoc """
  An example bank account aggregate root.

  It demonstrates returning either an `{:ok, aggregate}` or `{:error, reason}` tuple from the public API functions on success or failure.

  Following this approach allows strict pattern matching on success and failures.
  An error indicates a domain business rule violation, such as attempting to open an account with a negative initial balance.

  You cannot use the pipeline operation (`|>`) to chain the functions.
  Use the `with` special form instead, as shown in the example below.

  ## Example usage

    with account <- BankAccount.new("123"),
      {:ok, account} <- BankAccount.open_account(account, "ACC123", 100),
      {:ok, account} <- BankAccount.deposit(account, 50),
    do: account

  """
  use EventSourced.AggregateRoot, fields: [account_number: nil, balance: nil]

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

  def open_account(%BankAccount{} = _account, _account_number, initial_balance) when initial_balance <= 0 do
    {:error, :initial_balance_must_be_above_zero}
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    {:ok, update(account, %BankAccountOpened{account_number: account_number, initial_balance: initial_balance})}
  end

  def deposit(%BankAccount{} = account, amount) do
    balance = account.state.balance + amount

    {:ok, update(account, %MoneyDeposited{amount: amount, balance: balance})}
  end

  def withdraw(%BankAccount{state: %{balance: balance}}, amount) when amount > balance do
    {:error, :not_enough_funds}
  end

  def withdraw(%BankAccount{} = account, amount) do
    balance = account.state.balance - amount

    {:ok, update(account, %MoneyWithdrawn{amount: amount, balance: balance})}
  end

  # state mutators

  def apply(%BankAccount.State{} = state, %BankAccountOpened{} = account_opened) do
    %BankAccount.State{state|
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    }
  end

  def apply(%BankAccount.State{} = state, %MoneyDeposited{} = money_deposited) do
    %BankAccount.State{state |
      balance: money_deposited.balance
    }
  end

  def apply(%BankAccount.State{} = state, %MoneyWithdrawn{} = money_withdrawn) do
    %BankAccount.State{state |
      balance: money_withdrawn.balance
    }
  end
end
