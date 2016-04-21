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

    # Main AAT method. Defaults to predicate for Worktype
    def aat(subject, data, predicate=RDF.type)
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
          graph << RDF::Statement.new(subject, predicate, uri)
        else
          @log.warn("No AAT URI for #{type}")
        end
      end

      graph
    end

    # Use AAT method with Subject predicate
    def aat_subject(subject, data)
      aat(subject, data, RDF::DC.subject)
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
        "Undergarment" => "http://vocab.getty.edu/aat/300209267",   # underwear
        "Hat" => "http://vocab.getty.edu/aat/300046106",   # hats
        "Textile or Textile fragment" => "http://vocab.getty.edu/aat/300014063",   # textiles (visual works)
        "Main Garment" => "http://vocab.getty.edu/aat/300209263",   # main garments
        "Loungewear" => "http://vocab.getty.edu/aat/300403908",   # loungewear

        'Silver gelatin prints' => 'http://vocab.getty.edu/aat/300128695',
        'Gelatin silver prints' => 'http://vocab.getty.edu/aat/300128695',
        'Postcards' => 'http://vocab.getty.edu/aat/300026816',
        'Color Slide' => 'http://vocab.getty.edu/aat/300128366',
        'Posters' => 'http://vocab.getty.edu/aat/300027221',
        'Halftone print' => 'http://vocab.getty.edu/aat/300154372',
        'Signs (Notices)' => 'http://vocab.getty.edu/aat/300213259',
        'Magazine covers' => 'http://vocab.getty.edu/aat/300215389',
        'Maps' => 'http://vocab.getty.edu/aat/300028094',
        'Emblems' => 'http://vocab.getty.edu/aat/300123036',
        'Ephemera' => 'http://vocab.getty.edu/aat/300028881',
        'Tickets' => 'http://vocab.getty.edu/aat/300027381',
        'Periodicals' => 'http://vocab.getty.edu/aat/300026657',
        'Envelopes' => 'http://vocab.getty.edu/aat/300197601',
        'Stereographs' => 'http://vocab.getty.edu/aat/300127197',
        'Photographic prints' => 'http://vocab.getty.edu/aat/300127104',
      }
    end
  end
end
