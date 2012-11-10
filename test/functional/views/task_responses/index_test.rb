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

require 'test_helper'

class TaskResponsesIndexTest < ActionController::TestCase
  tests TaskResponsesController

  setup do
    login
    setup_data
  end

  test "Bar chart element present" do
    get_page
    assert_select '#bar_chart'
  end

  test "MC questions present as options to chart" do
    get_page
    assert_select ".chart-options input[value=#{@mc1.id}]"
    assert_select ".chart-options input[value=#{@mc2.id}]"
    assert_select ".chart-options:content(#{@mc1.label})"
    assert_select ".chart-options:content(#{@mc2.label})"
  end

  test "MC questions present as options to segment by" do
    get_page
    assert_select ".segment-options input[value=#{@mc1.id}]"
    assert_select ".segment-options input[value=#{@mc2.id}]"
    assert_select ".segment-options:content(#{@mc1.label})"
    assert_select ".segment-options:content(#{@mc2.label})"
  end

  test "MC questions present as filters" do
    get_page
    assert_select ".filter-pane h5:content(#{@mc1.label})"
    assert_select ".filter-pane input[value=#{@mc1_opt1.id}]"
    assert_select ".filter-pane input[value=#{@mc1_opt2.id}]"
    assert_select ".filter-pane input[value=#{@mc1_opt3.id}]"

    assert_select ".filter-pane h5:content(#{@mc2.label})"
    assert_select ".filter-pane input[value=#{@mc2_opt1.id}]"
    assert_select ".filter-pane input[value=#{@mc2_opt2.id}]"
    assert_select ".filter-pane input[value=#{@mc2_opt3.id}]"
  end

  test "MC Questions with average values present as display options" do
    get_page
    assert_select_none ".display-options input[value=#{@mc1.id}]"
    assert_select ".display-options input[value=#{@mc2.id}]"
    assert_select_none ".display-options:content(Average value of #{@mc1.label})"
    assert_select ".display-options:content(Average value of #{@mc2.label})"
  end

  test "approve button shown when eval unapproved" do
    @e.status = 2 # unapproved
    @e.save!
    get_page
    assert_select 'a:content("Approve All Unapproved Responses")'

    @e.status = 3 # approved
    @e.save!
    get_page
    assert_select_none 'a:content("Approve All Unapproved Responses")'
  end

  test "approve/reject buttons shown when approval is undecided" do
    @r1.approved = nil
    @r1.save!
    @r2.approved = true
    @r2.save!
    get_page

    # r1 should have approve/reject buttons
    assert_select 'tbody tr:first-child .approval-controls a:content("Approve")'
    assert_select 'tbody tr:first-child .approval-controls a:content("Reject")'

    # r2 shouldn't
    assert_select_none 'tbody tr:nth-child(2) .approval-controls a:content("Approve")'
    assert_select_none 'tbody tr:nth-child(2) .approval-controls a:content("Reject")'
  end

  test "ban/unban buttons" do
    @r1.m_turk_user.banned = true
    @r1.m_turk_user.save!
    @r2.m_turk_user.banned = false
    @r2.m_turk_user.save!
    get_page

    # r1 should have unban button
    assert_visible 'tbody tr:first-child .ban-controls a:content("Unban")'
    assert_hidden  'tbody tr:first-child .ban-controls a:content("Ban")'

    # r2 should have ban button
    assert_hidden  'tbody tr:nth-child(2) .ban-controls a:content("Unban")'
    assert_visible 'tbody tr:nth-child(2) .ban-controls a:content("Ban")'
  end

  test "trust/untrust buttons" do
    @r1.m_turk_user.trusted = true
    @r1.m_turk_user.save!
    @r2.m_turk_user.trusted = false
    @r2.m_turk_user.save!
    get_page

    # r1 should have untrust button
    assert_visible 'tbody tr:first-child .trust-controls a:content("Untrust")'
    assert_hidden  'tbody tr:first-child .trust-controls a:content("Trust")'

    # r2 should have trust button
    assert_hidden  'tbody tr:nth-child(2) .trust-controls a:content("Untrust")'
    assert_visible 'tbody tr:nth-child(2) .trust-controls a:content("Trust")'
  end

  test "responses shown in table" do
    get_page

    # check header content and order
    assert_select "thead th:nth-child(2):content('item1')"
    assert_select "thead th:nth-child(3):content('item2')"
    assert_select "thead th:nth-child(4):content('tweet')"
    assert_select "thead th:nth-child(5):content('metadata1')"
    assert_select "thead th:nth-child(6):content('metadata2')"
    assert_select "thead th:nth-child(7):content('#{@mc1.label}')"
    assert_select "thead th:nth-child(8):content('#{@mc2.label}')"
    assert_select "thead th:nth-child(9):content('#{@fr1.label}')"
    assert_select "thead th:nth-child(10):content('#{@fr2.label}')"

    # check first response
    task1_data = @e.task_responses.first.task.data
    assert_select "tbody tr:first-child td:nth-child(2):content('#{task1_data['item1']}')"
    assert_select "tbody tr:first-child td:nth-child(3):content('#{task1_data['item2']}')"
    assert_select "tbody tr:first-child td:nth-child(4):content('#{task1_data['tweet']}')"
    assert_select "tbody tr:first-child td:nth-child(5):content('#{task1_data['metadata1']}')"
    assert_select "tbody tr:first-child td:nth-child(6):content('#{task1_data['metadata2']}')"
    assert_select "tbody tr:first-child td:nth-child(7):content('#{@mc1_opt1.label}')"
    assert_select "tbody tr:first-child td:nth-child(8):content('#{@mc2_opt2.label}')"
    assert_select "tbody tr:first-child td:nth-child(9):content('response 1')"
    assert_select "tbody tr:first-child td:nth-child(10):content('response 2')"
    assert_select "tbody tr:first-child td:nth-child(11) a:content('#{@r1.m_turk_user_id}')"
    assert_select "tbody tr:first-child td:nth-child(12):content('10')"
    assert_select "tbody tr:first-child td:nth-child(13) .approval-status:content('Undecided')"

    # check second response
    task2_data = @e.task_responses.second.task.data
    assert_select "tbody tr:nth-child(2) td:nth-child(2):content('#{task2_data['item1']}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(3):content('#{task2_data['item2']}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(4):content('#{task2_data['tweet']}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(5):content('#{task2_data['metadata1']}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(6):content('#{task2_data['metadata2']}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(7):content('#{@mc1_opt2.label}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(8):content('#{@mc2_opt3.label}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(9):content('response 3')"
    assert_select "tbody tr:nth-child(2) td:nth-child(10):content('response 4')"
    assert_select "tbody tr:nth-child(2) td:nth-child(11) a:content('#{@r2.m_turk_user_id}')"
    assert_select "tbody tr:nth-child(2) td:nth-child(12):content('20')"
    assert_select "tbody tr:nth-child(2) td:nth-child(13) .approval-status:content('Rejected')"
  end


  def setup_data
    return if @e

    @e = create :evaluation_with_tasks_and_questions, :task_count => 2,
                                                      :mc_option_count => 3

    @mc1 = @e.mc_questions.first
    @mc2 = @e.mc_questions.second
    @fr1 = @e.fr_questions.first
    @fr2 = @e.fr_questions.second

    @mc1_opt1 = @mc1.mc_question_options.first
    @mc1_opt2 = @mc1.mc_question_options.second
    @mc1_opt3 = @mc1.mc_question_options.third

    @mc2_opt1 = @mc2.mc_question_options.first
    @mc2_opt2 = @mc2.mc_question_options.second
    @mc2_opt3 = @mc2.mc_question_options.third
    @mc2_opt3.value = 10
    @mc2_opt3.save!

    @r1 = create :task_response, :task => @e.tasks.first, :approved => nil, :work_duration => 10
    create :mc_question_response, :task_response      => @r1,
                                  :mc_question_option => @mc1_opt1

    create :mc_question_response, :task_response      => @r1,
                                  :mc_question_option => @mc2_opt2

    create :fr_question_response, :task_response      => @r1,
                                  :fr_question        => @fr1,
                                  :response           => "response 1"

    create :fr_question_response, :task_response      => @r1,
                                  :fr_question        => @fr2,
                                  :response           => "response 2"

    @r2 = create :task_response, :task => @e.tasks.second, :approved => false, :work_duration => 20

    create :mc_question_response, :task_response      => @r2,
                                  :mc_question_option => @mc1_opt2

    create :mc_question_response, :task_response      => @r2,
                                  :mc_question_option => @mc2_opt3

    create :fr_question_response, :task_response      => @r2,
                                  :fr_question        => @fr1,
                                  :response           => "response 3"

    create :fr_question_response, :task_response      => @r2,
                                  :fr_question        => @fr2,
                                  :response           => "response 4"
  end

  def get_page
    get :index, :evaluation_id => @e.id
  end
end