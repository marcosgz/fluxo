# Fluxo

Provides a simple and powerful way to create operations service objects for complex workflows.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluxo'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install fluxo

## Usage

Minimal operation definition:
```ruby
class MyOperation < Fluxo::Operation
  def call!(**)
    Success(:ok)
  end
end
```

And then just use the opperation by calling:
```
result = MyOperation.call
result.success? # => true
result.value # => :ok
```

In order to execute an operation with parameters, you must first define list of attributes:

```ruby
class MyOperation < Fluxo::Operation
  attributes :param1, :param2

  def call!(param1:, param2:)
    Success(:ok)
  end
end
```

or use the shortcut for defining attributes:
```ruby
class MyOperation < Fluxo::Operation(:param1, :param2)
  def call!(param1:, param2:)
    Success(:ok)
  end
end
```

### Operation Result

The execution result of an operation is a `Fluxo::Result` object. There are three types of results:
* `:ok`: the operation was successful
* `:failure`: the operation failed
* `:exception`: the operation raised an error

Use the `Success` and `Failure` methods to create results accordingly.

```ruby
class AgeCheckOperation < Fluxo::Operation(:age)
  def call!(age:)
    age >= 18 ? Success('ok') : Failure('too young')
  end
end

result = AgeCheckOperation.call(age: 16) # #<Fluxo::Result @value="too young", @type=:failure>
result.success?                          # false
result.error?                            # false
result.failure?                          # true
result.value                             # "too young"

result = AgeCheckOperation.call(age: 18) # #<Fluxo::Result @value="ok", @type=:ok>
result.success?                          # true
result.error?                            # false
result.failure?                          # false
result.value                             # "ok"
```

The `result` also provides `on_success`, `on_failure` and `on_error` methods to define callbacks for the `:ok` and `:failure` results.

```ruby
AgeCheckOperation.call(age: 18)
  .on_success { |result| puts result.value }
  .on_failure { |_result| puts "Sorry, you are too young" }
```

You can also define multiple callbacks for the opportunity result. The callbacks are executed in the order they were defined. You can filter which callbacks are executed by specifying an identifier to the `Success(id) { }` or `Failure(id) { }` methods along with its value as a block.

```ruby
class AgeCategoriesOperation < Fluxo::Operation(:age)
  def call!(age:)
    case age
    when 0..14
      Failure(:child) { "Sorry, you are too young" }
    when 15..17
      Failure(:teenager) { "You are a teenager" }
    when 18..65
      Success(:adult) { "You are an adult" }
    else
      Success(:senior) { "You are a senior" }
    end
  end
end

AgeCategoriesOperation.call(age: 18) \
  .on_success { |_result| puts "Great, you are an adult" } \
  .on_success(:senior) { |_result| puts "Enjoy your retirement" } \
  .on_success(:adult, :senior) { |_result| puts "Allowed access" } \
  .on_failure { |_result| puts "Sorry, you are too young" } \
  .on_failure(:teenager) { |_result| puts "Almost there, you are a teenager" }
# The above example will print:
#   Great, you are an adult
#   Allowed access
```

### Operation Flow

Once things become more complex, you can use can define a `flow` with a list of steps to be executed:

```ruby
class ArithmeticOperation < Fluxo::Operation(:num)
  flow :normalize, :plus_one, :double, :square, :wrap

  def normalize(num:)
    Success(num: num.to_i)
  end

  def plus_one(num:)
    return Failure('cannot be zero') if num == 0

    Success(num: num + 1)
  end

  def double(num:)
    Success(num: num * 2)
  end

  def square(num:)
    Success(num: num * num)
  end

  def wrap(num:)
    Success(num)
  end
end

ArithmeticOperation.call(num: 1) \
  .on_success { |result| puts "Result: #{result.value}" }
# Result: 16
```

Notice that the value of each step is passed to the next step as an argument. And the last step is always the result of the operation.

By default you can only pass defined attributes to the steps. You may want to pass transient attributes to the steps. You can do this by specifying a `transient_attributes` option to the operation class:

```ruby
class CreateUserOperation < Fluxo::Operation(:name, :age)
  flow :build, :save

  def build(name:, age:)
    user = User.new(name: name, age: age)
    Success(user: user)
  end

  def save(user:, **)
    return Failure(user.errors) unless user.save

    Success(user: user)
  end
end
```

This is useful to make the flow data transparent to the operation. But you can also disable this by setting the `strict_transient_attributes` option to `false` under the Operation class or the global configuration.

```ruby
class CreateUserOperation < Fluxo::Operation(:name, :age)
  self.strict_transient_attributes = false
  # ...
end
# or globally
Fluxo.config do |config|
  config.strict_attributes = false
  config.strict_transient_attributes = false
end
# or even
Fluxo.config.strict_transient_attributes = false
```

### Operation Groups

Another very useful feature of Fluxo is the ability to group operations steps. Imagine that you want to execute a bunch of operations in a single transaction. You can do this by defining a the group method and specifying the steps to be executed in the group.

```ruby
class CreateUserOperation < Fluxo::Operation(:name, :email)
  transient_attributes :user, :profile

  flow :build, {transaction: %i[save_user save_profile]}, :enqueue_job

  private

  def transaction(**kwargs, &block)
    ActiveRecord::Base.transaction do
      result = block.call(**kwargs)
      raise(ActiveRecord::Rollback) unless result.success?
    end
    result
  end

  def build(name:, email:)
    user = User.new(name: name, email: email)
    Success(user: user)
  end

  def save_user(user:, **)
    return Failure(user.errors) unless user.save

    Success(user: user)
  end

  def save_profile(user:, **)
    UserProfile.create!(user: user)
    Success()
  end

  def enqueue_job(user:, **)
    UserJob.perform_later(user.id)

    Success(user)
  end
end
```

### Operation Validation

If you have the `ActiveModel` gem installed, you can use the `validations` method to define validations on the operation.

```ruby
class SubscribeOperation < Fluxo::Operation(:name, :email)
  validations do
    validates :name, presence: true
    validates :email, presence: true, format: { with: /\A[^@]+@[^@]+\z/ }
  end

  def call!(name:, email:)
    # ...
  end
end
```

### Configuration

```ruby
Fluxo.config do |config|
  config.wrap_falsey_result = false
  config.wrap_truthy_result = false
  config.strict_attributes = true
  config.strict_transient_attributes = true
  config.error_handlers << ->(result) { Honeybadger.notify(result.value) }
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/fluxo.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
