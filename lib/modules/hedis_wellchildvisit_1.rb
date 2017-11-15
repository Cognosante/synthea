module Synthea
  module Modules
    class HedisWellChildVisit1 < Synthea::Rules

      SKIP = {
        true => 0.75,
        false => 0.25
      }

      VARIANCE = {
        1.0 => 0.20,
        1.25 => 0.20,
        1.5 => 0.20,
        1.75 => 0.20,
        2.0 => 0.20
      }

      rule :encounter, [], [:schedule_encounter, :observations, :lab_results, :diagnoses, :immunizations] do |time, entity|
        if entity.alive?(time)
      
          unprocessed_events = entity.events.unprocessed_before(time, :encounter)          
          unprocessed_events.each do |event|
            entity.events.process(event)

            self.class.encounter(entity, event.time)

            Synthea::Modules::Generic.perform_wellness_encounter(entity, event.time)            

            entity.events.create(event.time, :encounter_ordered, :encounter)
          end
        end
      end

      rule :schedule_encounter, [:age], [:encounter] do |time, entity|
        if entity.alive?(time)
          unprocessed_events = entity.events.unprocessed_before(time, :encounter_ordered)
          unprocessed_events.each do |event|
            entity.events.process(event)
      
            age_in_years = entity[:age]

            if age_in_years >= 3
              delta = if age_in_years <= 19
                        1.year
                        elsif age_in_years <= 39
                        3.years
                        elsif age_in_years <= 49
                        2.years
                        else
                        1.year
                        end
            else

              birthdate = entity.event(:birth).time
              deathdate = entity.event(:death).try(:time)    
              age_in_months = Synthea::Modules::Lifecycle.age(time, birthdate, deathdate, :months)

              delta = if age_in_months <= 1
                        1.months
                      elsif age_in_months <= 5
                        2.months
                      elsif age_in_months <= 17
                        3.months
                      else
                        6.months
                      end
            end

            variance = SyntheaExt::WRS[VARIANCE]
            next_date = time + delta * variance

            if SyntheaExt::WRS[SKIP]
              entity.events.create(next_date, :encounter_ordered, :schedule_encounter)
            else
              entity.events.create(next_date, :encounter, :schedule_encounter)
            end
          end
        end
      end
  

      def self.encounter(entity, time, reason = nil)
        age = entity[:age]
        type = if age <= 1
                 :age_lt_1
               elsif age <= 4
                 :age_lt_4
               elsif age <= 11
                 :age_lt_11
               elsif age <= 17
                 :age_lt_17
               elsif age <= 39
                 :age_lt_39
               elsif age <= 64
                 :age_lt_64
               else
                 :age_senior
               end

        # find closest service provider
        encounter_data = ENCOUNTER_LOOKUP[type]
        service = encounter_data[:class]
        
        provider = Synthea::Provider.find_closest_service(entity, service)        
        # hash below is added as reference
        entity.add_current_provider('ruby_module_encounter_' + time.to_s, provider)
        provider.increment_encounters

        options = { reason: reason, provider: entity.ambulatory_provider }

        entity.record_synthea.encounter(type, time, options)
        # TODO: wellness encounters need their duration defined by the activities performed
        # the trouble is those activities are split among many modules
        entity.record_synthea.encounter_end(type, time + 1.hour)
      end
      
    end
  end
end
  