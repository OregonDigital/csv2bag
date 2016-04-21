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

        if matched_uris.include?(type)
          uri = RDF::URI(matched_uris[type])
        else
          uri = aat_search(type)
        end

        if uri.kind_of? RDF::URI
          @log.info("AAT Result URI for #{type}: #{uri.to_s}")
          graph << RDF::Statement.new(subject, RDF.type, uri)
        else
          @log.warn("No AAT URI for #{type}")
        end
      end

      graph
    end

    # To avoid possible search lookup failures, can specify matched URIs here
    # This is checked before the cache.
    def matched_uris
      {
        "Blouse" => "http://vocab.getty.edu/aat/300046133",   # blouses (main garments)
        "Boots" => "http://vocab.getty.edu/aat/300046057",   # boots (footwear)
        "Camisole" => "http://vocab.getty.edu/aat/300210541",   # camisoles (underbodices)
        "Cap" => "http://vocab.getty.edu/aat/300046094",  # caps (headgear)
        "Calotte" => "http://vocab.getty.edu/aat/300046125",   # skullcaps (caps) [calottes (headgear) is alternate]
        "Drawers" => "http://vocab.getty.edu/aat/300210555",   # drawers (underpants)
        "Dress" => "http://vocab.getty.edu/aat/300046159",   # dresses (garments)
        "Evening gown" => "http://vocab.getty.edu/aat/300243843",   # evening dresses (garments)
        "Night Shirt" => "http://vocab.getty.edu/aat/300209952",   # nightshirts
        "Mary Janes" => "http://opaquenamespace.org/ns/workType/maryjanes",
        "Pillbox" => "http://vocab.getty.edu/aat/300046109",   # pillboxes (hats)
        "Platform Sandal" => "http://opaquenamespace.org/ns/workType/platformsandal",
        "Pumps" => "http://vocab.getty.edu/aat/300210043",   # pumps (shoes)
        "Shoes" => "http://vocab.getty.edu/aat/300046065",   # shoes (footwear)
        "Slip" => "http://vocab.getty.edu/aat/300210564",   # slips (underwear)
        "T-strap Shoe" => "http://opaquenamespace.org/ns/workType/tstrapshoes",
        "Textile Panel" => "http://opaquenamespace.org/ns/workType/textilepanel",
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
