defmodule BankAccountTest do
  use ExUnit.Case
  doctest DomainModel

  alias BankAccount.Events.BankAccountOpened

  test "open account" do
    account = BankAccount.new
    event = BankAccount.open_account(account, "ACC123", 100)

    assert event == %BankAccountOpened{id: account.id, account_number: "ACC123", initial_balance: 100}
    assert BankAccount.apply(account, event) == %BankAccount{id: account.id, account_number: "ACC123", balance: 100}
  end
end
