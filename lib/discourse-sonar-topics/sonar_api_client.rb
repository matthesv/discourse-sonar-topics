require 'net/http'
require 'uri'
require 'json'

module DiscourseSonarTopics
  class SonarApiClient
    API_ENDPOINT = "https://api.perplexity.ai/chat/completions"

    def initialize(api_key:, model:, prompt:, include_domains: nil, exclude_domains: nil, recency_filter: nil)
      @api_key = api_key
      @model = model
      @prompt = prompt
      @include_domains = include_domains
      @exclude_domains = exclude_domains
      @recency_filter = recency_filter
    end

    def generate_topic
      topic_text = call_api(@prompt)
      # Versuche, einen Titel und Inhalt aus der Antwort zu extrahieren
      title, content = extract_title_and_content(topic_text)

      # Falls kein Titel extrahiert werden konnte, einen zweiten API-Aufruf zur Titelerstellung durchführen
      if title.nil? || title.strip.empty?
        generated_title = generate_title(topic_text)
        title = generated_title unless generated_title.strip.empty?
      end

      # Fallback, falls weiterhin kein Titel vorhanden ist
      title = "Automatisch generiertes Thema" if title.nil? || title.strip.empty?
      
      { title: title.strip, content: content.strip }
    end

    private

    def call_api(prompt)
      uri = URI.parse(API_ENDPOINT)
      headers = {
        "Content-Type"  => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }

      # Domains verarbeiten
      include_domains_array = @include_domains.to_s.split(",").map(&:strip).reject(&:empty?)
      exclude_domains_array = @exclude_domains.to_s.split(",").map(&:strip).reject(&:empty?).map { |d| d.start_with?('-') ? d : "-#{d}" }
      domain_filter = (include_domains_array + exclude_domains_array).presence

      payload = {
        "model" => @model,
        "messages" => [
          {
            "role"    => "user",
            "content" => prompt
          }
        ],
        "max_tokens"        => 256,
        "temperature"       => 0.7,
        "top_p"             => 0.9,
        "top_k"             => 0,
        "stream"            => false,
        "presence_penalty"  => 0,
        "frequency_penalty" => 0
      }

      # Suchfilter hinzufügen, falls vorhanden
      payload["search_domain_filter"] = domain_filter if domain_filter
      payload["search_recency_filter"] = @recency_filter.to_s.strip if @recency_filter

      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = payload.to_json

        response = http.request(request)
        result = JSON.parse(response.body)
        if result["choices"] && result["choices"][0] && result["choices"][0]["message"] && result["choices"][0]["message"]["content"]
          return result["choices"][0]["message"]["content"]
        else
          Rails.logger.error("SonarApiClient: Ungültige Antwortstruktur: #{response.body}")
          return ""
        end
      rescue => e
        Rails.logger.error("SonarApiClient: API Aufruf Fehler: #{e.message}")
        return ""
      end
    end

    def extract_title_and_content(text)
      # Es wird angenommen, dass die API-Antwort eventuell in der ersten Zeile einen Titel liefert,
      # gefolgt von einer Leerzeile und anschließend dem Inhalt.
      lines = text.split("\n").map(&:strip).reject(&:empty?)
      return [nil, text] if lines.empty?
      
      if lines.size > 1
        title = lines.first
        content = lines[1..-1].join(" ")
        [title, content]
      else
        [nil, text]
      end
    end

    def generate_title(content)
      # Nutzt die API, um aus dem Inhalt einen prägnanten Titel zu generieren.
      title_prompt = "Erstelle einen prägnanten, ansprechenden Titel für das folgende Thema: #{content}"
      uri = URI.parse(API_ENDPOINT)
      headers = {
        "Content-Type"  => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }

      payload = {
        "model" => @model,
        "messages" => [
          {
            "role"    => "user",
            "content" => title_prompt
          }
        ],
        "max_tokens"        => 64,
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
        if result["choices"] && result["choices"][0] && result["choices"][0]["message"] && result["choices"][0]["message"]["content"]
          result["choices"][0]["message"]["content"].strip
        else
          Rails.logger.error("SonarApiClient (generate_title): Ungültige Antwortstruktur")
          ""
        end
      rescue => e
        Rails.logger.error("SonarApiClient (generate_title): Fehler beim Titelgenerieren: #{e.message}")
        ""
      end
    end
  end
end
