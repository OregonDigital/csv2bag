require 'rdf'

module MappingMethods
  module Rights
    ODLICENSES = 
      [
        { :title => "Public Domain Mark",
          :uri => RDF::URI('http://creativecommons.org/publicdomain/mark/1.0/') },
        { :title => "Creative Commons CC0 Universal Public Domain",
          :uri => RDF::URI('http://creativecommons.org/publicdomain/zero/1.0/') }, 
        { :title => "Creative Commons - Attribution (BY)",
          :uri => RDF::URI('http://creativecommons.org/licenses/by/4.0/') },
        { :title => "Creative Commons - Attribution, ShareAlike (BY-SA)",
          :uri => RDF::URI('http://creativecommons.org/licenses/by-sa/4.0/') },
        { :title => "Creative Commons - Attribution, No Derivatives (BY-ND)",
          :uri => RDF::URI(' http://creativecommons.org/licenses/by-nd/4.0/') },
        { :title => "Creative Commons - Attribution, Non-Commercial (BY-NC)",
          :uri => RDF::URI('http://creativecommons.org/licenses/by-nc/4.0/') },
        { :title => "Creative Commons - Attribution, Non-Commercial, ShareAlike (BY-NC-SA)",
          :uri => RDF::URI('http://creativecommons.org/licenses/by-nc-sa/4.0/') },
        { :title => "Creative Commons - Attribution, Non-Commercial, No Derivatives (BY-NC-ND)",
          :uri => RDF::URI('http://creativecommons.org/licenses/by-nc-nd/4.0/') },
        { :title => "Educational Use Permitted",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/educational/') },
        { :title => "Rights Reserved - Free Access",
          :uri => RDF::URI('http://www.europeana.eu/rights/rr-f/') },
        { :title => "Rights Reserved - Restricted Access",
          :uri => RDF::URI('http://www.europeana.eu/rights/rr-r/') },
        { :title => "Orphan Works",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/orphan-work-us/') },
        { :title => "Unknown",
          :uri => RDF::URI('http://www.europeana.eu/rights/unknown/') }
      ]

    def rights(subject, data)
      graph = RDF::Graph.new
      rightsURI = ""

      if data.include?('http')
        # Check if URI matches allowed license URIs
        ODLICENSES.each do |odlicense|
          rightsURI << odlicense[:uri] if RDF::URI(data) == odlicense[:uri]
        end

        if rightsURI.to_s.empty? then @log.error("Rights URI does not match any acceptable licenses: " + data) end
      else
        # Check if text matches allowed license title
        ODLICENSES.each do |odlicense|
          rightsURI << odlicense[:uri] if data == odlicense[:title]
        end

        if rightsURI.to_s.empty? then @log.error("Rights text does not match any acceptable licenses: " + data) end
      end

      if !rightsURI.to_s.empty?
        graph << RDF::Statement(subject, RDF::Vocab::DC.rights, RDF::URI(rightsURI))
      end

      @log.info("Rights URI = " + rightsURI)

      graph
    end
  end
end
