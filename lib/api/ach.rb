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
    raise ArgumentError, "ACH ID is required" if id.to_s.strip.empty?

    get(path: "/v2/transfer/domestic-achs/#{id}", scope: ACH_SCOPE)
  end

  def get_legacy_ach(id, api_key: nil, hmac_secret: nil)
    raise ArgumentError, "ACH ID is required" if id.to_s.strip.empty?

    path = "/v1/ach/#{id}"
    headers = {
      "Authorization": "Bearer #{api_key}",
      "Content-Type": 'application/json'
    }

    if hmac_secret
      timestamp = Time.now.to_i.to_s
      message = [timestamp, 'GET', path, '', ''].join("\n")
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), hmac_secret, message)

      headers["X-Timestamp"] = timestamp
      headers["X-Signature"] = signature
    end

    uri = URI.parse(@base_url + path)
    request = Net::HTTP::Get.new(uri, headers)
    response = send_request(uri, request)
    parsed_body = JSON.parse(response.body)

    {
      code: response.code,
      data: parsed_body['data'] || parsed_body,
    }
  end

  def create_ach(batch_details: {}, transfers: [])
    raise ArgumentError, "Batch details are required" if batch_details.nil? || batch_details.empty?
    raise ArgumentError, "Transfer details are required" if transfers.nil? || transfers.empty?

    payload = {
      batch_details: batch_details,
      transfers: transfers
    }
    post(path: '/v2/transfer/domestic-achs', body: payload, scope: ACH_SCOPE)
  end

  def cancel_ach(id)
    raise ArgumentError, "ACH ID is required" if id.to_s.strip.empty?

    payload = [{
                 "op": "replace",
                 "path": "/status",
                 "value": "CANCELED"
               }]
    patch(path: "/v2/transfer/domestic-achs/#{id}", body: payload, scope: ACH_SCOPE)
  end

  def reverse_ach(id, reason: "DUPLICATE_ENTRY")
    raise ArgumentError, "ACH ID is required" if id.to_s.strip.empty?

    valid_reasons = %w[DUPLICATE_ENTRY INCORRECT_RECEIVER_(NOT_FRAUD_RELATED) INCORRECT_DOLLAR_AMOUNT_(NOT_FRAUD_RELATED) DEBIT(S)_SENT_EARLIER_THAN_INTENDED CREDIT(S)_SENT_LATER_THAN_INTENDED PPD_CREDIT_RELATED_TERMINATION/SEPARATION_FROM_EMPLOYMENT]

    if reason && !valid_reasons.include?(reason)
      raise ArgumentError, "Invalid reason. Must be one of: #{valid_reasons.join(', ')}"
    end

    payload = {
      batch_details: {
        settlement_priority: "STANDARD"
      },
      reversal_details_single_mass_id: {},
      reversal_details_multiple_id: [
        {
          reason_for_reversal: reason,
          original_id: id
        }
      ]
    }

    headers = {
      "prefer" => "RETURN_REPRESENTATION"
    }

    post(path: '/v2/transfer/reversal', body: payload, scope: ACH_SCOPE, headers: headers)
  end

end
