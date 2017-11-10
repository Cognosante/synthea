module Synthea
  module Modules
    class HedisPrenatalCare1 < Synthea::Rules

      # from https://spacefem.com/pregnant/charts/duedate3.php
      BIRTH_AGE_WKS = {
        35	=> 0.014,
        36	=> 0.027,
        37	=> 0.064,
        38	=> 0.136,
        39	=> 0.255,
        40	=> 0.318,
        41	=> 0.162,
        42	=> 0.02,
        43	=> 0.004
      }
    
      # estimated from histogram in story 46315
      VISIT_AGE_WKS = {
        1  => 0,
        2  => 0,
        3  => 0,
        4  => 0,
        5  => 0.005,
        6  => 0.005,
        7  => 0.005,
        8  => 0.005,
        9  => 0.005,
        10 => 0.005,
        11 => 0.025,
        12 => 0.025,
        13 => 0.025,
        14 => 0.025,
        15 => 0.030,
        16 => 0.030,
        17 => 0.060,
        18 => 0.060,
        19 => 0.050,
        20 => 0.050,
        21 => 0.070,
        22 => 0.070,
        23 => 0.040,
        24 => 0.040,
        25 => 0.035,
        26 => 0.035,
        27 => 0.025,
        28 => 0.025,
        29 => 0.025,
        30 => 0.025,
        31 => 0.020,
        32 => 0.020,
        33 => 0.020,
        34 => 0.020,
        35 => 0.020,
        36 => 0.020,
        37 => 0.015,
        38 => 0.015,
        39 => 0.015,
        40 => 0.015,           
        50 => 0.030
      }
    
      rule :schedule_birth, [:age], [] do |time, entity|
        unless entity[:scheduled_birth]
          min_conception_time = Synthea::Config.ext&.min_encounter_time || Synthea::Config.end_date-59.months
          max_conception_time = Synthea::Config.ext&.max_encounter_time || Synthea::Config.end_date-1.month

          conception_time = rand(min_conception_time..max_conception_time)
          birth_time = conception_time + SyntheaExt::WRS[BIRTH_AGE_WKS].weeks
          visit_time = conception_time + SyntheaExt::WRS[VISIT_AGE_WKS].weeks
          ultrasound_time = [visit_time, conception_time+14.weeks].max + rand(1..21).days
          
          if visit_time < birth_time
            entity.events.create(visit_time, :perform_visit, :schedule_birth)
          end

          if ultrasound_time < birth_time
            entity[:gestational_age] = ((ultrasound_time - conception_time) / 1.week).to_i
            entity.events.create(ultrasound_time, :perform_ultrasound, :schedule_birth)          
          end

          entity.events.create(birth_time, :perform_birth, :schedule_birth)
          entity[:scheduled_birth] = true
        end

      end

      rule :perform_visit, [:age], [] do |time, entity|
        if entity.alive?(time)
          unprocessed_events = entity.events.unprocessed_before(time, :perform_visit)
          unprocessed_events.each do |event|
            entity.events.process(event)
            entity[:perform_visit] = true
          end
        end
      end

      rule :perform_ultrasound, [:age], [] do |time, entity|
        if entity.alive?(time)
          unprocessed_events = entity.events.unprocessed_before(time, :perform_ultrasound)
          unprocessed_events.each do |event|
            entity.events.process(event)
            entity[:perform_ultrasound] = true
          end
        end
      end

      rule :perform_birth, [:age], [] do |time, entity|
        if entity.alive?(time)
          unprocessed_events = entity.events.unprocessed_before(time, :perform_birth)
          unprocessed_events.each do |event|
            entity.events.process(event)
            entity[:perform_birth] = true
          end
        end
      end

    end
  end
end
