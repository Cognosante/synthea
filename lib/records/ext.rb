module SyntheaExt
  PATIENTS = Synthea::Config.ext&.patients_json ? JSON.parse(File.read(Synthea::Config.ext&.patients_json)) : []

  if Synthea::Config.ext&.genders
    PATIENTS = PATIENTS.select { |e| Synthea::Config.ext&.genders.include? e['properties']['gender'] }
  end
  
  # one-pass weighted random sampling of hash (v=>p)
  #  
  # https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-max_by
  # http://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf

  WRS = -> (freq) { freq.max_by { |_, weight| rand ** (1.0 / weight) }.first }

end
