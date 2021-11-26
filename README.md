# Hws::PaymentOperationsDemo

This is a demo orchestration using Hypto's primitives and connector libraries. This orchestration at the moment supports the below functionalities.

**Virtual Accounts**:
- Create a Virtual account
- Activate / Deactivate a virtual account
- Track balance of a virtual account.
- Track Incoming credits into virtual accounts via webhook.

**Payouts**:
- Transfer funds to a beneficiary using NEFT, IMPS, RTGS or UPI.
- Refresh status of a transaction.
- Update transaction status based on webhooks

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hws-payment_operations_demo'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install hws-payment_operations_demo

## Setup
1. Add `hws-payment_operations_demo` as dependency to the Gemfile.

```ruby
gem hws-payment_operations_demo
```

2. Inject the necessary migrations by executing the generator:

```bash
rails generate hws:payment_operations_demo:install
```

3. Setup the required underlying instruments by following instructions from [hws-instruments-ruby#setup](https://github.com/hwslabs/hws-instruments-ruby#setup)

## Usage

### **Create a virtual account:**

```ruby
Hws::PaymentOperationsDemo::VirtualAccount.create(name: '', description: '')

=> #<Hws::PaymentOperationsDemo::VirtualAccount:0x00005590ef001268 @instrument=#<Hws::Instruments::Models::Instrument id: "5fb8fd0e-65f4...", ..., value: {"va_num"=>"HYPTOUAT70809083146145", "account_ifsc"=>"YESB0CMSNOC", ...}, ...>, @store=#<Hws::PaymentOperationsDemo::TransactionalValueStore:0x00005590ef0012e0 @store_id="61bf460f-24cc..."...>>
```

### **Create an instance of `Hws::PaymentOperationsDemo::VirtualAccount`:**

This object can be used to perform operations on a virtual account.

```ruby
Hws::PaymentOperationsDemo::VirtualAccount.of('<va_acc_num>')
```

### **Activate a virtual account:**

```ruby
virtual_account_obj = Hws::PaymentOperationsDemo::VirtualAccount.of('<va_acc_num>')
virtual_account_obj.activate
```

### **Deactivate a virtual account:**

```ruby
virtual_account_obj.deactivate
```

### **Fetch balance of a virtual account:**
```ruby
virtual_account_obj.balance
```

### **Transfer Funds (Payout):**
```ruby
virtual_account_obj.transfer_funds(amount: 100, payment_type: 'UPI', beneficiary: {upi_id: 'upi_id@bank'})
```
**Supported payment types:** `NEFT`, `IMPS`, `RTGS` and `UPI`

**Structure of beneficiary:**

  For payment types: `NEFT`, `IMPS`, `RTGS` and `UPI`

    {account_number: '', account_ifsc: ''}

  For payment types: `UPI`

    {upi_id: ''}

### **Fetch transaction status:**

```ruby
Hws::PaymentOperationsDemo::VirtualAccount.fetch_transaction_status('reference_number')
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hwslabs/hws-payment_operations_demo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
