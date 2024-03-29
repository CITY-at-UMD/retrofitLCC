dir = OpenStudio::Path.new("#{Dir.pwd}/energyplus_additions/AddEnvironmentalImpactFactors")             
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()
reporting_frequency = OpenStudio::Ruleset::OSArgument::makeStringArgument("reporting_frequency")
reporting_frequency.setValue("RunPeriod")
args << reporting_frequency
electricity_region = OpenStudio::Ruleset::OSArgument::makeStringArgument("electricity_region")
electricity_region.setValue("Eastern")
args << electricity_region
equipment = OpenStudio::Ruleset::OSArgument::makeStringArgument("equipment")
equipment.setValue("Commercial Boiler")
args << equipment
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args);
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath());
wf.addJob(rubyjobbuilder.toWorkItem());

dir = OpenStudio::Path.new("#{Dir.pwd}/energyplus_additions/AddUtilityRates")                  
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()
elec_tar = OpenStudio::Ruleset::OSArgument::makeStringArgument("elec_tar")
elec_tar.setValue("PECO Rates")
args << elec_tar
gas_tar = OpenStudio::Ruleset::OSArgument::makeStringArgument("gas_tar")
gas_tar.setValue("PGW Rates")
args << gas_tar
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args);
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath());
wf.addJob(rubyjobbuilder.toWorkItem());

dir = OpenStudio::Path.new("#{Dir.pwd}/energyplus_additions/AddSummaryReport")                  
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()
reports_request = OpenStudio::Ruleset::OSArgument::makeStringArgument("reports_request")
reports_request.setValue("ZoneComponentLoadSummary")
args << reports_request
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args);
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath());
wf.addJob(rubyjobbuilder.toWorkItem());