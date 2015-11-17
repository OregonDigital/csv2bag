require 'rdf'
module Qa; end
require 'qa/authorities/web_service_base'
require 'qa/authorities/loc'

module MappingMethods
  module Creator

    def name_cache
      unless @name_cache
        if File.exist?("cache_names.yml")
          @name_cache = YAML.load(File.read("cache_names.yml"))
          @log.info("Loading #{@name_cache.length} entries from Name Cache")
        end
      end
      @name_cache ||= {}
    end

    # Search authorities for name. Cache should have already been checked.
    def name_search(data)
      authority = Qa::Authorities::Loc.new

      Array(data.split(';')).each do |creator_name|
        creator_name.strip!
        creator_name.gsub!('"', "")
        next if creator_name.gsub("-","") == ""

        @log.debug("Name split: " + creator_name)

        begin
          uri = authority.search("#{creator_name}", "names").find{|x| x["label"].strip.downcase == creator_name.downcase} ||
            authority.search("#{creator_name}", "subjects").find{|x| x["label"].strip.downcase == creator_name.downcase} #|| 
#            MappingMethods::Lcsh::name_uri_from_opaquens("#{creator_name}")
        rescue StandardError => e
          puts e
        end

        uri ||= ""

        if !uri.nil? && uri != ""
          parsed_uri = uri["id"].gsub("info:lc", "http://id.loc.gov")
          @log.info("Creator Result found for " + creator_name + ": " + parsed_uri)
          name_cache[creator_name] = {:uri => RDF::URI(parsed_uri), :label => creator_name}
        else
          @log.warn "No Creator found for #{creator_name}"
          name_cache[creator_name] = {:uri => creator_name, :label => creator_name}
        end

        File.open("cache_names.yml", 'w') do |f|
          f.write name_cache.to_yaml
        end

        name_cache
      end
    end

    # Main creator method. Checks name cache, does lookup if no cache hit. Can accept other predicates.
    def creator(subject, data, predicate=RDF::Vocab::DC11.creator)
      @log.debug("Creator: " + data)

      graph = RDF::Graph.new

      Array(data.split(';')).each do |name|
        name.strip!

        unless name_cache.include? name
          begin
            name_search(name)
          rescue => e
            puts subject, name, e.backtrace
          end
        end

        if name_cache[name][:uri].to_s.include?('http')
          graph << RDF::Statement.new(subject, predicate, name_cache[name][:uri])
        else
          @log.warn("Name URI not found: " + name)
          graph << RDF::Statement.new(subject, predicate, name)
        end
      end

      graph
    end

    # Use same creator code with contributor predicate
    def contributor(subject, data)
      creator(subject, data, RDF::Vocab::DC11.contributor)
    end

  end
end
