require 'rdf'

module MappingMethods
  module Rights
    ODRIGHTS =
      [
        { :title => "Educational Use Permitted",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/educational') },
        { :title => "Rights Reserved - Free Access",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/rr-f') },
        { :title => "Rights Reserved - Restricted Access",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/rr-r') },
        { :title => "Orphan Works",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/orphan-work-us') },
        { :title => "Unknown",
          :uri => RDF::URI('http://opaquenamespace.org/ns/rights/unknown') },

        { :label => 'COPYRIGHT NOT EVALUATED',
          :uri => RDF::URI('http://rightsstatements.org/vocab/CNE/1.0/') },
        { :label => 'IN COPYRIGHT - EDUCATIONAL USE PERMITTED',
          :uri => RDF::URI('http://rightsstatements.org/vocab/InC-EDU/1.0/') },
        { :label => 'IN COPYRIGHT - NON-COMMERCIAL USE PERMITTED',
          :uri => RDF::URI('http://rightsstatements.org/vocab/InC-NC/1.0/') },
        { :label => 'IN COPYRIGHT - EU ORPHAN WORK',
          :uri => RDF::URI('http://rightsstatements.org/vocab/InC-OW-EU/1.0/') },
        { :label => 'IN COPYRIGHT - RIGHTS-HOLDER(S) UNLOCATABLE OR UNIDENTIFIABLE',
          :uri => RDF::URI('http://rightsstatements.org/vocab/InC-RUU/1.0/') },
        { :label => 'IN COPYRIGHT',
          :uri => RDF::URI('http://rightsstatements.org/vocab/InC/1.0/') },
        { :label => 'NO KNOWN COPYRIGHT',
          :uri => RDF::URI('http://rightsstatements.org/vocab/NKC/1.0/') },
        { :label => 'NO COPYRIGHT - CONTRACTUAL RESTRICTIONS',
          :uri => RDF::URI('http://rightsstatements.org/vocab/NoC-CR/1.0/') },
        { :label => 'NO COPYRIGHT - NON-COMMERCIAL USE ONLY',
          :uri => RDF::URI('http://rightsstatements.org/vocab/NoC-NC/1.0/') },
        { :label => 'NO COPYRIGHT - OTHER KNOWN LEGAL RESTRICTIONS',
          :uri => RDF::URI('http://rightsstatements.org/vocab/NoC-OKLR/1.0/') },
        { :label => 'NO COPYRIGHT - UNITED STATES',
          :uri => RDF::URI('http://rightsstatements.org/vocab/NoC-US/1.0/') },
        { :label => 'COPYRIGHT UNDETERMINED',
          :uri => RDF::URI('http://rightsstatements.org/vocab/UND/1.0/') }
      ]

    def rights(subject, data)
      graph = RDF::Graph.new
      rightsURI = ""

      if data.include?('http')
        # Check if URI matches allowed rights URIs
        ODRIGHTS.each do |odrights|
          rightsURI << odrights[:uri] if RDF::URI(data) == odrights[:uri]
        end

        if rightsURI.to_s.empty? then @log.error("Rights URI does not match any acceptable value: " + data) end
      else
        # Check if text matches allowed license title
        ODRIGHTS.each do |odrights|
          rightsURI << odrights[:uri] if data == odrights[:title]
        end

        if rightsURI.to_s.empty? then @log.error("Rights text does not match any acceptable value: " + data) end
      end

      if !rightsURI.to_s.empty?
        graph << RDF::Statement(subject, RDF::Vocab::DC.rights, RDF::URI(rightsURI))
      end

      @log.info("Rights URI = " + rightsURI)

      graph
    end
  end
end
