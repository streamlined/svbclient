# SVBClient Ruby gem

A gem which you can use in your Ruby / Ruby on Rails app to simplify your integration with the SVB API.

## Table of Contents
- [Installation](#installation)
- [Initialization](#initialization)
- [Usage](#api-usage)
    - [Account Balance](#account-balance)
    - [ACH Transfers](#ach)
    - [Account Transfers](#account-transfers)
- [Testing](#testing)
- [Contributing](#contributing)


## Installation

Via command line:

```
gem install svbclient
```

In a Gemfile:

```ruby
gem 'svbclient', '~> 4.0.0'
```

## Initialization

```ruby
require 'svbclient'

client = SVB::Client.new(client_id: CLIENT_ID, client_secret: CLIENT_SECRET)
```
*Note:* The client defaults to the Sandbox environment. To use the Production environment, set the `base_url` parameter
to 'https://api.svb.com' when initializing the client.

## API Usage

### Account Balance

Get account balance
```ruby
client.get_account_balance(account_number: '1111111111')
```
```ruby
{
  :code => "200",
  :data => {
    "deposit_balances" => [
      {
        "account" => "1111111111",
        "currency" => "USD",
        "balance_information" => [
          {
            "available_balance" => {
              "value" => "5231245.4"
            }
          }
        ]
      }
    ],
    "total_items" => "1"
  }
}
```

### ACH

#### Get a list of all ACH
```ruby
client.list_achs
```
```ruby
{
  :code=>"200", 
  :data=>{
    "links"=>[
      {
        "method"=>"GET", 
        "rel"=>"self", 
        "href"=>"https://uat.api.svb.com/v2/transfer/domestic-achs?offset=1&limit=1000"
      }
    ], 
    "items"=>[
      {
        "id"=>"25dbe37c-8773-4c97-91f7-4335725122ba",
        "links"=>[
          {
            "method"=>"GET", 
            "rel"=>"self", 
            "href"=>"https://uat.api.svb.com/v2/transfer/domestic-achs/25dbe37c-8773-4c97-91f7-4335725122ba"
          }
        ]
      }
    ], 
    "total_items"=>1, 
    "total_pages"=>1
  }
}
```

#### Search ACH by field

`account_number`, `amount`, `direction`, `effective_entry_date`, `offset`, `limit`, `status`, `batch_id`
```ruby
client.list_achs(effective_entry_date: "2024-10-23")
```

#### Create an ACH
```ruby
client.create_ach(batch_details: {
  account_number: "1111111111", # Originating account number
  direction: "CREDIT", #CREDIT or DEBIT
  sec_code: "PPD", #PPD for customer related. CCD for corporate account to account (across different banks).
  settlement_priority: "STANDARD", #STANDARD or SAME_DAY
  company_entry_description: "A123456789",
  effective_entry_date: "2024-10-23",
  currency: "USD",
  company_name: 'Streamlined',
}, transfers: [
  {
    amount: 55555,
    company_name: 'Streamlined', #OBO name to display to recipient
    identification_number: "000015234AB",
    receiver_account_number: "2222220",
    receiver_account_type: "CHECKING",
    receiver_name: "Spice Corp",
    receiver_routing_number: "321081669"
  }
])
```
```ruby
{
  :code=>"201", 
  :data=>{
    "results"=>[
      {
        "id"=>"25dbe37c-8773-4c97-91f7-4335725122ba", 
        "index"=>0, 
        "validation_status"=>"SUCCESS"
      }
    ], 
    "links"=>[]
  }
}
```

#### Get ACH details
```ruby
client.get_ach('25dbe37c-8773-4c97-91f7-4335725122ba')
```
```ruby
{
  :code=>"200", 
  :data=>{
    "company_entry_description"=>"A123456789", 
    "effective_entry_date"=>"2024-10-23", 
    "svb_account_number"=>"3300187974", 
    "currency"=>"USD", 
    "company_name"=>"Streamlined", 
    "direction"=>"CREDIT", 
    "settlement_priority"=>"STANDARD", 
    "sec_code"=>"CCD", 
    "receiver_account_number"=>"2222220", 
    "receiver_account_type"=>"CHECKING", 
    "receiver_name"=>"Spice Corp", 
    "receiver_routing_number"=>"321081669", 
    "additional_information"=>{}, 
    "amount"=>55555, 
    "identification_number"=>"000015234AB", 
    "id"=>"25dbe37c-8773-4c97-91f7-4335725122ba", 
    "status"=>"PENDING", 
    "mass_delivery_id"=>"10979515-dc52-4217-929b-13015af4be31", 
    "created_at"=>"2024-09-24T14:20:12.020593Z", 
    "updated_at"=>"2024-09-24T14:20:12.020593Z", 
    "links"=>[
      {
        "method"=>"GET", 
        "rel"=>"self", 
        "href"=>"https://uat.api.svb.com/v2/transfer/domestic-achs/25dbe37c-8773-4c97-91f7-4335725122ba"
      }
    ]
  }
}
```

#### Cancel an ACH
```ruby
client.cancel_ach('083a2d38-a82f-41f2-b658-01c8402b70d4')
```

```ruby
{
  :code=>"200", 
  :data=>{
    "company_entry_description"=>"A123456789", 
    "effective_entry_date"=>"2024-10-23", 
    "svb_account_number"=>"3300187974", 
    "currency"=>"USD", 
    "company_name"=>"Streamlined", 
    "direction"=>"CREDIT", 
    "settlement_priority"=>"STANDARD", 
    "sec_code"=>"PPD", 
    "receiver_account_number"=>"2222220", 
    "receiver_account_type"=>"CHECKING", 
    "receiver_name"=>"Spice Corp", 
    "receiver_routing_number"=>"321081669", 
    "additional_information"=>{}, 
    "amount"=>55555, 
    "identification_number"=>"000015234AB", 
    "id"=>"083a2d38-a82f-41f2-b658-01c8402b70d4", 
    "status"=>"CANCELED", 
    "mass_delivery_id"=>"5c36d5ae-01ab-4a23-9113-ba34bcd72ce0", 
    "created_at"=>"2024-09-25T06:23:54.829735Z", 
    "updated_at"=>"2024-09-25T06:40:38.548308013Z", 
    "links"=>[]
  }
}
```

### Account Transfers

#### Create an account-to-account book transfer
```ruby
client.create_transfer(amount: 250000, from_account_number: 3300297004, to_account_number: 3300297042, memo: 'Lockbox Sweep')
```
```ruby
{
  :code=>"201", 
  :data=>{
    "id"=>"6085f92a-a67f-4f5e-9e28-8b5f8a940114", 
    "status"=>"PROCESSING", 
    "created_at"=>"2024-09-25T06:01:45.784113164Z", 
    "updated_at"=>"2024-09-25T06:01:45.926724840Z", 
    "from_account"=>"3300297004", 
    "to_account"=>"3300297042", 
    "amount"=>{
      "currency_code"=>"USD", 
      "value"=>"2500.00"
    }, 
    "memo"=>"Lockbox Sweep", 
    "links"=>[
      {
        "method"=>"GET", 
        "rel"=>"self", 
        "href"=>"https://uat.api.svb.com/v1/payment/account-transfers/6085f92a-a67f-4f5e-9e28-8b5f8a940114"
      }
    ]
  }
}
```

#### Get an account-to-account book transfer details
```ruby
client.get_transfer('6085f92a-a67f-4f5e-9e28-8b5f8a940114')
```
```ruby
{
  :code=>"200", 
  :data=>{
    "id"=>"6085f92a-a67f-4f5e-9e28-8b5f8a940114", 
    "status"=>"PROCESSING", 
    "created_at"=>"2024-09-25T06:01:45.784113Z", 
    "updated_at"=>"2024-09-25T06:01:45.926725Z", 
    "from_account"=>"3300297004", 
    "to_account"=>"3300297042", 
    "amount"=>{
      "currency_code"=>"USD", 
      "value"=>"2500.00"
    }, 
    "memo"=>"Lockbox Sweep", 
    "links"=>[
      {
        "method"=>"GET", 
        "rel"=>"self", 
        "href"=>"https://uat.api.svb.com/v1/payment/account-transfers/6085f92a-a67f-4f5e-9e28-8b5f8a940114"
      }
    ]
  }
}
```

#### Get a list of all account-to-account book transfers
```ruby
client.list_transfers
```
```ruby
{
  :code=>"200", 
  :data=>{
    "links"=>[
      {
        "method"=>"GET", 
        "rel"=>"self", 
        "href"=>"https://uat.api.svb.com/v1/payment/account-transfers/?offset=1&limit=1000"
      }
    ], 
    "items"=>[
      {
        "id"=>"6085f92a-a67f-4f5e-9e28-8b5f8a940114", 
        "status"=>"PROCESSING", 
        "created_at"=>"2024-09-25T06:01:45.784113Z", 
        "updated_at"=>"2024-09-25T06:01:45.926725Z", 
        "from_account"=>"3300297004", 
        "to_account"=>"3300297042", 
        "amount"=>{
          "currency_code"=>"USD", 
          "value"=>"2500.00"
        }, 
        "memo"=>"Lockbox Sweep", 
        "links"=>[
          {
            "method"=>"GET", 
            "rel"=>"self", 
            "href"=>"https://uat.api.svb.com/v1/payment/account-transfers/6085f92a-a67f-4f5e-9e28-8b5f8a940114"
          }
        ]
      }
    ], 
    "total_items"=>1, 
    "total_pages"=>1
  }
}
```

## Testing

First update `client_spec.rb` with your client id and secret. If you don't have it, contact SVB API support to get your client id and secret.

```ruby
let(:client_id) { '' }
let(:client_secret) { '' }
```

To run the tests, run the following command:

```
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub.