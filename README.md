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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hwslabs/hws-payment_operations_demo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
