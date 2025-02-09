# name: discourse-sonar-topics
# about: Erzeugt automatisch Themen mithilfe der Sonar Perplexity API.
# version: 0.2.0
# authors: Matthes
# url: https://github.com/deinusername/discourse-sonar-topics

enabled_site_setting :sonar_topics_enabled

after_initialize do
  # Lade die Service-Klasse aus dem lib-Verzeichnis (relativer Pfad korrekt gesetzt)
  require_dependency File.expand_path("lib/discourse-sonar-topics/sonar_api_client.rb", __dir__)

  # Lade den Scheduled Job (relativer Pfad korrekt gesetzt)
  load File.expand_path("jobs/scheduled/sonar_topic_creation_job.rb", __dir__)
end
