# Encoding: utf-8
require 'spec_helper'
require 'svbclient'
require 'json'

api_key = ''
hmac = ''

describe 'simple requests' do
  it 'should do a GET request' do
    client = SVBClient.new(api_key, hmac)
    j = JSON.parse(client.get("/v1").body)
    expect(j["api_version"]).to eq("1")
    expect(j["fault"]).to eq(nil)
  end

  it 'should do a GET request with no hmac' do
    client = SVBClient.new(api_key)
    j = JSON.parse(client.get("/v1").body)
    expect(j["api_version"]).to eq("1")
    expect(j["fault"]).to eq(nil)
  end

  it 'should do a POST request' do
    client = SVBClient.new(api_key, hmac)
    j = JSON.parse(client.post("/v1", { "a": "b" }).body)
    expect(j["api_version"]).to eq("1")
    expect(j["fault"]).to eq(nil)
  end

  it 'should upload a file' do
    client = SVBClient.new(api_key, hmac)
    client.upload("/v1/files", File.new("./spec/y18.png", "rb"), 'image/png')
  end

  it 'should do a bad request' do
    expect {
      client = SVBClient.new('fail', 'fail')
      client.get("/v1")
    }.to raise_error
  end
end

describe 'onboarding helper' do
  it 'creates an address' do
    client = SVBClient.new(api_key, hmac, base_url: 'http://localhost:4000')
    Onboarding = SVBClient::Onboarding.new(client)

    address = Onboarding.address(street_line1: '221B Baker St', city: 'London', country: 'GB')
    expect(address.data["street_line1"]).to eq("221B Baker St")

    address.update({ street_line1: "222 Baker St" })
    expect(address.data["street_line1"]).to eq("222 Baker St")
  end

  it 'fails to create an address without a city or country' do
    client = SVBClient.new(api_key, hmac, base_url: 'http://localhost:4000')
    Onboarding = SVBClient::Onboarding.new(client)

    expect {
      address = Onboarding.address(street_line1: '221B Baker St')
    }.to raise_error
  end
end

describe 'ACH features' do
  it 'creates an ACH' do
    client = SVBClient.new(api_key, hmac)
    handler = SVBClient::ACHHandler.new(client)
    handler.create({})
  end

  it 'lists canceled ACHs' do
    client = SVBClient.new(api_key, hmac)
    handler = SVBClient::ACHHandler.new(client)
    cancels = handler.find({ status: 'canceled' })
    expect(cancels.length).to eq(36)
  end

  it 'lists pending ACHs' do
    client = SVBClient.new(api_key, hmac)
    handler = SVBClient::ACHHandler.new(client)
    cancels = handler.find({ status: 'pending' })
    expect(cancels.length).to eq(0)
  end
end
