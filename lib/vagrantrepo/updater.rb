require 'digest'
require 'json'

module Vagrantrepo
  # Generate metadata based on the found boxes and previous information.
  class Updater
    DEFAULT_META_TEMPLATE = '%<boxname>s/index.json.new'.freeze
    DEFAULT_ROOT = '.'.freeze
    DEFAULT_OUTPUT_PATH = '.'.freeze

    CHECKSUM_TYPE = 'sha1'.freeze
    BUFFER_SIZE = 32_768

    def default_basic_meta(boxname)
      {
        'description' => "Box #{boxname}",
        'short_description' => "Box #{boxname}",
        'name' => "#{@vendor}/#{boxname}",
        'versions' => {},
      }
    end

    def initialize(box_meta, vagrant_meta, options)
      @box_meta = box_meta
      @vagrant_meta = vagrant_meta
      @root = options[:root] || DEFAULT_ROOT
      @vendor = options[:vendor]
      @output_path = options[:output] || DEFAULT_OUTPUT_PATH
      @url = options[:url].gsub(%r{/$}, '')
      @output_meta_template = options[:output_meta_template] || @meta_template
      @purge = options[:purge] || false
      @fields = options[:meta_field] || {}
      @logger = options[:logger] || Logger.new(nil)
    end

    def update
      @box_meta.each_key do |boxname|
        @logger.info("Updating vagrant manifest for #{boxname}")
        meta = basic_box_meta(boxname)
        vagrant_versions = meta.delete('versions')
        meta['versions'] = box_versions_meta(boxname, vagrant_versions)
        write_meta(boxname, meta)
      end
    end

    private def write_meta(boxname, meta)
      meta['versions'].each_value do |k|
        k['providers'] = hash_hash_to_array('name', k['providers']) if k['providers']
      end
      meta['versions'] = hash_hash_to_array('version', meta['versions'])
      filename = format(@output_meta_template, boxname: boxname)
      Dir.chdir(@output_path) do
        @logger.debug("writing to #{filename}")
        File.open(filename, 'w') do |file|
          file.write(JSON.pretty_generate(meta))
        end
      end
    end

    private def basic_box_meta(boxname)
      # use defaults
      # enhance with upstream / exclude versions
      # overwrite with meta fields
      meta = default_basic_meta(boxname)
      if @vagrant_meta.fetch(boxname, false)
        update_vagrant = @vagrant_meta[boxname].clone
        meta.update(update_vagrant)
      end
      meta.update(@fields.clone) if @fields
      meta['name'] = "#{@vendor}/#{boxname}"
      meta
    end

    private def box_versions_meta(boxname, vagrant_versions)
      # collect versions to keep (purge?)
      # calculate new versions (not in collected versions yet)
      versions_meta = {}

      unless @purge
        @logger.debug('Parsing current vagrant versions into the meta')
        vagrant_versions = vagrant_versions.nil? ? {} : array_hash_to_hash('version', vagrant_versions)
        vagrant_versions.each_value do |versions|
          if versions['providers']
            providers = versions.delete('providers')
            versions['providers'] = array_hash_to_hash('name', providers)
          end
        end
        versions_meta.update(vagrant_versions)
      end
      @logger.debug('Version meta before adding detected boxes:')
      @logger.ap(versions_meta)

      @box_meta[boxname].each do |version, providers|
        providers.each do |provider, boxfile|
          versions_meta[version] ||= {}
          versions_meta[version]['providers'] ||= {}
          versions_meta[version]['providers'][provider] ||= { 'name' => provider }
          prov_meta = versions_meta[version]['providers'][provider]
          @logger.debug("#{boxname} / #{version} / #{provider}")
          @logger.ap prov_meta

          unless prov_meta.fetch('checksum', false) && prov_meta.fetch('checksum_type', false)
            checksum_data = box_checksum(boxfile)
            prov_meta.update(checksum_data)
          end
          prov_meta['url'] = format_url(boxfile)
        end
      end
      versions_meta
    end

    # converts an array of hashes to a hash with subhashes using a key in each hash
    # as the new id. json loving people and their [{}] stuff.
    private def array_hash_to_hash(key, arr)
      arraylike = arr.map { |v| [v[key], v] }
      Hash[arraylike]
    end

    private def hash_hash_to_array(key, hash)
      hash.collect { |k, y| y.update(key => k) }
    end

    private def format_url(boxfile)
      "#{@url}/#{boxfile}"
    end

    private def box_checksum(filename, checksum_type = CHECKSUM_TYPE)
      checksum = nil
      Dir.chdir(@root) do
        case checksum_type.to_s.downcase
        when 'sha1'
          checksum = sha1_sum(filename)
        else
          raise Exception, "checksum type (#{checksum_type}) not supported."
        end
      end
      { 'checksum_type' => checksum_type, 'checksum' => checksum }
    end

    private def sha1_sum(filename)
      @logger.debug("calculate sha1 sum for #{filename}")
      digest = Digest::SHA1.new
      file = File.open(filename)
      while (buffer = file.read(BUFFER_SIZE))
        digest.update(buffer)
      end
      checksum = digest.hexdigest
      @logger.debug("calculated sha1 sum for #{filename}")
      checksum
    end
  end
end
