module SVB
  module AccountTransfer

    ACCOUNT_TRANSFER_SCOPE = 'accounttransfer'

    def list_transfers(offset: nil, limit: nil)
      query_params = {
        offset: offset,
        limit: limit
      }.compact

      query_string = URI.encode_www_form(query_params)
      path = '/v1/payment/account-transfers'
      path += "?#{query_string}" unless query_string.empty?

      get(path: path, scope: ACCOUNT_TRANSFER_SCOPE)
    end

    def get_transfer(id)
      raise ArgumentError, "Transfer ID is required" if id.blank?

      get(path: "/v1/payment/account-transfers/#{id}", scope: ACCOUNT_TRANSFER_SCOPE)
    end

    def create_transfer(amount:, from_account_number:, to_account_number:, memo:nil)
      raise ArgumentError, "Amount is required" if amount.blank? || amount <= 0
      raise ArgumentError, "A from_account and to_account is required" if from_account_number.blank? || to_account_number.blank?

      return if amount.nil? || amount <= 0
      payload = {
        from_account: from_account_number.to_s,
        to_account: to_account_number.to_s,
        amount: {
          currency_code: "USD",
          value: sprintf('%.2f', (amount.to_f / 100)) #coverts cents to dollars and cents in format 0.00
        },
        memo: memo
      }.compact

      post(path: '/v1/payment/account-transfers', body: payload, scope: ACCOUNT_TRANSFER_SCOPE)
    end
  end
end
