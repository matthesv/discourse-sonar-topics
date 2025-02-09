module ::DiscourseSonarTopics
    class SonarTopicCreationJob < ::Jobs::Scheduled
      every 1.hour
  
      def execute(args)
        return unless SiteSetting.sonar_topics_enabled
  
        api_key = SiteSetting.sonar_api_key
        model   = SiteSetting.sonar_model
        prompt  = SiteSetting.sonar_prompt
  
        # Domains aus den Einstellungen auslesen
        include_domains = SiteSetting.sonar_include_domains.split(",").map(&:strip).reject(&:empty?)
        exclude_domains = SiteSetting.sonar_exclude_domains.split(",").map(&:strip).reject(&:empty?).map { |d| d.start_with?('-') ? d : "-#{d}" }
        # Kombinieren der beiden Listen; wenn keine Domains definiert sind, wird nil übergeben
        domain_filter = (include_domains + exclude_domains).presence
  
        # Aktualitätsfilter aus den Einstellungen
        recency_filter = SiteSetting.sonar_recency_filter.strip
            
        uri = URI.parse("https://api.perplexity.ai/chat/completions")
        headers = {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }
  
        payload = {
          "model" => model,
          "messages" => [
            {
              "role"    => "user",
              "content" => prompt
            }
          ],
          # Falls domain_filter definiert ist, übergeben wir diesen Parameter
          "search_domain_filter" => domain_filter,
          # Setze den Aktualitätsfilter (z.B. "month", "week", "day", "hour")
          "search_recency_filter" => recency_filter,
          "max_tokens"        => 0,
          "temperature"       => 0.7,
          "top_p"             => 0.9,
          "top_k"             => 0,
          "stream"            => false,
          "presence_penalty"  => 0,
          "frequency_penalty" => 0
        }
  
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri, headers)
          request.body = payload.to_json
  
          response = http.request(request)
          result = JSON.parse(response.body)
  
          if result["choices"] && result["choices"][0] &&
             result["choices"][0]["message"] && result["choices"][0]["message"]["content"]
  
            topic_content = result["choices"][0]["message"]["content"]
            title = "Automatisch generiertes Thema"  # Hier kannst du noch Logik ergänzen, um einen Titel abzuleiten
  
            PostCreator.create!(Discourse.system_user,
              title: title,
              raw: topic_content,
              skip_validations: true
            )
          end
        rescue => e
          Rails.logger.error("SonarTopicCreationJob Fehler: #{e}")
        end
      end
    end
  end
  