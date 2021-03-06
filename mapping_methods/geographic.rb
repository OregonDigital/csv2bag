require 'rdf'
require 'rest-client'
require 'json'
require 'rdf/ntriples'
require 'rdf/raptor'
require 'yaml'

module MappingMethods
  module Geographic
    def geocache
      unless @geocache
        if File.exist?("cache_geo.yml")
          @geocache = YAML.load(File.read("cache_geo.yml"))
          @log.info "Loading #{@geocache.length} entries from Geo Cache"
        end
      end
      @geocache ||= {}
    end

    def geonames_search(str, extra_params={})
      str.slice! '(Ore.)'
      str.slice! '(Ore)'

      response = RestClient.get 'http://api.geonames.org/searchJSON', {:params => {:username => 'johnson_tom', :q => str, :maxRows => 1, :style => 'short'}.merge(extra_params)}
      response = JSON.parse(response)
      if response["totalResultsCount"] != 0
        uri = "http://sws.geonames.org/#{response['geonames'][0]['geonameId']}/"
        geocache[str] = {:uri => RDF::URI(uri), :label => response['geonames'][0]['name']}
      else
        geocache[str] = {:uri => str}
      end
      File.open("cache_geo.yml", 'w') do |f|
        f.write geocache.to_yaml
      end
      geocache
    end

    # Main geographic method. Checks cache, searches Geonames if no hit.
    def geographic(subject, data, predicate=RDF::Vocab::DC[:spatial], extra_params={})
      @log.debug("Geographic: " + data)

      graph = RDF::Graph.new

      Array(data.split(';')).each do |location|
        location.strip!
        next if location.empty?

        @log.debug("Geographic split: " + location)

        unless geocache.include? location
          begin
            geonames_search(location, extra_params)
          rescue => e
            puts subject, location, e.backtrace
          end
        end

        if geocache.include? location
          graph << RDF::Statement.new(subject, predicate, geocache[location][:uri])
        else
          @log.warn("Geographic URI not found: " + location)
#          graph << RDF::Statement.new(subject, predicate, location)
        end
      end

      graph
    end

    # Geographic search limited to Oregon
    def geographic_oregon(subject, data)
      geographic(subject, data, RDF::Vocab::DC[:spatial], {:adminCode1 => "OR", :countryBias => "US"})
    end

    # Geographic search limited to the United States
    def geographic_us(subject, data)
      geographic(subject, data, RDF::Vocab::DC[:spatial], {:countryBias => "US"})
    end

    # Geographic search, Place of Publication predicate
    def geographic_pup(subject, data)
      geographic(subject, data, RDF::URI("http://id.loc.gov/vocabulary/relators/pup"))
    end

    # Geographic search, Water Basin predicate
    def geographic_waterbasin(subject, data)
      data.gsub!(' Basin', '')
      geographic(subject, data, RDF::URI("http://opaquenamespace.org/ns/waterBasin"))
    end
  end
end
