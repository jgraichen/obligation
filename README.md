# Obligation

Obligation is a support library to return promised, future results.

It is planned to support different concurrency models, like threads, EventMachine and EM + Fibers.

Note: Obliation DOES NOT implement concurrency, it can be used within library to return futures/promises that can then be used within different concurrency models.

Note: Pre-alpha library.

## Installation

As Obligation is made to be used as a support library you will most likely add it to your gemspec:

```ruby
  spec.add_runtime_dependency 'obligation', '~> 0.1'
```

## Usage

Within your library you can create an Obligation:

```ruby
def my_library_method
  obligation, writer = Obligation.create
```

Then return the `obligation` object and use the `writer` object to fulfill it somewhere in your concurrent library code:

```ruby
  Thread.new do
    sleep 1
    writer.fulfill 42
  end

  return obligation
end
```

A user of your library using e.g. threads can now use it like a future object:

```ruby
future = my_library_method

# Dome something else...

future.value # block until result is there
#=> 42
```

Obligation also supports a promise-like API:

```ruby
promise = my_library_method

p2 = promise.then do |p|
  p ** 2
end

p2.value #=> 84
```

It is also planned to implement more promise like API features like depending on multiple other promises like a data flow.

All these future and promise API functions will be made available on whatever concurrency model the user of your library uses, may it be threads or (not yet supported) EventMachine or Celluloid or Fibers.

See [Restify](https://github.com/jgraichen/restify) for a library using obligations.

## Contributing

1. Fork it ( http://github.com/jgraichen/obligation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit specs for your feature so that I do not break it later
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## License

Copyright (C) 2014 Jan Graichen

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
