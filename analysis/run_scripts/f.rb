# dependencies
require 'openstudio'
require 'openstudio/energyplus/find_energyplus'
require 'rubygems'
gem 'minitest'
require 'minitest/autorun'

#watcher
class RunManagerWatcherImpl < OpenStudio::Runmanager::RunManagerWatcher
  def initialize(runmanager)
  super
    @m_finishedCounts=[]
  end

  def finishedCounts
    return @m_finishedCounts
  end

  def jobFinishedDetails(t_jobId, t_jobType, t_lastRun, t_errors, t_outputFiles, t_inputParams, t_isMergedJob, t_mergedIntoJobId)
    #puts "JobFinished: #{t_jobId} #{t_jobType.valueName} #{t_lastRun} #{t_errors.succeeded} #{t_outputFiles.files.size} #{t_outputFiles.files.at(0).fullPath} #{t_inputParams.params.size} #{t_isMergedJob} #{t_mergedIntoJobId}\n"
	puts "Job Id:#{t_jobType.valueName}\nRun Time:#{t_lastRun}\nNo Errors?:#{t_errors.succeeded}\nNumber Files Output:#{t_outputFiles.files.size}\nFile Path:#{t_outputFiles.files.at(0).fullPath}\n"

    if not @m_finishedCounts[t_jobType.value]
      @m_finishedCounts[t_jobType.value] = 1
    else
      @m_finishedCounts[t_jobType.value] += 1
    end
  end

  def treeFinished(t_job)
    puts "\nTree Finished"
    if not @m_finishedCounts[999]
      @m_finishedCounts[999] = 1
    else
      @m_finishedCounts[999] += 1
    end
  end
  
end

class RunManagerWatcher_Test < MiniTest::Test
def test_RunManagerWatcher

# configure logging
osm = OpenStudio::Path.new("#{Dir.pwd}/model/exampleVirtualPULSEModel.osm"); # load osm file
epw = OpenStudio::Path.new("#{Dir.pwd}/weather/USA_PA_Philadelphia.Intl.AP.724080_TMY3.epw"); # set epw file location
wf = OpenStudio::Runmanager::Workflow.new();  # make a new workflow

dir = OpenStudio::Path.new("#{Dir.pwd}/measures/SetWindowtoWallRatiobyFacade"); # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir);  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new(); # make a new argument vector
wwr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("wwr"); # make a new double argument
wwr.setValue(0.9) # set value for this argument
args << wwr # add it to the arguments array
sillHeight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sillHeight");
sillHeight.setValue(0.2)
args << sillHeight
facade = OpenStudio::Ruleset::OSArgument::makeStringArgument("facade"); # make a new string argument
facade.setValue("North");
args << facade
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args); # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()); # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()); # set the measure as the first job in the queue
# convert osm model to idf before adding energy plus measures
wf.addJob(OpenStudio::Runmanager::JobType.new("ModelToIdf"));

dir = OpenStudio::Path.new("#{Dir.pwd}/energyplus_additions/AddEnvironmentalImpactFactors")                  
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()
reporting_frequency = OpenStudio::Ruleset::OSArgument::makeStringArgument("reporting_frequency")
reporting_frequency.setValue("RunPeriod")
args << reporting_frequency
electricity_region = OpenStudio::Ruleset::OSArgument::makeStringArgument("electricity_region")
electricity_region.setValue("National")
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

outdir = OpenStudio::Path.new("./run_scripts/results/f")

# create energy plus run
wf.addJob(OpenStudio::Runmanager::JobType.new("EnergyPlus"));

# find Energy Plus v8.1 on the machine
ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,1)
ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
ep_parent_path = ep_path.parent_path();

# add the tools to the workflow
tools = OpenStudio::Runmanager::ConfigOptions::makeTools(ep_parent_path, OpenStudio::Path.new(), OpenStudio::Path.new(), $OpenStudio_RubyExeDir, OpenStudio::Path.new(), OpenStudio::Path.new(),OpenStudio::Path.new(),OpenStudio::Path.new(),OpenStudio::Path.new(),OpenStudio::Path.new())
wf.add(tools)
wf.addParam(OpenStudio::Runmanager::JobParam.new("flatoutdir"))

# create a new job tree
jobtree = wf.create(outdir, osm, epw);
OpenStudio::Runmanager::JobFactory::optimizeJobTree(jobtree)

# create a runmanager
run_manager = OpenStudio::Runmanager::RunManager.new(OpenStudio::tempDir() / OpenStudio::Path.new("runmanagerwatchertest.db"), true)
watcher = RunManagerWatcherImpl.new(run_manager)

# run the job tree
run_manager.enqueue(jobtree, true)

# show status dialog
#run_manager.showStatusDialog()

# wait until done
run_manager.waitForFinished()

counts = watcher.finishedCounts
  assert(counts[OpenStudio::Runmanager::JobType.new("ModelToIdf").value] == 1)
  assert(counts[OpenStudio::Runmanager::JobType.new("EnergyPlus").value] == 1)
  # check to make sure exactly ONE *tree* finished
  assert(counts[999] == 1);
  end
end