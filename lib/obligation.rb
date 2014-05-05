require 'obligation/version'

# # Obligation
#
# An {Obligation} represent a future result. It allows to do other
# things while something is calculated in the background and wait
# for it's value when needed.
#
# This implementation also supports various kinds of callbacks and
# data flow specification to integration into thread, fibered as well
# as evented environments.
#
module Obligation

  # Execute given block with {Obligation} result.
  #
  # The moment of execution is not specified and MAY not be directly after
  # {Obligation} was fulfilled. Execution of the callback SHALL be on
  # same thread as the current.
  #
  # If callback returns an {Obligation} the outer returned {Obligation} MUST
  # wait on the returned one from the callback. This allows seamless
  # integration with any library using {Obligation}s to handle delayed
  # return values (see example 3).
  #
  # @example Simple data flow
  #   o1 = Obligation.create do |w|
  #     Thread.new do
  #       sleep 1 # Heavy calculation
  #       w.fulfill 42
  #     end
  #   end
  #
  #   o2 = o1.then do |result|
  #     result - 5 + 1300
  #   end
  #
  #   o2.value #=> 1337
  #
  # @example Callback with another Obligation
  #   o1 = Obligation.create do |w|
  #     Thread.new do
  #       sleep 1 # Heavy calculation
  #       w.fulfill 42
  #     end
  #   end
  #
  #   o2 = o1.then do |result|
  #     Obligation.create do |w|
  #       Thread.new do
  #         r.fulfill result.times.map do
  #           Net::HTTP.get('example.com', 'index.html')
  #         end
  #       end
  #     end
  #   end
  #
  #   o2.value #=> ["<html>...", "<html>...", ...]
  #
  # @example Seamless integration with any library using {Obligation}
  #   o1 = Obligation.create do |w|
  #     Thread.new do
  #       sleep 1 # Heavy calculation
  #       w.fulfill 42
  #     end
  #   end
  #
  #   o2 = o1.then do |result|
  #     HTTPLibUsingObligation.get("http://example.org/#{result}.html")
  #   end
  #
  #   o2.value #=> ["<html>..."]
  #
  # @yield [result] Yield {Obligation}s result after it is fulfilled.
  # @yieldparam result [Object] {Obligation} result.
  # @yieldreturn [Object|Obligation] The returned {Obligation}s result.
  #   If result is a {Obligation} the returned {Obligation} will wait
  #   on it's result.
  # @return [Obligation] {Obligation} for yielded result.
  #
  def then
    throw NotImplementedError.new 'Obligation#then not implemented.'
  end

  # Wait for {Obligation}'s result.
  #
  # This method MUST block the thread of fiber until either
  # the {Obligation} is fullfilled or the given timeout exceeds.
  #
  # If the {Obligation} is already fulfilled the result MUST
  # be returned instantly. An {RejectedError} MUST be raised when
  # {Obligation} is rejected and a {TimeoutError} when waiting
  # has timed out.
  #
  # @param timeout [Integer] Timeout to wait in seconds.
  # @return [Object] {Obligation}'s result if any. Nil if rejected
  #   or timed out.
  # @raise [RejectedError] Raised when {Obligation} is rejected.
  #   Raised error will contain reason as `#cause`.
  # @raise [TimeoutError] Raised when waiting on result has timed out.
  #
  def value(timeout)
    throw NotImplementedError.new 'Obligation#value not implemented.'
  end

  # Check if {Obligation} is fulfilled.
  #
  # @example
  #   o = Obligation.create do |w|
  #     Thread.new { sleep 1; w.fulfill 42 }
  #   end
  #
  #   o.fulfilled? #=> false
  #   o.value
  #   o.fulfilled? #=> true
  #
  # @return [Boolean] True if {Obligation} is fulfilled, false otherwise.
  #
  def fulfilled?
    throw NotImplementedError.new 'Obligation#fulfilled? not implemented.'
  end

  # Check if {Obligation} is pending e.g. neither fulfilled or rejected.
  #
  # @example
  #   o = Obligation.create do |w|
  #     Thread.new { sleep 1; w.fulfill 42 }
  #   end
  #
  #   o.pending? #=> true
  #   o.value
  #   o.pending? #=> false
  #
  # @return [Boolean] True if {Obligation} is pending, false otherwise.
  #
  def pending?
    throw NotImplementedError.new 'Obligation#pending? not implemented.'
  end

  # Check if {Obligation} is rejected.
  #
  # @example
  #   o = Obligation.create do |w|
  #     Thread.new { sleep 1; w.reject StandardError.new }
  #   end
  #
  #   o.rejected? #=> false
  #   o.value
  #   o.pending? #=> true
  #
  # @return [Boolean] True if {Obligation} is rejected, false otherwise.
  #
  def rejected?
    throw NotImplementedError.new 'Obligation#rejected? not implemented.'
  end

  # A {RejectedError} will be raised when {Obligation} is rejected
  # and someone tries to access the result.
  #
  class RejectedError < StandardError
    attr_reader :cause
    def initialize(msg, cause = $!)
      super msg
      @cause = cause
    end
  end

  # A {TimeoutError} will be raised when waiting for a result
  # has timed out.
  class TimeoutError < StandardError; end

  # A {StateError} will be raised when a obligation is tried to
  # fulfill or reject twice.
  class StateError < StandardError; end

  class << self
    def create(*args, &block)
      Impl.create(*args, &block)
    end

    def on(*obligations)
      Impl.on(*obligations)
    end
  end
end

require 'obligation/impl'
