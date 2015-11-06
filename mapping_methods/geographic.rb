
require 'rdf'
require 'rest-client'
require 'json'
require 'rdf/ntriples'
require 'rdf/raptor'

module MappingMethods
  module Geographic
    def geocache
      @geocache ||= {}
    end

    def geonames_search(str, extra_params={})
      str.slice! '(Ore.)'
      str.slice! '(Ore)'
      response = RestClient.get 'http://api.geonames.org/searchJSON', {:params => {:username => 'johnson_tom', :q => str, :maxRows => 1, :style => 'short'}.merge(extra_params)}
      response = JSON.parse(response)
      if response["totalResultsCount"] != 0
        uri = "http://sws.geonames.org/#{response['geonames'][0]['geonameId']}/"
        geocache[str] = {:uri => RDF::URI(uri)}
      else
        geocache[str] = {:uri => str}
      end
    end

    def geographic_oe(subject, data)
      geographic(subject, data, RDF::Vocab::DC[:spatial], {:adminCode1 => "OR", :countryBias => "US"})
    end

    def geographic(subject, data, predicate=RDF::Vocab::DC[:spatial], extra_params={})
      data.slice!(';')
      data.strip!
      unless geocache.include? data
        begin
          geonames_search(data, extra_params)
        rescue => e
          puts subject, data, e.backtrace
        end
      end
      if geocache.include? data
        graph = RDF::Graph.new
        graph << RDF::Statement.new(subject, predicate, geocache[data][:uri])
        return graph#  << geonames_graph(geocache[data][:uri], data)
      else
        return RDF::Statement.new(subject, predicate, data)
      end
    end
    
    def geopup(subject, data)
      geographic(subject, RDF::URI("http://id.loc.gov/vocabulary/relators/pup"), data)
    end
  end
end
