require 'spec_helper'
require 'stringio'
require 'json'

describe Loga::ContextLogger do
  %w(debug info warn error fatal).each do |method|
    describe "##{method}" do
      let(:current_method) { method }
      let(:formatter) do
        Loga::Formatters::GELFFormatter.new(
          service_name: 'test',
          service_version: 'test',
          host: 'test',
        )
      end

      def log_output_for(*args, &block)
        output = StringIO.new
        logger = described_class.new(output)

        logger.formatter = formatter

        logger.public_send(current_method, *args, &block)

        JSON.parse(output.string, symbolize_names: true)
      end

      it 'works with strings' do
        expect(log_output_for('This is my test'))
          .to include(short_message: 'This is my test')
      end

      it 'works with context' do
        expect(log_output_for('Hello', user_id: 123, name: 'Ivan'))
          .to include(short_message: 'Hello', _user_id: 123, _name: 'Ivan')
      end

      it 'works with progname and a block that returns string' do
        # XXX: prognames are ignored at the moment
        expect(log_output_for('Updating') { 'doing something' })
          .to include(short_message: 'doing something')
      end

      it 'works with progname and a block that returns string and data' do
        # XXX: prognames are ignored at the moment
        expect(log_output_for('Updating') { ['doing something', file: 'test.pdf'] })
          .to include(short_message: 'doing something', _file: 'test.pdf')
      end
    end
  end
end
