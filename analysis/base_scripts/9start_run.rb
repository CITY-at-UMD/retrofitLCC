# create a new job tree
jobtree = wf.create(outdir, model_path, epw);
#OpenStudio::Runmanager::JobFactory::optimizeJobTree(jobtree)

# create a runmanager
run_manager = OpenStudio::Runmanager::RunManager.new(OpenStudio::tempDir() / OpenStudio::Path.new("runmanagerwatchertest.db"), true)
watcher = RunManagerWatcherImpl.new(run_manager)
run_manager.enqueue(jobtree, true) # run the job tree
#run_manager.showStatusDialog() # show status dialog
run_manager.waitForFinished() # wait until done

counts = watcher.finishedCounts
  assert(counts[OpenStudio::Runmanager::JobType.new("ModelToIdf").value] == 1)
  assert(counts[OpenStudio::Runmanager::JobType.new("EnergyPlus").value] == 1)
  # check to make sure exactly ONE *tree* finished
  assert(counts[999] == 1)
  end
end