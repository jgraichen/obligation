require 'spec_helper'

describe Obligation do
  context 'with threaded environment:' do
    describe 'get value:' do
      it 'should wait on fulfill' do
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

      it 'should be able to timeout' do
        o, _  = Obligation.create
        start = Time.now

        expect { o.value(0.5) }.to raise_error
        expect(Time.now - start).to be > 0.5
      end

      it 'should raise on reject' do
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
          error = err
        end

        expect(error.cause).to be_a RuntimeError
        expect(error.cause.message).to eq 'ERR'
      end
    end
  end
end
