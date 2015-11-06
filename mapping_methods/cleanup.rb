require 'rdf'

module MappingMethods
  module Cleanup

    def human_to_date(subject, human_date)

      # Attempts to convert the plain language formatted date into an ISO8601 formatted dct:date statement.
      # If the date refers to a range then oregon:earliestDate and oregon:latestDate statements are returned.
      statements = []

      if (year = /^(\d{4})$/.match(human_date))
        # Matches a 4-digit year: 1950.
        statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date), year[1]) # YYYY

      elsif (season = /^(circa|ca|summer|winter|fall|spring|early|late)(\.|,)*\s*(\d{4})$/i.match(human_date))
        # Matches Circa/season year: Spring 1930.
        statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date), season[3]) # YYYY

      elsif (year_range = /^(\d{4})'*s$/.match(human_date))
        # Matches a 4-digit year with "s" or "'s": 1940s or 1940's.
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['earliestDate']), "#{year_range[1][0,3]}0") # YYYY
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['latestDate']), "#{year_range[1][0,3]}9") # YYYY

      elsif (year_range = /^(circa|ca|c)\.*\s*(\d{4})'*s$/i.match(human_date))
        # Matches Circa/Ca + "s": Circa 1930s.
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['earliestDate']), "#{year_range[2][0,3]}0") # YYYY
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['latestDate']), "#{year_range[2][0,3]}9") # YYYY

      elsif (year_range = /^(ca|.*)\s*(\d{4})\s*.+\s*(\d{4})$/i.match(human_date))
        # Matches a year range: (Ca) 1960-1961.
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['earliestDate']), "#{year_range[2]}") # YYYY
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['latestDate']), "#{year_range[3]}") # YYYY

      elsif (year_range = /^(ca|.*)\.*\s*(\d{4})\s*-\s*(\d{2})$/i.match(human_date))
        # Matches a year range: (Ca) 1960-61.
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['earliestDate']), "#{year_range[2]}") # YYYY
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['latestDate']), "#{year_range[2][0,2]}#{year_range[3]}") # YYYY

      elsif (year_range = /^(\d{4})\s*-\s*(\d)$/.match(human_date))
        # Matches a year range: 1935-6.
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['earliestDate']), "#{year_range[1]}") # YYYY
        statements << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['latestDate']), "#{year_range[1][0,3]}#{year_range[2]}") # YYYY

      elsif (year_desc = /^(\d{4})\s+(\D*)$/.match(human_date))
        # Matches YEAR ... Description: 1941                                   Newport, OR Bayfront
        statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date), year_desc[1]) # YYYY
        # Special case: since some dates had additional descriptive material, a dct:description field is returned as well.
        statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.description), year_desc[2]) # Description

      elsif (mdy = /(\d{2})\/(\d{2})\/(\d{2})/.match(human_date))
        # Matches 05/12/45: 1954-05-12.
        statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date), "19#{mdy[3]}-#{mdy[1]}-#{mdy[2]}") # YYYY-MM-DD

      else
        begin
          # Try letting Date parser do the work and convert it to ISO8601.
          if /\D+(\d+),\s(\d{4})/.match(human_date)
            # Matches: July 4, 1963.
            d = Date.strptime(human_date, '%B %d, %Y')
            statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date),  d.strftime('%Y-%m-%d')) # YYYY-MM

          elsif /(\d+)\s\w+,\s*(\d{4})/.match(human_date)
            # Matches: 31 July, 1963.
            d = Date.strptime(human_date, '%d %B, %Y')
            statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date),  d.strftime('%Y-%m-%d')) # YYYY-MM

          elsif /\w+,\s*\d{4}/.match(human_date)
            # Matches: Month, Year.
            d = Date.strptime(human_date,'%B, %Y')
            statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date),  d.strftime('%Y-%m')) # YYYY-MM

          elsif /\w+\s*\d{4}/.match(human_date)
            # Matches: Month Year.
            d = Date.strptime(human_date,'%B %Y')
            statements << RDF::Statement.new(subject, RDF::URI.new(RDF::Vocab::DC.date),  d.strftime('%Y-%m')) # YYYY-MM

          end
        rescue ArgumentError
          @log.warn("#{__method__} :: Unable to parse date: #{human_date}")
        end
      end
      # printf("%-20s\n",human_date) # if xsd_dates.count == 0
      # statements.each {|stmt| printf("\t%-45s\t%s\n",stmt.predicate,stmt.object)}
      statements
    end

    def load_compound_objects(collection, graph, subject)
      begin
        # Get the id from 'replaces' object so we can retrieve the .cpd file.
        replaces = graph.query([nil, RDF::Vocab::DC.replaces, nil])
        cis_id = replaces.first.object.to_s.split("#{collection},").last
        cpd_url = "http://oregondigital.org/cgi-bin/showfile.exe?CISOROOT=/#{collection}&CISOPTR=#{cis_id}&filename=cpdfilename"
        cpd_file = RestClient.get cpd_url
        if 200 == cpd_file.code
          cpd_doc = Nokogiri::XML.parse(cpd_file)
          if cpd_doc.xpath('/cpd/page')
            # Pull out the individual 'page' element(s) from the .cpd and add them to the graph.
            pages = []
            first = nil
            last = nil
            cpd_doc.xpath('/cpd/page').each_with_index do |page, i|
              replaces_uri = RDF::URI.new("http://oregondigital.org/u?/#{collection},#{page.at_xpath('pageptr').text}")
              graph << RDF::Statement.new(subject, RDF::URI.new(@namespaces['oregon']['contents']), replaces_uri)
              cpd_node = RDF::Node.new
              graph << RDF::Statement.new(cpd_node, RDF::URI('http://www.openarchives.org/ore/1.0/datamodel#proxyFor'), replaces_uri)
              first = cpd_node if i == 0
              last = cpd_node
              pages << cpd_node
            end
            # Set the 'first' and 'last' terms for the parent object.
            graph << RDF::Statement.new(subject, RDF::URI('http://www.iana.org/assignments/relation/first'), first) unless first.nil?
            graph << RDF::Statement.new(subject, RDF::URI('http://www.iana.org/assignments/relation/last'), last) unless last.nil?

            # Set the 'next' term for each complex child object.
            pages.each_with_index do |pg, i|
              graph << RDF::Statement.new(pg, RDF::URI('http://www.iana.org/assignments/relation/next'), pages[i+1]) if i+1 < pages.count
            end
            # graph.each { |x| puts x.inspect}
          end
        else
          raise "Unexpected result code received: #{cpd_file.code}"
        end
      rescue => e
        @log.error("Error: #{e} getting RDF file: #{cpd_url}")
      end
      graph
    end

  end
end
