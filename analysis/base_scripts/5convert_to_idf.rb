# convert osm model to idf before adding energy plus measures
wf.addJob(OpenStudio::Runmanager::JobType.new("ModelToIdf"))