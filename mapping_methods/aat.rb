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
        "Apron" => "http://vocab.getty.edu/aat/300046131",  # aprons (protective wear)
        "Ascot" => "http://vocab.getty.edu/aat/300210052",  
        "Barrette" => "http://vocab.getty.edu/aat/300209295",  # barrettes (hair ornaments)
        "Basket" => "http://vocab.getty.edu/aat/300194498",  # baskets (containers)
        "Bathing suit" => "http://vocab.getty.edu/aat/300129420",  # bathing suits
        "Beaded Bag" => "http://vocab.getty.edu/aat/300198926",  # bags (costume accessories)
        "Bedspread" => "http://vocab.getty.edu/aat/300197889",  # bedspreads
        "Belt" => "http://vocab.getty.edu/aat/300210002",  # belts (costume accessories)
        "Belt Buckle" => "http://vocab.getty.edu/aat/300375281",  
        "Blouse" => "http://vocab.getty.edu/aat/300046133",   # blouses (main garments)
        "Boa" => "http://vocab.getty.edu/aat/300215870",  # boas (neckpieces)
        "Bodice" => "http://vocab.getty.edu/aat/300209874",  # bodices
        "Bonnet" => "http://vocab.getty.edu/aat/300210720",  # bonnets (hats)
        "Boots" => "http://vocab.getty.edu/aat/300046057",   # boots (footwear)
        "Bow" => "http://vocab.getty.edu/aat/300210057",  # bow ties
        "Bra" => "http://vocab.getty.edu/aat/300210538",  # brassieres
        "Brocade" => "http://vocab.getty.edu/aat/300227779",  # brocade (textile)
        "Bustle" => "http://vocab.getty.edu/aat/300210580",  # bustles
        "Calotte" => "http://vocab.getty.edu/aat/300046125",   # skullcaps (caps) [calottes (headgear) is alternate]
        "Caftan" => "http://vocab.getty.edu/aat/300046139",  # caftans
        "Camisole" => "http://vocab.getty.edu/aat/300210541",   # camisoles (underbodices)
        "Cap" => "http://vocab.getty.edu/aat/300046094",  # caps (headgear)
        "Cape" => "http://vocab.getty.edu/aat/300046140",  # capes (outerwear)
        "Cardigan" => "http://vocab.getty.edu/aat/300209880",  # cardigans
        "Ceremonial Apparel" => "http://vocab.getty.edu/aat/300210387",  # ceremonial costume
        "Chasuble" => "http://vocab.getty.edu/aat/300210424",  # chasubles (liturgical vestments)
        "Chatelaine" => "http://vocab.getty.edu/aat/300209297",  # chatelaines (clothing accessories)
        "Children's Wear" => "http://vocab.getty.edu/aat/300379348",   # childrenswear
        "Choli Blouse" => "http://vocab.getty.edu/aat/300209882",  # cholis
        "Cloche" => "http://vocab.getty.edu/aat/300210733",  # cloches (hats)
        "Clutch" => "http://vocab.getty.edu/aat/300256798",  # clutch bags
        "Coat" => "http://vocab.getty.edu/aat/300046143",  # coats (garments)
        "Crinoline" => "http://vocab.getty.edu/aat/300210554",  # crinolines
        "Curtains" => "http://vocab.getty.edu/aat/300037564",  # curtains (window hangings)
        "Cushion" => "http://vocab.getty.edu/aat/300236073",  # cushions
        "Detachable Collar" => "http://vocab.getty.edu/aat/300210058",  # collars (neckwear)
        "Detachable Skirt" => "http://vocab.getty.edu/aat/300209932",  # skirts (garments)
        "Dickey" => "http://vocab.getty.edu/aat/300210060",
        "Drawers" => "http://vocab.getty.edu/aat/300210555",   # drawers (underpants)
        "Dress" => "http://vocab.getty.edu/aat/300046159",   # dresses (garments)
        "Dress Ensemble" => "http://vocab.getty.edu/aat/300046159",   # dresses (garments)
        "Dressing gown" => "http://vocab.getty.edu/aat/300209947",   # dressing gowns
        "Ensemble" => "http://vocab.getty.edu/aat/300209844",   # ensembles (costume)
        "Evening dress" => "http://vocab.getty.edu/aat/300243843",  # evening dresses (garments)
        "Evening dress ensemble" => "http://vocab.getty.edu/aat/300243843",  # evening dresses (garments)
        "Evening gown" => "http://vocab.getty.edu/aat/300243843",   # evening dresses (garments)
        "Eyeglass Holder" => "http://vocab.getty.edu/aat/300225933",  # eyeglass cases
        "Fabric Sample" => "http://vocab.getty.edu/aat/300249430",   # swatches
        "Fan" => "http://vocab.getty.edu/aat/300258857",  # fans (costume accessories)
        "Feather(s)" => "http://vocab.getty.edu/aat/300011809",  # feather (material)
        "Girdle" => "http://vocab.getty.edu/aat/300210585",  # girdles (underwear)
        "Gloves" => "http://vocab.getty.edu/aat/300148821",  # gloves
        "Handbag" => "http://vocab.getty.edu/aat/300312361",  # handbags
        "Hair Comb" => "http://vocab.getty.edu/aat/300046265",  # combs (hair ornaments)
        "Hair Net" => "http://vocab.getty.edu/aat/300210861",  # hairnets
        "Halter Top" => "http://vocab.getty.edu/aat/300209885",  # halters (main garments)
        "Hand Muff" => "http://vocab.getty.edu/aat/300210014",  # muffs
        "Handkerchief" => "http://vocab.getty.edu/aat/300216195",  # handkerchiefs
        "Hat" => "http://vocab.getty.edu/aat/300046106",   # hats
        "Hat Pin" => "http://vocab.getty.edu/aat/300209304",  # hatpins
        "Head Scarf" => "http://vocab.getty.edu/aat/300256716",  # headscarves
        "Headband" => "http://vocab.getty.edu/aat/300046115",   # headbands (headgear)
        "Jabot" => "http://vocab.getty.edu/aat/300210062",
        "Jacket" => "http://vocab.getty.edu/aat/300046167",  # jackets (garments)
        "Jewelry" => "http://vocab.getty.edu/aat/300209286",
        "Jumper" => "http://vocab.getty.edu/aat/300046164",  # jumpers (dresses)
        "Lace" => "http://vocab.getty.edu/aat/300231662",  # needle lace
        "Loungewear" => "http://vocab.getty.edu/aat/300403908",   # loungewear
        "Main Garment" => "http://vocab.getty.edu/aat/300209263",   # main garments
        "Mary Janes" => "http://opaquenamespace.org/ns/workType/maryjanes",
        "Menswear" => "http://vocab.getty.edu/aat/300379341",  # menswear
        "Mules" => "http://vocab.getty.edu/aat/300216741",  # mules (shoes)
        "Napkin" => "http://vocab.getty.edu/aat/300216644",  # napkins (culinary textile)
        "Needle Book" => "http://vocab.getty.edu/aat/300023451",  # needle cases
        "Night Shirt" => "http://vocab.getty.edu/aat/300209952",   # nightshirts
        "Nightgown" => "http://vocab.getty.edu/aat/300046175",  # nightgowns
        "Outerwear" => "http://vocab.getty.edu/aat/300209265",   # outerwear 
        "Other" => "http://vocab.getty.edu/aat/300400513",  # other (information indicator)
        "Pamphlet" => "http://vocab.getty.edu/aat/300220572",
        "Panties" => "http://vocab.getty.edu/aat/300210563",  # panties (underpants)
        "Pants" => "http://vocab.getty.edu/aat/300209935",  # trousers
        "Pantsuit" => "http://vocab.getty.edu/aat/300046183",  # pantsuits
        "Parasol" => "http://vocab.getty.edu/aat/300046218",  # parasols (costume accessories)
        "Petticoat" => "http://vocab.getty.edu/aat/300209927",  # petticoats (underskirts)
        "Photograph" => "http://vocab.getty.edu/aat/300046300",
        "Pillbox" => "http://vocab.getty.edu/aat/300046109",   # pillboxes (hats)
        "Placemat" => "http://vocab.getty.edu/aat/300204964",  # placemats
        "Platform Sandal" => "http://opaquenamespace.org/ns/workType/platformsandal",
        "Pouch" => "http://vocab.getty.edu/aat/300194553",  # pouches
        "Pumps" => "http://vocab.getty.edu/aat/300210043",   # pumps (shoes)
        "Purse" => "http://vocab.getty.edu/aat/300046219",  # purses (ladies' accessories)
        "Reticule" => "http://vocab.getty.edu/aat/300216942",  # reticules
        "Robe" => "http://vocab.getty.edu/aat/300209852",  # robes (main garments)
        "Rug" => "http://vocab.getty.edu/aat/300185749",  # rugs (textiles)
        "Saddle Bag" => "http://vocab.getty.edu/aat/300237746",  # saddlebags (containers)
        "Sandals" => "http://vocab.getty.edu/aat/300046077",  # sandals
        "Sari" => "http://vocab.getty.edu/aat/300209858",  # saris (garments)
        "Sarong" => "http://vocab.getty.edu/aat/300209928",
        "Sash" => "http://vocab.getty.edu/aat/300216864",  # sashes (costume accessories)
        "Scarf" => "http://vocab.getty.edu/aat/300046123",  # scarves (costume accessories)
        "Sewing Kit" => "http://vocab.getty.edu/aat/300247545",  # sewing tools and equipment
        "Shawl" => "http://vocab.getty.edu/aat/300209991",   # shawls
        "Shirt" => "http://vocab.getty.edu/aat/300212499",  # shirts (main garments)
        "Shoes" => "http://vocab.getty.edu/aat/300046065",   # shoes (footwear)
        "Skirt" => "http://vocab.getty.edu/aat/300209932",  # skirts (garments)
        "Skirt Lifter" => "http://vocab.getty.edu/aat/300395573",
        "Skirt Suit" => "http://opaquenamespace.org/ns/workType/skirtsuit",
        "Skirt suit ensemble" => "http://vocab.getty.edu/aat/300411730",  # skirt suit
        "Sleeve Bands" => "http://vocab.getty.edu/aat/300210530",  # sleeves (costume)
        "Slip" => "http://vocab.getty.edu/aat/300210564",   # slips (underwear)
        "Slippers" => "http://vocab.getty.edu/aat/300046083",  # slippers (shoes)
        "Spats" => "http://vocab.getty.edu/aat/300210047",
        "Stilettos" => "http://vocab.getty.edu/aat/300210043",   # pumps (shoes)
        "Suit" => "http://vocab.getty.edu/aat/300209863",  # suits (main garments)
        "Sweater" => "http://vocab.getty.edu/aat/300209900",  # sweaters
        "Swimsuit" => "http://vocab.getty.edu/aat/300129420",  # bathing suits
        "Swimwear" => "http://vocab.getty.edu/aat/300129420",   # bathing suits
        "T-strap Shoe" => "http://opaquenamespace.org/ns/workType/tstrapshoes",
        "Table Cover" => "http://vocab.getty.edu/aat/300204971",   # tea cloths
        "Table Scarf" => "http://vocab.getty.edu/aat/300204971",   # tea cloths
        "Tapestry" => "http://vocab.getty.edu/aat/300205002",
        "Tea Cloth" => "http://vocab.getty.edu/aat/300204971",   # tea cloths
        "Textile or Textile fragment" => "http://vocab.getty.edu/aat/300014063",   # textiles (visual works)
        "Textile Panel" => "http://opaquenamespace.org/ns/workType/textilepanel",
        "Tie" => "http://vocab.getty.edu/aat/300210068",  # neckties
        "Tool" => "http://vocab.getty.edu/aat/300024841", 
        "Toque" => "http://vocab.getty.edu/aat/300210812",  # toques (caps)
        "Towel" => "http://vocab.getty.edu/aat/300216632",  # towels
        "Trim" => "http://vocab.getty.edu/aat/300183798",  # trimming (material)
        "Turban" => "http://vocab.getty.edu/aat/300046127",  # turbans
        "Undergarment" => "http://vocab.getty.edu/aat/300209267",   # underwear
        "Upholstery Fabric" => "http://vocab.getty.edu/aat/300204906",  # upholstery components
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
