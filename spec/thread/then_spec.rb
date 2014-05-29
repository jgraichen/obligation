require 'spec_helper'

describe Obligation do
  context 'with threaded environment:' do
    describe 'then dataflow:' do
      it 'should let data flow' do
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

        expect(Time.now - start).to be > 0.2
        expect(result).to eq 1337
      end

      it 'should inherit error on reject' do
        o1 = Obligation.create do |w|
          Thread.new do
            w.reject RuntimeError.new 'ERR'
          end
        end

        o2 = o1.then do |result|
          result - 5
        end

        expect { o2.value }.to raise_error Obligation::RejectedError

        begin
          o2.value
        rescue Obligation::RejectedError => err
          error = err
        end

        expect(error.cause).to be_a RuntimeError
        expect(error.cause.message).to eq 'ERR'
      end
    end
  end
end
