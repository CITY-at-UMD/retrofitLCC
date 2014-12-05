# create a new job tree
jobtree = wf.create(outdir, model, epw);
#OpenStudio::Runmanager::JobFactory::optimizeJobTree(jobtree)

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
  assert(counts[999] == 1)
  end
end