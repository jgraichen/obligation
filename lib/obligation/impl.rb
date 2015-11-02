require 'concurrent/event'

module Obligation
  #
  class Base
    include Obligation

    def initialize
      @state  = :pending
      @mutex  = Mutex.new
      @event  = Concurrent::Event.new
      @reason = nil
    end

    def pending?
      state == :pending
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    def state
      @mutex.synchronize { @state }
    end

    def reason
      @mutex.synchronize { @reason }
    end

    def value(timeout = 30)
      _value(timeout)
    end

    def then
      return self unless block_given?

      Dependent.new(self, &Proc.new)
    end

    protected

    def _sync_pending?
      @state == :pending
    end

    def _fulfill(result)
      @mutex.synchronize { _sync_fulfill result }
    end

    def _sync_fulfill(result)
      if @state == :pending
        @state  = :fulfilled
        @result = result
        @event.set
      else
        raise StateError.new "Obligation already changed to #{@state}."
      end
    end

    def _reject(reason)
      @mutex.synchronize { _sync_reject reason }
    end

    def _sync_reject(reason)
      if @state == :pending
        @state  = :rejected
        @reason = reason
        @event.set
      else
        raise StateError.new "Obligation already changed to #{@state}."
      end
    end
  end

  #
  class Value < Base
    def initialize
      super

      @result = nil
    end

    protected

    def _value(timeout)
      @event.wait(timeout) if pending? && timeout != 0
      @mutex.synchronize do
        case @state
          when :fulfilled then @result
          when :rejected  then raise RejectedError.new \
            "Obligation rejected due to #{@reason}.", @reason
          else raise TimeoutError.new
        end
      end
    end

    #
    class Writer
      def initialize(obligation)
        @obligation = obligation
      end

      def fulfill(result)
        @obligation.send :_fulfill, result
      end

      def reject(reason)
        @obligation.send :_reject, reason
      end
    end
  end

  #
  class Dependent < Base
    def initialize(dependencies, &block)
      super()
      @dependencies = dependencies
      @block        = block
      @reason       = nil
      @result       = nil
    end

    protected

    def _value(timeout)
      @mutex.synchronize do
        if _sync_pending?
          begin
            _sync_fulfill @block.call _resolved_dependencies
          rescue RejectedError => e
            _sync_reject e.cause
            raise RejectedError.new "Obligation rejected due to #{e.cause}."
          end
        end

        case @state
          when :fulfilled then @result
          when :rejected  then raise RejectedError.new \
            "Obligation rejected due to #{@reason}.", @reason
        end
      end
    end

    def _resolved_dependencies
      return @dependencies.map(&:value) if @dependencies.is_a?(Array)

      @dependencies.value
    end
  end

  #
  module Impl
    class << self
      def create
        if block_given?
          Value.new.tap do |ob|
            yield Value::Writer.new(ob), ob
          end
        else
          ob = Value.new
          [ob, Value::Writer.new(ob)]
        end
      end
    end
  end
end
