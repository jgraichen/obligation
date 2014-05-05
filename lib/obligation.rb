require 'obligation/version'
require 'concurrent/event'

class Obligation
  class << self
    def create
      if block_given?
        new.tap do |ob|
          yield Writer.new(ob)
        end
      else
        ob = new
        [ob, Writer.new(ob)]
      end
    end
  end

  def initialize
    @state  = :pending
    @mutex  = Mutex.new
    @event  = Concurrent::Event.new
    @reason = nil
    @result = nil
  end

  def then
    return self unless block_given?

    Obligation.create do |w|
      add_callback do |result|
        w.fulfill yield result
      end
    end
  end

  def value(timeout = 5)
    @event.wait(timeout) if timeout != 0 && pending?
    @mutex.synchronize { @result }
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

  def reason
    @mutex.synchronize { @reason }
  end

  def state
    @mutex.synchronize { @state }
  end

  private

  def add_callback
    if @state == :fulfilled
      yield
    else
      callbacks << Proc.new
    end
  end

  def callbacks
    @callbacks ||= []
  end

  def _fulfill(result)
    @mutex.synchronize do
      @state  = :fulfilled
      @result = result
      @event.set
    end
  end

  def _reject(reason)
    @mutex.synchronize do
      @state  = :rejected
      @reason = reason
      @event.set
    end
  end

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
