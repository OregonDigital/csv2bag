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
        "Accessory - Other" => "http://vocab.getty.edu/aat/300251645",   # accessories (object genre)
        "Blouse" => "http://vocab.getty.edu/aat/300046133",   # blouses (main garments)
        "Boots" => "http://vocab.getty.edu/aat/300046057",   # boots (footwear)
        "Camisole" => "http://vocab.getty.edu/aat/300210541",   # camisoles (underbodices)
        "Cap" => "http://vocab.getty.edu/aat/300046094",  # caps (headgear)
        "Calotte" => "http://vocab.getty.edu/aat/300046125",   # skullcaps (caps) [calottes (headgear) is alternate]
        "Ceremonial Apparel" => "http://vocab.getty.edu/aat/300210387",  # ceremonial costume 
        "Children's Wear" => "http://vocab.getty.edu/aat/300379348",   # childrenswear 
        "Cloche" => "http://vocab.getty.edu/aat/300210733",  # cloches (hats)
        "Coat" => "http://vocab.getty.edu/aat/300046143",  # coats (garments)
        "Cushion" => "http://vocab.getty.edu/aat/300236073",  # cushions
        "Drawers" => "http://vocab.getty.edu/aat/300210555",   # drawers (underpants)
        "Dress" => "http://vocab.getty.edu/aat/300046159",   # dresses (garments)
        "Dress Ensemble" => "http://vocab.getty.edu/aat/300046159",   # dresses (garments)
        "Dressing gown" => "http://vocab.getty.edu/aat/300209947",   # dressing gowns
        "Ensemble" => "http://vocab.getty.edu/aat/300209844",   # ensembles (costume)
        "Evening dress" => "http://vocab.getty.edu/aat/300243843",  # evening dresses (garments)
        "Evening dress ensemble" => "http://vocab.getty.edu/aat/300243843",  # evening dresses (garments)
        "Evening gown" => "http://vocab.getty.edu/aat/300243843",   # evening dresses (garments)
        "Handbag" => "http://vocab.getty.edu/aat/300312361",  # handbags
        "Hair Net" => "http://vocab.getty.edu/aat/300210861",  # hairnets
        "Hat" => "http://vocab.getty.edu/aat/300046106",   # hats
        "Headband" => "http://vocab.getty.edu/aat/300046115",   # headbands (headgear)
        "Jacket" => "http://vocab.getty.edu/aat/300046167",  # jackets (garments)
        "Loungewear" => "http://vocab.getty.edu/aat/300403908",   # loungewear
        "Main Garment" => "http://vocab.getty.edu/aat/300209263",   # main garments
        "Night Shirt" => "http://vocab.getty.edu/aat/300209952",   # nightshirts
        "Mary Janes" => "http://opaquenamespace.org/ns/workType/maryjanes",
        "Mules" => "http://vocab.getty.edu/aat/300216741",  # mules (shoes)
        "Outerwear" => "http://vocab.getty.edu/aat/300209265",   # outerwear 
        "Other" => "http://vocab.getty.edu/aat/300400513",  # other (information indicator)
        "Pantsuit" => "http://vocab.getty.edu/aat/300046183",  # pantsuits
        "Pillbox" => "http://vocab.getty.edu/aat/300046109",   # pillboxes (hats)
        "Platform Sandal" => "http://opaquenamespace.org/ns/workType/platformsandal",
        "Pumps" => "http://vocab.getty.edu/aat/300210043",   # pumps (shoes)
        "Purse" => "http://vocab.getty.edu/aat/300046219",  # purses (ladies' accessories)
        "Reticule" => "http://vocab.getty.edu/aat/300216942",  # reticules
        "Robe" => "http://vocab.getty.edu/aat/300209852",  # robes (main garments)
        "Sandals" => "http://vocab.getty.edu/aat/300046077",  # sandals
        "Shoes" => "http://vocab.getty.edu/aat/300046065",   # shoes (footwear)
        "Skirt" => "http://vocab.getty.edu/aat/300209932",  # skirts (garments)
        "Skirt Suit" => "http://opaquenamespace.org/ns/workType/skirtsuit",
        "Sleeve Bands" => "http://vocab.getty.edu/aat/300210530",  # sleeves (costume)
        "Slip" => "http://vocab.getty.edu/aat/300210564",   # slips (underwear)
        "Slippers" => "http://vocab.getty.edu/aat/300046083",  # slippers (shoes)
        "Stilettos" => "http://vocab.getty.edu/aat/300210043",   # pumps (shoes)
        "Sweater" => "http://vocab.getty.edu/aat/300209900",  # sweaters
        "T-strap Shoe" => "http://opaquenamespace.org/ns/workType/tstrapshoes",
        "Table Cover" => "http://vocab.getty.edu/aat/300204971",   # tea cloths
        "Table Scarf" => "http://vocab.getty.edu/aat/300204971",   # tea cloths
        "Textile or Textile fragment" => "http://vocab.getty.edu/aat/300014063",   # textiles (visual works)
        "Textile Panel" => "http://opaquenamespace.org/ns/workType/textilepanel",
        "Toque" => "http://vocab.getty.edu/aat/300210812",  # toques (caps)
        "Turban" => "http://vocab.getty.edu/aat/300046127",  # turbans
        "Undergarment" => "http://vocab.getty.edu/aat/300209267",   # underwear
        "Veil" => "http://vocab.getty.edu/aat/300046128",  # veils (headcloths)
        "Vest" => "http://vocab.getty.edu/aat/300209904",  # vests (garments)
        "Wall Hanging" => "http://vocab.getty.edu/aat/300204886",  # wall hangings
        "Wedding Dress" => "http://vocab.getty.edu/aat/300255177",  # wedding dresses
        "Wrap" => "http://vocab.getty.edu/aat/300220742",  # dolmans (mantles)


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
