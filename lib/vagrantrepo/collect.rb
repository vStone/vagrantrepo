require 'json'

module Vagrantrepo
  # Loop boxes, parse info into a hash.
  class Collect
    DEFAULT_BOX_REGEX = %r{^(?<boxname>[^\/]+)\/\k<boxname>-(?<version>[0-9.]+)-(?<provider>[a-z]+).box$}
    DEFAULT_META_TEMPLATE = '%<boxname>s/index.json'.freeze
    DEFAULT_FILTER = '**/*.box'.freeze
    DEFAULT_ROOT = '.'.freeze

    def initialize(options)
      @root = options[:root] || DEFAULT_ROOT
      @filter = options[:filter] || DEFAULT_FILTER
      @regex = options[:regex] || DEFAULT_BOX_REGEX
      @meta_template = options[:meta_template] || DEFAULT_META_TEMPLATE
      @logger = options[:logger] || Logger.new(nil)
    end

    # @return [Hash]
    def boxfile_meta
      @boxfile_meta ||= collect_boxfile_meta
    end

    # @return [Hash]
    def vagrant_meta
      @vagrant_meta ||= collect_vagrant_meta
    end

    # @param [String] boxname
    private def collect_box_vagrant_meta(boxname)
      filename = format(@meta_template, boxname: boxname)
      Dir.chdir(@root) do
        return {} unless File.file?(filename)
        return JSON.parse(File.read(filename))
      end
    end

    private def collect_vagrant_meta
      vagrant_meta = {}
      boxfile_meta.each_key do |boxname|
        vagrant_meta[boxname] = collect_box_vagrant_meta(boxname)
      end
      vagrant_meta
    end

    private def collect_boxfile_meta
      boxes_hash = {}
      Dir.chdir(@root) do
        Dir[@filter].each do |file|
          next if File.directory?(file)
          add_box_filename_information(boxes_hash, file)
        end
      end
      boxes_hash
    end

    private def add_box_filename_information(boxes_hash, file)
      match = @regex.match(file)
      if match
        boxname = match[:boxname]
        version = match[:version]
        boxes_hash[boxname] ||= {}
        boxes_hash[boxname][version] ||= {}
        boxes_hash[boxname][version][match[:provider]] = match[0]
      else
        @logger.warn("Unknown file #{file}. Skipping.")
      end
    end
  end
end
