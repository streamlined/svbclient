module SVB
  module AccountBalance

    ACCOUNT_BALANCE_SCOPE = 'accountbalance'

    def get_account_balance(account_number:)
      raise ArgumentError, "Account number is required" if account_number.blank?

      body = {account: account_number}.to_json
      post(path:"/v1/accounts/balances", body: body, scope: ACCOUNT_BALANCE_SCOPE)
    end
  end
end