# name: discourse-sonar-topics
# about: Erzeugt automatisch Themen mithilfe der Sonar Perplexity API.
# version: 0.1.0
# authors: Dein Name
# url: https://github.com/deinusername/discourse-sonar-topics

enabled_site_setting :sonar_topics_enabled

after_initialize do
  # Hier werden unsere Jobs und weitere Klassen geladen.
  load File.expand_path("../jobs/scheduled/sonar_topic_creation_job.rb", __FILE__)
end
