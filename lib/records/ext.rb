module SyntheaExt
  PATIENTS = Synthea::Config.ext&.patients_json ? JSON.parse(File.read(Synthea::Config.ext&.patients_json)) : []
end
