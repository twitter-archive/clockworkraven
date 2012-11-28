class CreateMCQuestionOptionToResponseJoinTable < ActiveRecord::Migration
  def change
    create_table :mc_question_options_mc_question_responses, :id => false do |t|
      t.references :mc_question_option, :null => false
      t.references :mc_question_response, :null => false
    end

    add_index(:mc_question_options_mc_question_responses, [:mc_question_option_id, :mc_question_response_id], :unique => true, :name => :mc_q_opt_resp_idx)
  end
end
