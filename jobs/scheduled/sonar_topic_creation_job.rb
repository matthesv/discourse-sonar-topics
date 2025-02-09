module ::DiscourseSonarTopics
    class SonarTopicCreationJob < ::Jobs::Scheduled
      every 1.hour
  
      def execute(args)
        return unless SiteSetting.sonar_topics_enabled
  
        api_key = SiteSetting.sonar_api_key
        model   = SiteSetting.sonar_model
        prompt  = SiteSetting.sonar_prompt
  
        include_domains = SiteSetting.sonar_include_domains
        exclude_domains = SiteSetting.sonar_exclude_domains
        recency_filter = SiteSetting.sonar_recency_filter
  
        client = DiscourseSonarTopics::SonarApiClient.new(
          api_key: api_key,
          model: model,
          prompt: prompt,
          include_domains: include_domains,
          exclude_domains: exclude_domains,
          recency_filter: recency_filter
        )
  
        topic = client.generate_topic
  
        if topic[:content].present?
          begin
            PostCreator.create!(Discourse.system_user,
              title: topic[:title],
              raw: topic[:content],
              skip_validations: true
            )
          rescue => e
            Rails.logger.error("SonarTopicCreationJob Fehler beim Erstellen des Themas: #{e.message}")
          end
        else
          Rails.logger.error("SonarTopicCreationJob: Leerer Inhalt generiert, Thema wird nicht erstellt.")
        end
      end
    end
  end
  