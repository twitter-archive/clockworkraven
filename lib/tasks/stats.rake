# Copyright 2012 Twitter, Inc. and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

namespace :raven do
  desc "Show some usage stats"
  task :stats, [:days] => :environment do |t, args|
    args.with_defaults(:days => '7')
    range = args[:days].to_i.days.ago..DateTime.now

    puts "In the past #{args[:days]} #{"day".pluralize(args[:days])}:"

    evals = Evaluation.where(:created_at => (range), :status => (1..4), :prod => true)
    puts "Evaluations run: #{evals.count}"

    eval_ids = evals.map(&:id)
    results = TaskResponse.joins(:task).where('clockwork_raven_tasks.evaluation_id' => eval_ids).count
    puts "Results gathered: #{results}"

    cents = TaskResponse.joins(:task => :evaluation).where('clockwork_raven_evaluations.id' => eval_ids).sum('clockwork_raven_evaluations.payment * 1.1')
    puts "Money spent: #{ActionController::Base.helpers.number_to_currency(cents / 100.0)}"

    puts "Average cost per result: #{ActionController::Base.helpers.number_to_currency((cents / results.to_f) / 100.0)}"

    workers = TaskResponse.joins(:task => :evaluation).where('clockwork_raven_evaluations.id' => eval_ids).count('DISTINCT m_turk_user_id')
    puts "Workers used: #{workers}"

    workers = TaskResponse.joins(:task => :evaluation).
                           where('clockwork_raven_evaluations.id' => eval_ids).
                           group(:m_turk_user_id).
                           select('m_turk_user_id, SUM(clockwork_raven_evaluations.payment) as payed, SUM(clockwork_raven_task_responses.work_duration) as time, COUNT(clockwork_raven_task_responses.id) AS count')

    workers.each do |worker|
      puts "#{worker.m_turk_user_id}: #{ActionController::Base.helpers.number_to_currency((worker.payed.to_f/100) / (worker.time.to_f / 3600))}/hr over #{worker.count} responses"
    end
  end
end