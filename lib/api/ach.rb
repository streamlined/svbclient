module SVB
  module ACH

    ACH_SCOPE = 'ach'
    def list_achs(
      account_number: nil,
      amount: nil,
      direction: nil,
      effective_entry_date: nil,
      offset: nil,
      limit: nil,
      status: nil,
      batch_id: nil
    )
      query_params = {
        svb_account_number: account_number,
        amount: amount,
        direction: direction,
        effective_entry_date: effective_entry_date,
        offset: offset,
        limit: limit,
        status: status,
        batch_id: batch_id
      }.compact

      query_string = URI.encode_www_form(query_params)
      path = '/v2/transfer/domestic-achs'
      path += "?#{query_string}" unless query_string.empty?

      get(path: path, scope: ACH_SCOPE)
    end

    def get_ach(id)
      raise ArgumentError, "ACH ID is required" if id.blank?

      get(path: "/v2/transfer/domestic-achs/#{id}", scope: ACH_SCOPE)
    end

    def create_ach(batch_details: {}, transfers: [])
      raise ArgumentError, "Batch details are required" if batch_details.blank? || batch_details.empty?
      raise ArgumentError, "Transfer details are required" if transfers.blank? || transfers.empty?

      payload = {
        batch_details: batch_details,
        transfers: transfers
      }
      post(path: '/v2/transfer/domestic-achs', body: payload, scope: ACH_SCOPE)
    end

    def cancel_ach(id)
      raise ArgumentError, "ACH ID is required" if id.blank?

      payload = [{
        "op": "replace",
        "path": "/status",
        "value": "CANCELED"
      }]
      patch(path: "/v2/transfer/domestic-achs/#{id}", body: payload, scope: ACH_SCOPE)
    end
  end
end