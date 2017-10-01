shared_context 'gethostname', with_hostname: true do
  let(:hostname) { 'bird.example.com' }

  before do
    allow(Socket).to receive(:gethostname).and_return(hostname)
  end
end
