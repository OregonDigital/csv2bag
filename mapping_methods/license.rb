require 'rdf'

module MappingMethods
  module License
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
      ]

    def license(subject, data)
      graph = RDF::Graph.new
      licenseURI = ""

      if data.include?('http')
        # Check if URI matches allowed license URIs
        ODLICENSES.each do |odlicense|
          licenseURI << odlicense[:uri] if RDF::URI(data) == odlicense[:uri]
        end

        if licenseURI.to_s.empty? then @log.error("License URI does not match any acceptable value: " + data) end
      else
        # Check if text matches allowed license title
        ODLICENSES.each do |odlicense|
          licenseURI << odlicense[:uri] if data == odlicense[:title]
        end

        if licenseURI.to_s.empty? then @log.error("License text does not match any acceptable value: " + data) end
      end

      if !licenseURI.to_s.empty?
        graph << RDF::Statement(subject, RDF::Vocab::CC.license, RDF::URI(licenseURI))
      end

      @log.info("License URI = " + licenseURI)

      graph
    end
  end
end
