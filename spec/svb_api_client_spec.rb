# Encoding: utf-8
require 'spec_helper'
require 'svb_api_client'
require 'json'

RSpec.describe SVB::API::Client do
  let(:client_id) { '' }
  let(:client_secret) { '' }
  let(:client) { described_class.new(client_id: client_id, client_secret: client_secret) }

  describe '#get_account_balance' do
    let(:account_number) { '3300297004' }
    let(:invalid_account_number) { '1234567890' }

    it 'returns a valid account balance' do
      response = client.get_account_balance(account_number: account_number)

      expect(response[:code]).to eq('200')

      body = response[:data]
      expect(body).to be_a(Hash)

      deposit_balances = body['deposit_balances']
      expect(deposit_balances).to be_a(Array)

      deposit_info = deposit_balances.first

      account = deposit_info['account']
      expect(account).to eq(account_number.to_s)

      currency = deposit_info['currency']
      expect(currency).to eq('USD')

      balance_info = deposit_info['balance_information']
      expect(balance_info).to be_a(Array)

      available_balance = balance_info.first['available_balance']
      expect(available_balance).to be_a(Hash)

      expect(available_balance['value']).to be_a(String)
      expect(available_balance['value'].to_f).to be > 0
    end

    it 'returns an error if account number is invalid' do
      response = client.get_account_balance(account_number: invalid_account_number)

      expect(response[:code]).to eq('400')

      expect(response[:data]['name']).to eq('ENTITLEMENT_ERROR')
    end

    it 'raises an ArgumentError if no account number is provided' do
      expect {
        client.get_account_balance(account_number: nil)
      }.to raise_error(ArgumentError, "Account number is required")

      expect {
        client.get_account_balance(account_number: '')
      }.to raise_error(ArgumentError, "Account number is required")
    end
  end

  describe '#list_transfers' do
    it 'retrieves a list of all account-to-account book transfers' do
      response = client.list_transfers

      expect(response[:code]).to eq('200')
      expect(response[:data]['items']).to be_an(Array)
      expect(response[:data]['total_items']).to be_an(Integer)
      expect(response[:data]['total_pages']).to be_an(Integer)
    end
  end

  describe '#create_transfer and #get_transfer' do
    describe 'Transfer operations' do
      let (:from_account_number) { 3300297042 }
      let (:to_account_number) { 3300297004 }
      let (:transfer_amount) { 100 }

      let(:created_transfer_id) { @created_transfer_id }
      let(:created_transfer_status) { @created_transfer_status }
      let(:created_transfer_response_code) { @created_transfer_response_code }
      let(:created_transfer_amount) { @created_transfer_amount }

      before do
        response = client.create_transfer(amount: transfer_amount, from_account_number: from_account_number, to_account_number: to_account_number, memo: 'Lockbox Sweep')

        @created_transfer_response_code = response[:code]
        @created_transfer_id = response[:data]['id']
        @created_transfer_status = response[:data]['status']
        @created_transfer_amount = response[:data]['amount']['value']
      end

      it 'creates an account-to-account book transfer successfully' do
        expect(@created_transfer_response_code).to eq('201')
        expect(@created_transfer_id).to be_a(String)
        expect(@created_transfer_status).to match(/PROCESSING|SUCCEEDED/)
        expect(@created_transfer_amount).to eq('1.00')
      end

      it 'retrieves details of an account-to-account book transfer' do
        response = client.get_transfer(created_transfer_id)

        expect(response[:code]).to eq('200')
        expect(response[:data]['id']).to eq(created_transfer_id)
        expect(response[:data]['status']).to be_a(String)

        expect(response[:data]['from_account']).to be_a(String)
        expect(response[:data]['from_account']).to eq(from_account_number.to_s)

        expect(response[:data]['to_account']).to be_a(String)
        expect(response[:data]['to_account']).to eq(to_account_number.to_s)

        expect(response[:data]['amount']['value']).to be_a(String)
        expect(response[:data]['amount']['value']).to eq('1.00')
      end

      it 'raises an ArgumentError if no amount or account numbers provided' do
        expect {
          client.create_transfer(amount: '', from_account_number: from_account_number, to_account_number: to_account_number, memo: 'Lockbox Sweep')
        }.to raise_error(ArgumentError, "Amount is required")

        expect {
          client.create_transfer(amount: 0, from_account_number: from_account_number, to_account_number: to_account_number, memo: 'Lockbox Sweep')
        }.to raise_error(ArgumentError, "Amount is required")

        expect {
          client.create_transfer(amount: 2500, from_account_number: '', to_account_number: '', memo: 'Lockbox Sweep')
        }.to raise_error(ArgumentError, "A from_account and to_account is required")

        expect {
          client.create_transfer(amount: 2500, from_account_number: from_account_number, to_account_number: '', memo: 'Lockbox Sweep')
        }.to raise_error(ArgumentError, "A from_account and to_account is required")

        expect {
          client.create_transfer(amount: 2500, from_account_number: nil, to_account_number: to_account_number, memo: 'Lockbox Sweep')
        }.to raise_error(ArgumentError, "A from_account and to_account is required")
      end
    end
  end

  describe '#get_transfer' do
    let (:invalid_transfer_id) {'12345678-a67f-4f5e-9e28-8b5f8a940114'}

    it 'returns 404 error if an invalid transfer id is provided' do
      response = client.get_transfer(invalid_transfer_id)
      expect(response[:code]).to eq('404')
      expect(response[:data]['name']).to eq('not_found')
    end

    it 'raises an ArgumentError if no transfer id provided' do
      expect {
        client.get_transfer('')
      }.to raise_error(ArgumentError, "Transfer ID is required")

      expect {
        client.get_transfer(nil)
      }.to raise_error(ArgumentError, "Transfer ID is required")
    end
  end

  describe '#list_achs' do
    let (:account_number) { 3300297004 }

    it 'retrieves a list of all ACH transfers' do
      response = client.list_achs

      expect(response[:code]).to eq('200')
      expect(response[:data]['items']).to be_an(Array)
      expect(response[:data]['total_items']).to be_an(Integer)
      expect(response[:data]['total_pages']).to be_an(Integer)
    end

    it 'retrieves a list of all ACH transfers for a given account' do
      response = client.list_achs(account_number: account_number)

      expect(response[:code]).to eq('200')
      expect(response[:data]['items']).to be_an(Array)
      expect(response[:data]['total_items']).to be_an(Integer)
      expect(response[:data]['total_pages']).to be_an(Integer)
    end
  end

  describe '#create_ach, #get_ach and #cancel_ach' do
    let (:account_number) { 3300297004 }

    describe 'ACH operations' do
      let(:batch_details) do
        {
          account_number: account_number,
          direction: "CREDIT",
          sec_code: "PPD",
          settlement_priority: "STANDARD",
          company_entry_description: "A123456789",
          effective_entry_date: Date.today.strftime("%Y-%m-%d"),
          currency: "USD",
          company_name: 'Streamlined Inc'
        }
      end
      let(:transfers) do
        [
          {
            amount: 55555,
            company_name: 'Streamlined',
            identification_number: "000015234AB",
            receiver_account_number: "2222220",
            receiver_account_type: "CHECKING",
            receiver_name: "Spice Corp",
            receiver_routing_number: "321081669"
          }
        ]
      end
      let(:created_ach_id) { @created_ach_id }
      let(:created_ach_status) { @created_ach_status }
      let(:created_ach_response_code) { @created_ach_response_code }

      before do
        response = client.create_ach(batch_details: batch_details, transfers: transfers)

        @created_ach_response_code = response[:code]
        @created_ach_id = response[:data]['results'].first['id']
        @created_ach_status = response[:data]['results'].first['validation_status']
      end

      it 'creates an ACH successfully' do
        expect(@created_ach_response_code).to eq('201')
        expect(@created_ach_id).to be_a(String)
        expect(@created_ach_status).to eq('SUCCESS')
      end

      it 'retrieves details of an ACH' do
        response = client.get_ach(created_ach_id)

        expect(response[:code]).to eq('200')
        expect(response[:data]['id']).to eq(created_ach_id)
        expect(response[:data]['status']).to be_a(String)
        expect(response[:data]['company_entry_description']).to be_a(String)
        expect(response[:data]['effective_entry_date']).to be_a(String)
        expect(response[:data]['amount']).to be_an(Integer)
      end

      it 'cancels an ACH successfully' do
        response = client.cancel_ach(created_ach_id)

        expect(response[:code]).to eq('200')
        expect(response[:data]['id']).to eq(created_ach_id)
        expect(response[:data]['status']).to eq('CANCELED')
      end
    end
  end

  describe '#cancel_ach' do
    let (:invalid_ach_id) { '12345678-8773-4c97-91f7-4335725122ba' }

    it 'returns 404 error if an invalid ach id is provided' do
      response = client.cancel_ach(invalid_ach_id)
      expect(response[:code]).to eq('404')
      expect(response[:data]['name']).to eq('Resource not found')
    end

    it 'raises an ArgumentError if no ach id provided' do
      expect {
        client.cancel_ach('')
      }.to raise_error(ArgumentError, "ACH ID is required")

      expect {
        client.cancel_ach(nil)
      }.to raise_error(ArgumentError, "ACH ID is required")
    end
  end

  describe '#get_ach' do
    let (:invalid_ach_id) { '12345678-8773-4c97-91f7-4335725122ba' }

    it 'returns 404 error if an invalid ach id is provided' do
      response = client.get_ach(invalid_ach_id)
      expect(response[:code]).to eq('404')
      expect(response[:data]['name']).to eq('Resource not found')
    end

    it 'raises an ArgumentError if no ach id provided' do
      expect {
        client.get_ach('')
      }.to raise_error(ArgumentError, "ACH ID is required")

      expect {
        client.get_ach(nil)
      }.to raise_error(ArgumentError, "ACH ID is required")
    end
  end

end
