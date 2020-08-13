# frozen_string_literal: true

require 'indieauth_discovery/errors'

RSpec.describe IndieAuthDiscovery do
  describe IndieAuthDiscovery::Error do
    describe '#message' do
      subject(:error) { described_class.new('error', 'description', 'uri') }

      it 'includes the error' do
        expect(error.message).to match(/error/)
      end

      it 'includes the description' do
        expect(error.message).to match(/description/)
      end

      it 'includes the URI' do
        expect(error.message).to match(/uri/)
      end
    end
  end
end
