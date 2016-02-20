defmodule BankAccount do
  defstruct id: nil, account_number: nil, balance: nil

  defmodule Events do
    defmodule BankAccountOpened do
      defstruct id: nil, account_number: nil, initial_balance: nil
    end
  end

  alias Events.BankAccountOpened

  def new do
    %BankAccount{
      id: UUID.uuid1()
    }
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    %BankAccountOpened {
      id: account.id,
      account_number: account_number,
      initial_balance: initial_balance
    }
  end

  def apply(%BankAccount{} = account, %BankAccountOpened{} = account_opened) do
    Map.merge(account, %{
      id: account_opened.id,
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    })
  end
end