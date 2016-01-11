module Loga
  class RevisionStrategy
    DEFAULT_REVISION = 'unknown.sha'.freeze

    class << self
      def call(service_version)
        if service_version == :git
          fetch_from_git || read_from_file || DEFAULT_REVISION
        else
          service_version.strip
        end
      end

      def fetch_from_git
        sha1_hash = `git rev-parse --short HEAD`
        $CHILD_STATUS.exitstatus == 0 ? sha1_hash.strip : false
      end

      def read_from_file
        File.read('REVISION').strip
      rescue Errno::ENOENT
        false
      end
    end
  end
end
