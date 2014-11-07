# Exterior Wall Insulation and Finish System
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ExteriorWallInsulationandFinishSystem/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector
insul_tchkn = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("insul_tchkn",true)
insul_tchkn.setValue(4)
args << insul_tchkn 
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue
