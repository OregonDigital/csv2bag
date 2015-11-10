require 'json'
require 'linkeddata'
module Qa; end
require 'qa/authorities/web_service_base'
require 'qa/authorities/loc'

module MappingMethods
  module Subject

    def subject_cache
      unless @subject_cache
        if File.exist?("cache_subject.yml")
          @subject_cache = YAML.load(File.read("cache_subject.yml"))
          @log.info "Loading #{@subject_cache.length} entries from Subject Cache"
        end
      end
      @subject_cache ||= {}
    end

    def lcsh_search(str)
      authority = Qa::Authorities::Loc.new

      begin
        uri = authority.search("#{str}", "subjects").find{|x| x["label"].strip.downcase == str.downcase}
      rescue StandardError => e
        puts e
      end

      uri ||= ""

      @log.debug("LCSH Result URI: " + uri.to_s)

      if !uri.nil? && uri != ""
        parsed_uri = uri["id"].gsub("info:lc", "http://id.loc.gov")
        @log.info("Subject Result found for " + str + ": " + parsed_uri)
        subject_cache[str] = {:uri => RDF::URI(parsed_uri), :label => str}
      else
        @log.warn "No Subject found for #{str}" unless subject_cache.include?(str.downcase)
        subject_cache[str] = {:uri => str, :label => str}
      end

      File.open("cache_subject.yml", 'w') do |f|
        f.write subject_cache.to_yaml
      end

      subject_cache
    end

    # Main subject method. Searches cache, then if no hit tries LCSH.
    def subject(subject, data)
      graph = RDF::Graph.new

      Array(data.split(';')).each do |subject_name|
        subject_name.strip!
        subject_name.gsub!('"', "")
        next if subject_name.gsub("-","") == ""

        @log.debug("Subject split: " + subject_name)

        unless subject_cache.include? subject_name
          begin
            lcsh_search(subject_name)
          rescue => e
            puts subject, subject_name, e.backtrace
          end
        end

        # If no URI is found, use the fallback predicate for keywords
        if subject_cache[subject_name][:uri].to_s.include?('http')
          graph << RDF::Statement.new(subject, RDF::Vocab::DC.subject, subject_cache[subject_name][:uri])
        else
          @log.warn("Subject URI not found: " + subject_name)
          graph << RDF::Statement.new(subject, RDF::Vocab::DC11.subject, subject_name)
        end
      end

      graph
    end
  end
end
