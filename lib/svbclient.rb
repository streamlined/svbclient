# Encoding: utf-8

##
# svb-client.rb
#
# Example of HMAC request signing for use with the SVB API.
# See for the full documentation http://docs.svbplatform.com/authentication/.
# Email apisupport@svb.com for help!
#

require 'json'
require 'openssl'
require 'base64'
require 'net/https'
require 'uri'
require 'rest-client'

class SVBClient
  def initialize(api_key, hmac = nil, base_url: 'https://api.svb.com')
    @API_KEY = api_key
    @HMAC_SECRET = hmac
    @BASE_URL = base_url
  end

  def signature(timestamp, method, path, query, body)
    message = [timestamp, method, path, query, body].join("\n")
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @HMAC_SECRET, message)
  end

  def headers(method, path, query, body)
    hs = {
      "Authorization": "Bearer " + @API_KEY,
      "Content-Type": "application/json"
    }

    if @HMAC_SECRET
      mytimestamp = Time.now.to_i.to_s
      signature = signature(mytimestamp, method, path, query, body)
      hs["X-Timestamp"] = mytimestamp
      hs["X-Signature"] = signature
    end

    hs
  end

  def error_builder(error)
    error = {
      code: error.http_code,
      status_text: error.message,
      message: JSON.parse(error.response)
    }
    puts error
    error
  end

  def delete(path)
    begin
      hs = headers('DELETE', path, '', '')
      RestClient.delete(@BASE_URL + path, headers=hs)
    rescue => e
      error_builder(e)
    end
  end

  def get(path, query="")
    begin
      hs = headers('GET', path, query, '')
      RestClient.get(@BASE_URL + path + '?' + query, headers=hs)
    rescue => e
      error_builder(e)
    end
  end

  def patch(path, jsonbody)
    begin
      jsonbody = { data: jsonbody } unless jsonbody.key? 'data'
      hs = headers('PATCH', path, '', jsonbody.to_json)
      RestClient.patch(@BASE_URL + path, jsonbody.to_json, headers=hs)
    rescue => e
      error_builder(e)
    end
  end

  def post(path, jsonbody)
    begin
      jsonbody = { data: jsonbody } unless jsonbody.key? 'data'
      hs = headers('POST', path, '', jsonbody.to_json)
      RestClient.post(@BASE_URL + path, jsonbody.to_json, headers=hs)
    rescue => e
      error_builder(e)
    end
  end

  def upload(path, filesrc, mimetype)
    begin
      mytimestamp = Time.now.to_i.to_s
      signature = signature(mytimestamp, 'POST', path, '', '')

      hs = headers('POST', path, '', '')
      hs["Content-Type"] = "multipart/form-data"

      RestClient.post(@BASE_URL + path, { :file => filesrc, :multipart => true, 'Content-Type': mimetype }, headers=hs)
    rescue => e
      error_builder(e)
    end  
  end
end

class SVBClient::ACH
  def initialize(client, id)
    @client = client
    @id = id
  end

  def data
    JSON.parse(@client.get("/v1/ach/#{@id}").body)["data"]
  end

  def update_status(status)
    @client.patch("/v1/ach/#{id}", { status: status })
  end
end

class SVBClient::ACHHandler
  def initialize(client)
    raise 'provide an API client' if client.nil?
    @client = client
  end

  def create(ach_data)
    response = @client.post('/v1/ach', ach_data)
    SVBClient::ACH.new(@client, JSON.parse(response.body)["data"]["id"])
  end

  def get(id)
    @client.get("/v1/ach/#{id}")
    SVBClient::ACH.new(@client, id)
  end

  def find(status: nil, effective_date: nil)
    query = ''
    query += "filter%5Bstatus%5D=#{status}" unless status.nil?
    query += "filter%5Beffective_date%5D=#{effective_date}" unless effective_date.nil?
    response = @client.get("/v1/ach", query)
    list = JSON.parse(response.body)["data"]
    list.map do |ach|
      SVBClient::ACH.new(@client, ach["id"])
    end
  end
end

