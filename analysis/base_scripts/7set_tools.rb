# create energy plus run
wf.addJob(OpenStudio::Runmanager::JobType.new("EnergyPlus"))

# find Energy Plus v8.1 on the machine
ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,1)
ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
ep_parent_path = ep_path.parent_path()

# add the tools to the workflow
# makeTools (const openstudio::path &t_energyplus, const openstudio::path &t_xmlpreproc, const openstudio::path &t_radiance, const openstudio::path &t_ruby, const openstudio::path &t_dakota)
tools = OpenStudio::Runmanager::ConfigOptions::makeTools(ep_parent_path, OpenStudio::Path.new(), OpenStudio::Path.new(), $OpenStudio_RubyExeDir, OpenStudio::Path.new())
wf.add(tools)
wf.addParam(OpenStudio::Runmanager::JobParam.new("flatoutdir"))