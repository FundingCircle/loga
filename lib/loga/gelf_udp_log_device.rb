require 'socket'
require 'digest/md5'

module Loga
  class GELFUPDLogDevice
    attr_reader :host, :port, :max_chunk_size, :compress

    def initialize(options = {})
      @max_chunk_size = 1420
      # Enables zlib message compression
      @compress       = options.fetch(:compress, true)
      @socket         = UDPSocket.open
      @host           = options.fetch(:host, '127.0.0.1')
      @port           = options.fetch(:port, 12_201)
    end

    def close
      @socket.close
    end

    def write(message)
      data      = (compress ? Zlib::Deflate.deflate(message) : message).bytes
      datagrams = []

      if data.count > max_chunk_size
        id    = Digest::MD5.digest(SecureRandom.uuid)[0, 8]
        count = (data.count.to_f / max_chunk_size).ceil
        index = 0

        data.each_slice(max_chunk_size) do |slice|
          datagrams << "\x1e\x0f" + id + [index, count, *slice].pack('C*')
          index += 1
        end
      else
        datagrams << data.to_a.pack('C*')
      end

      datagrams.each do |datagram|
        socket.send(datagram, 0, host, port)
      end
    end

    private

    attr_reader :socket
  end
end
