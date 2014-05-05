require 'spec_helper'

describe Obligation do
  context 'with Threads' do
    it 'should allow to wait on background thread computation' do
      o, w = Obligation.create

      Thread.new do
        sleep 0.2
        w.fulfill 42
      end

      start  = Time.now
      result = o.value

      expect(result).to eq 42
      expect(Time.now - start).to be_within(0.1).of(0.2)
    end

    it 'should propagate rejection' do
      o = Obligation.create do |w|
        Thread.new do
          begin
            raise RuntimeError.new 'ERR'
          rescue => e
            w.reject e
          end
        end
      end

      expect{ o.value }.to raise_error Obligation::RejectedError

      begin
        o.value
      rescue Obligation::RejectedError => err
      end

      expect(err.cause).to be_a RuntimeError
      expect(err.cause.message).to eq 'ERR'
    end

    it 'should allow to define then-promise flow' do
      o1 = Obligation.create do |w|
        Thread.new do
          sleep 0.2
          w.fulfill 42
        end
      end

      o2 = o1.then do |result|
        result - 5
      end

      o3 = o2.then do |result|
        result + 1300
      end

      start  = Time.now
      result = o3.value

      expect(Time.now - start).to be_within(0.1).of(0.2)
      expect(result).to eq 1337
    end

    it 'should execute then-cbs on same thread' do
      o1 = Obligation.create do |w|
        Thread.new do
          sleep 0.2
          w.fulfill 42
        end
      end

      queue = Queue.new

      o2 = o1.then do |result|
        queue << Thread.current
        result - 5
      end

      o3 = o2.then do |result|
        queue << Thread.current
        result + 1300
      end

      start  = Time.now
      result = o3.value

      expect(Time.now - start).to be_within(0.1).of(0.2)
      expect(result).to eq 1337

      threads = queue.size.times.map{ queue.pop }
      expect(threads.uniq).to have(1).items
      expect(threads.uniq.first).to eq Thread.current
    end
  end
end
