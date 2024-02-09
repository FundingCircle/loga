# frozen_string_literal: true

shared_context 'gethostname', :with_hostname do
  let(:hostname) { 'bird.example.com' }

  before do
    allow(Socket).to receive(:gethostname).and_return(hostname)
  end
end
