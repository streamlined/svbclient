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

end