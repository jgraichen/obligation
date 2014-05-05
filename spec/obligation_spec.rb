require 'spec_helper'

describe Obligation do

  it 'should allow to wait on background thread computation' do
    o, w = Obligation.create

    Thread.new do
      sleep 0.2
      w.fulfill 42
    end

    start  = Time.now
    result = o.value

    expect(Time.now - start).to be_within(0.1).of(0.2)
    expect(result).to eq 42
  end
end
