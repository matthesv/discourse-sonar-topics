namespace :discourse_sonar_topics do
    desc "Manuell ausführen: Erzeugt ein Sonar-Thema"
    task create_topic: :environment do
      ::Jobs.enqueue(:sonar_topic_creation_job)
      puts "Sonar Topic Creation Job wurde in die Warteschlange eingereiht."
    end
  end
  