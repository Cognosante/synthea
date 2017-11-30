module SyntheaExt
  patients = Synthea::Config.ext&.patients_json ? JSON.parse(File.read(Synthea::Config.ext&.patients_json)) : []

  if Synthea::Config.ext&.genders
    patients = patients.select { |e| Synthea::Config.ext&.genders.include? e['properties']['gender'] }
  end
  
  PATIENTS = patients

  providers = Synthea::Config.ext&.providers_json ? JSON.parse(File.read(Synthea::Config.ext&.providers_json)) : {}

  PROVIDERS = providers.select { |k,v| v['properties']['hie'] }
  
  # one-pass weighted random sampling of hash (v=>p)
  #  
  # https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-max_by
  # http://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf

  WRS = -> (freq) { freq.max_by { |_, weight| rand ** (1.0 / weight) }.first }

end
