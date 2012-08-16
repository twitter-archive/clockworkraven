class ModifyJobsForResque < ActiveRecord::Migration
  def up
    add_column :evaluations, :job_id, 'integer unsigned'

    execute <<-SQL
      ALTER TABLE clockwork_raven_evaluations
        ADD CONSTRAINT fk_evaluations_jobs
        FOREIGN KEY (`job_id`)
        REFERENCES `clockwork_raven_jobs` (`id`)
    SQL

    remove_column :jobs, :completed
    remove_column :jobs, :total
    remove_column :jobs, :error
    remove_column :jobs, :status

    add_column :jobs, :resque_job, :string
  end

  def down
    remove_column :jobs, :reque_job

    add_column :jobs, :status, :integer
    add_column :jobs, :error, :text
    add_column :jobs, :total, :integer
    add_column :jobs, :completed, :integer


    execute <<-SQL
      ALTER TABLE clockwork_raven_evaluations
        DROP FOREIGN KEY fk_evaluations_jobs;
    SQL

    remove_column :evaluations, :job_id
  end
end
