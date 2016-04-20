require 'rdf'
require 'sparql/client'

module MappingMethods
  module AAT

    def aat_cache
      unless @aat_cache
        if File.exist?("cache/aat_cache.yml")
          @aat_cache = YAML.load(File.read("cache/aat_cache.yml"))
          @log.info "Loading #{@aat_cache.length} entries from AAT cache"
        end
      end
      @aat_cache ||= {}
    end

    def aat_search(str)
      str = str.downcase

      return aat_cache[str][:uri] if aat_cache.include?(str)

      uri ||= ""

      begin
        @log.info("Searching AAT for: " + str)
        sparql = SPARQL::Client.new("http://vocab.getty.edu/sparql")
        q = "select distinct ?subj {?subj skos:prefLabel|skos:altLabel ?label. filter(str(?label)=\"#{str}\")}"
        result = sparql.query(q, :content_type => "application/sparql-results+json")

        solution = result.first
        uri = solution[:subj] if solution
      rescue => e
        puts str, e.message, e.backtrace
      end

      @log.debug("AAT Result URI: " + uri.to_s)

      if !uri.to_s.empty?
        @log.info("AAT Result found for " + str + ": " + uri.to_s)
        aat_cache[str] = {:uri => RDF::URI(uri), :label => str}
      else
        @log.warn("No AAT found for #{str}") unless aat_cache.include?(str)
        aat_cache[str] = {:uri => str, :label => str}
      end

      File.open("cache/aat_cache.yml", 'w') do |f|
        f.write aat_cache.to_yaml
      end

      uri
    end

    def aat_from_search(subject, data)
      graph = RDF::Graph.new
      data = data.split(";")
      Array(data).each do |type|
        @log.debug("AAT split: " + type)
        filtered_type = type_match[filtered_type] if type_match.include?(filtered_type)
        uri = aat_search(type)

        if uri.kind_of? RDF::URI
          graph << RDF::Statement.new(subject, RDF.type, uri)
        else
          @log.warn("No AAT URI for #{type}")
        end
      end

      graph
    end

    def type_match
      {
        "slides" => "slides (photographs)",
        "negatives" => "negatives (photographic)",
        "book illustrations" => "illustrations (layout features)",
        "programs" => "programs (documents)",
        "letters" => "letters (correspondence)",
        "cyanotypes" => "cyanotypes (photographic prints)",
        "fillms" => "films",
        "mezzotint" => "mezzotints (prints)",
        "relief" => "relief print",
        "intaglio" => "intaglio prints",
        "reproduction" => "reproductions",
        "monotypes" => "monotypes (planographic prints)",
        "aquatint" => "aquatints (prints)",
      }
    end

  end

  # Workaround for frequent net connection errors with Getty sparql endpoint.
  def cached_types
    {
      'Silver gelatin prints' => '300128695',
      'Gelatin silver prints' => '300128695',
      'Postcards' => '300026816',
      'Color Slide' => '300128366',
      'Posters' => '300027221',
      'Halftone print' => '300154372',
      'Signs (Notices)' => '300213259',
      'Magazine covers' => '300215389',
      'Maps' => '300028094',
      'Emblems' => '300123036',
      'Ephemera' => '300028881',
      'Tickets' => '300027381',
      'Periodicals' => '300026657',
      'Envelopes' => '300197601',
      'Stereographs' => '300127197',
      'Photographic prints' => '300127104',
    }
  end


end
