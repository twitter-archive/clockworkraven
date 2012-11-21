class AddNumJudgesPerTaskToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :num_judges_per_task, :integer, :default => 1
  end
end
