module Synthea
  module Modules
    class ScheduleEncounter < Synthea::Rules

      rule :schedule_encounter, [:age], [] do |time, entity|
        unless entity[:scheduled_encounter]
          min_encounter_time = Synthea::Config.ext&.min_encounter_time || Synthea::Config.end_date-11.months
          max_encounter_time = Synthea::Config.ext&.max_encounter_time || Synthea::Config.end_date-1.month
          encounter_time = rand(min_encounter_time..max_encounter_time)
          entity.events.create(encounter_time, :perform_scheduled, :schedule_encounter)
          entity[:scheduled_encounter] = true
        end
      end

      rule :perform_scheduled, [:age], [] do |time, entity|
        if entity.alive?(time)
          unprocessed_events = entity.events.unprocessed_before(time, :perform_scheduled)
          unprocessed_events.each do |event|
            entity.events.process(event)
            entity[:perform_scheduled] = true
          end
        end
      end

    end
  end
end
