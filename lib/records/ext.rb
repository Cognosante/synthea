module SyntheaExt
  PATIENTS = Synthea::Config.ext&.patients_json ? JSON.parse(File.read("ext/patients.json")) : []
end
