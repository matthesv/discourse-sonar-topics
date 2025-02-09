# name: discourse-sonar-topics
# about: Erzeugt automatisch Themen mithilfe der Sonar Perplexity API.
# version: 0.2.0
# authors: Matthes
# url: https://github.com/matthesv/discourse-sonar-topics

enabled_site_setting :sonar_topics_enabled

after_initialize do
  # Unsere Service-Klasse laden
  require_dependency File.expand_path("../lib/discourse-sonar-topics/sonar_api_client.rb", __dir__)

  # Lade Jobs und weitere Klassen
  load File.expand_path("../jobs/scheduled/sonar_topic_creation_job.rb", __FILE__)
end