class SVBClient::Onboarding
  def initialize(client)
    raise 'provide an API client' if client.nil?
    @client = client
  end

  def address(id: nil, street_line1: nil, street_line2: nil, street_line3: nil, city: nil, state: nil, postal_code: nil, country: nil)
    if id.nil?
      # generate this address
      add = @client.post('/v1/addresses', {
        street_line1: street_line1,
        street_line2: street_line2,
        street_line3: street_line3,
        city: city,
        state: state,
        postal_code: postal_code,
        country: country
      })
      body = JSON.parse(add.body)
      SVBClient::Onboarding::Address.new(@client, body["data"]["id"])
    else
      # verify that the address exists
      @client.get("/v1/addresses/#{id}")
      SVBClient::Onboarding::Address.new(@client, id)
    end
  end

  def company(id: nil, description: nil, document_ids: [], email_address: nil, incorporation_address_id: -1,
    mailing_address_id: -1, metadata: nil, mcc: -1, name: nil, options: nil, parent_company_id: -1, person_ids: [],
    phone_number: nil, physical_address_id: -1, product_description: nil, products: [], referral_source: nil,
    risk_commentary: nil, source_of_funds: nil, state: nil, website_url: nil,
    documents: nil, incorporation_address: nil, mailing_address: nil, parent_company: nil,
    persons: nil, physical_address: nil)

    if id.nil?
      # generate this address

      unless documents.nil?
        document_ids = documents.map do |document|
          document.id
        end
      end
      unless persons.nil?
        person_ids = persons.map do |person|
          person.id
        end
      end
      incorporation_address_id = incorporation_address.id unless incorporation_address.nil?
      mailing_address_id = mailing_address.id unless mailing_address.nil?
      physical_address_id = physical_address.id unless physical_address.nil?
      parent_company_id = parent_company.id unless parent_company.nil?

      resource = @client.post('/v1/companies', {
        description: description,
        document_ids: document_ids,
        email_address: email_address,
        incorporation_address_id: incorporation_address_id,
        mailing_address_id: mailing_address_id,
        metadata: metadata,
        mcc: mcc,
        name: name,
        options: options,
        parent_company_id: parent_company_id,
        person_ids: person_ids,
        phone_number: phone_number,
        physical_address_id: physical_address_id,
        product_description: product_description,
        products: products,
        referral_source: referral_source,
        risk_commentary: risk_commentary,
        source_of_funds: source_of_funds,
        state: state,
        website_url: website_url
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::Company.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/companies/#{id}")
      SVBClient::Onboarding::Company.new(@client, id)
    end
  end

  def document(id: nil, document_type: nil, file_id: -1, metadata: nil, number: nil, file: nil)

    if id.nil?
      # generate this address
      file_id = file.id unless file.nil?

      resource = @client.post('/v1/documents', {
        document_type: document_type,
        file_id: file_id,
        metadata: metadata,
        number: number
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::Document.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/documents/#{id}")
      SVBClient::Onboarding::Document.new(@client, id)
    end
  end

  def file(id: nil, file: nil, mimetype: nil)
    if id.nil?
      # upload this file
      resource = @client.upload("/v1/files", file, mimetype)
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::File.new(@client, id)
    else
      # verify that the resource exists
      @client.get("/v1/files/#{id}")
      SVBClient::Onboarding::File.new(@client, id)
    end
  end

  def gov_ident(id: nil, country: nil, document_type: nil, expires_on: nil, file_id: -1,
    first_name: nil, last_name: nil, middle_name: nil, number: nil, file: nil)

    if id.nil?
      # generate this address
      file_id = file.id unless file.nil?

      resource = @client.post('/v1/gov_idents', {
        country: country,
        document_type: document_type,
        expires_on: expires_on,
        file_id: file_id,
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        number: number
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::GovIdent.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/gov_idents/#{id}")
      SVBClient::Onboarding::GovIdent.new(@client, id)
    end
  end

  def login(id: nil, login_name: nil, reservation_expires: nil)
    if id.nil?
      # generate this address
      resource = @client.post('/v1/logins', {
        login_name: login_name,
        reservation_expires: reservation_expires
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::Login.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/logins/#{id}")
      SVBClient::Onboarding::Login.new(@client, id)
    end
  end

  def parent_company(id: nil, address_id: -1, address: nil, country: nil, description: nil,
    name: nil, metadata: nil, percent_ownership: -1, source_of_funds: nil)

    if id.nil?
      # generate this address
      address_id = address.id unless address.nil?

      resource = @client.post('/v1/parent_companies', {
        address_id: address_id,
        country: country,
        description: description,
        name: name,
        metadata: metadata,
        percent_ownership: percent_ownership,
        source_of_funds: source_of_funds
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::ParentCompany.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/parent_companies/#{id}")
      SVBClient::Onboarding::ParentCompany.new(@client, id)
    end
  end

  def person(id: nil, address_id: -1, address: nil, date_of_birth: nil, email_address: nil,
    first_name: nil, gov_idents: [], gov_ident_ids: [], last_name: nil, login_id: -1, login: nil,
    metadata: nil, middle_name: nil, percent_ownership: -1, phone_number: nil, risk_commentary: nil,
    roles: [], title: nil)

    if id.nil?
      # generate this address
      unless gov_idents.nil?
        gov_ident_ids = gov_idents.map do |gov_ident|
          gov_ident.id
        end
      end
      address_id = address.id unless address.nil?
      login_id = login.id unless login.nil?

      resource = @client.post('/v1/persons', {
        address_id: address_id,
        date_of_birth: date_of_birth,
        email_address: email_address,
        first_name: first_name,
        gov_ident_ids: gov_ident_ids,
        last_name: last_name,
        login_id: login_id,
        metadata: metadata,
        middle_name: middle_name,
        percent_ownership: percent_ownership,
        phone_number: phone_number,
        risk_commentary: risk_commentary,
        roles: roles,
        title: title
      })
      body = JSON.parse(resource.body)
      SVBClient::Onboarding::Person.new(@client, body["data"]["id"])
    else
      # verify that the resource exists
      @client.get("/v1/persons/#{id}")
      SVBClient::Onboarding::Person.new(@client, id)
    end
  end
end

class SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'thing'
  end

  def id
    @id
  end

  def data
    JSON.parse(@client.get("/v1/#{@type}/#{@id}").body)["data"]
  end

  def update(jsonbody)
    @client.patch("/v1/#{@type}/#{@id}", jsonbody)
  end

  def delete
    @client.delete("/v1/#{@type}/#{@id}")
  end
end

class SVBClient::Onboarding::Address < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'addresses'
  end
end

class SVBClient::Onboarding::Company < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'companies'
  end
end

class SVBClient::Onboarding::Document < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'documents'
  end
end

class SVBClient::Onboarding::File < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'files'
  end

  def update
    raise 'unsupported'
  end
end

class SVBClient::Onboarding::GovIdent < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'gov_idents'
  end
end

class SVBClient::Onboarding::Login < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'logins'
  end

  def update
    raise 'unsupported'
  end
end

class SVBClient::Onboarding::ParentCompany < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'parent_companies'
  end
end

class SVBClient::Onboarding::Person < SVBClient::Onboarding::Resource
  def initialize(client, id)
    @client = client
    @id = id
    @type = 'persons'
  end
end
