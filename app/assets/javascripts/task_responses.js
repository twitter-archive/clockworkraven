/* Copyright 2012 Twitter, Inc. and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// task_responses.js: Code for the bar chart visualization and data table on the
//                    evaluations results page

TaskResponses = {
    // the current set of filters applied to the chart
    filters: {},

    // Initializes the bar chart
    initChart: function() {
        TaskResponses.barChartOptions = {
            width: '100%',
            height: '100%',
            title: 'Results Summary',
            isStacked: true,
            animation: {
                duration: 1000,
                easing: 'out',
            }
        };

        TaskResponses.barChart = new google.visualization.ColumnChart(document.getElementById('bar_chart'));

        // update chart when options change
        $('input[type=radio]').click(TaskResponses.updateChart);

        // load in initial data
        TaskResponses.updateChart();
    },

    // Updates the bar chart to reflect the selected parameters
    updateChart: function() {
        // copy default options
        var options = $.extend(true, {}, TaskResponses.barChartOptions);

        // which question are we charting?
        var chartQuestionRadio = $('input[name=chart_option]:checked');
        options.hAxis = {title: chartQuestionRadio.get(0).nextSibling.nodeValue.trim()}
        var chartQuestionId = chartQuestionRadio.val();
        var chartQuestion = DATA.mcQuestions[chartQuestionId];

        // what are we segmenting by?
        var segmentQuestionId = $('input[name=segment_option]:checked').val();
        var segmentQuestion = DATA.mcQuestions[segmentQuestionId];

        if(!_.isObject(segmentQuestion)) {
            // we're not segmenting, so set segmentQuestion to chartQuestion
            // for reasonable behavior
            segmentQuestion = chartQuestion;
            segmentQuestionId = chartQuestionId;
        }

        if(segmentQuestion == chartQuestion) {
            // disable legend
            options.legend = {position: 'none'};
        }

        // what values are we displaying?
        var displayRadio = $('input[name=display_option]:checked');
        options.vAxis = {title: displayRadio.get(0).nextSibling.nodeValue.trim()}
        var display = displayRadio.val();

        // is this a change just to filtering?
        var justFilter = ((chartQuestionId == TaskResponses.oldChartQuestionId) &&
                          (segmentQuestionId == TaskResponses.oldSegmentQuestionId));

        TaskResponses.oldChartQuestionId = chartQuestionId;
        TaskResponses.oldSegmentQuestionId = segmentQuestionId;

        // update filtering
        TaskResponses.filters = {};
        $('.filter-pane').each(function(index, pane) {
            var selected = $(pane).children('input[type=radio]:checked');
            var questionId = selected.attr('name').split('_')[1];
            var value = selected.val();

            if(value != 'none') {
                TaskResponses.filters[questionId] = value;
            }
        });

        // build a table
        var header = ['chartQuestion']
        header = header.concat(_.map(segmentQuestion.options, TaskResponses.labelForOption));
        var table = [header];
        table = table.concat(_.map(chartQuestion.options, function(optionId, i) {
            var label = TaskResponses.labelForOption(optionId);
            var filtered = _.map(segmentQuestion.options, function(segOptionId) {
                return _.filter(DATA.responses, function(response) {
                    return (
                        (response.approved) &&
                        (response.mcQuestions[chartQuestionId] == optionId) &&
                        (response.mcQuestions[segmentQuestionId] == segOptionId) &&
                        _.all(TaskResponses.filters, function(value, key) {
                            // check filters
                            return (response.mcQuestions[key] == value);
                        })
                    );
                });
            });


            var values;
            if(display == 'normalized') {
                // we're normalizing the bars
                var sum = _.reduce(filtered, function(memo, item){
                    return memo + item.length;
                }, 0);

                values = _.map(filtered, function(item) {
                    return item.length / sum;
                })
            }
            else if(display == 'count'){
                // we're just displaying counts
                values = _.pluck(filtered, 'length');
            }
            else {
                // we're showing an average value
                var sum = _.reduce(filtered, function(memo, item){
                    return memo + item.length;
                }, 0);

                values = _.map(filtered, function(item) {
                    return TaskResponses.totalValueOfResponses(item, display) / sum;
                })
            }

            return [label].concat(values);
        }));

        if(!justFilter) {
            // no animations
            delete options.animation;
        }

        TaskResponses.barChart.draw(google.visualization.arrayToDataTable(table), options)

        // calculate the average value
        var hasValues = TaskResponses.hasValues(chartQuestionId)
        if(hasValues) {
            $('#average_value').text(TaskResponses.averageValue(chartQuestionId))
            $('#average_value_text').show();
        }
        else {
            $('#average_value_text').hide();
        }

    },

    // returns the label for the given option id, with the option's
    // value appended if it has one (e.g. "Tweet A was more relvant (value: -1)")
    labelForOption: function(optionId) {
        var label = DATA.mcQuestionOptions[optionId].label;

        // add value to the label if there is one
        if(DATA.mcQuestionOptions[optionId].value) {
            label += (" (value: " + DATA.mcQuestionOptions[optionId].value + ")")
        }

        return label
    },

    hasValues: function(questionId) {
        return _.any(DATA.mcQuestions[questionId].options, function(optionId) {
            return DATA.mcQuestionOptions[optionId].value;
        })
    },

    averageValue: function(questionId) {
        var filteredResponses = _.filter(DATA.responses, function(response) {
            // Only examine responses that match the current filters
            return _.all(TaskResponses.filters, function(value, key) {
                return (response.mcQuestions[key] == value);
            })
        });

        return TaskResponses.totalValueOfResponses(filteredResponses, questionId) / filteredResponses.length;
    },

    totalValueOfResponses: function(responses, questionId) {
        return _.chain(responses)
                .map(function(response) {
                    // retrieve the value of the options selected by the
                    // response
                    var option = response.mcQuestions[questionId];
                    if(option && DATA.mcQuestionOptions[option].value) {
                        return DATA.mcQuestionOptions[option].value;
                    }
                    return 0;
                })
                .reduce(function(memo, value) {
                    // sum
                    return memo + value;
                }, 0)
                .value();
    },

    // initialize the table of responses
    initDataTable: function() {
        TaskResponses.dt = $("#data_table").dataTable({
            // use jquery UI
            "bJQueryUI": true,
            // numbers, not just next/prev
            "sPaginationType": "full_numbers",
            // don't sort on actions
            "aoColumnDefs": [
                {
                    "bSortable": false,
                    "sWidth": "200px",
                    "bSearchable": false,
                    "aTargets": [ 0 ]
                }
            ],
            // header: length, search box
            // footer: page info, pagination controls
            "sDom": '<"H"lCfr>t<"F"ip>',
            // active column visibility selection on mouseover and always
            // make actions visible
            "oColVis": {
                "activate": "mouseover",
                "aiExclude": [ 0 ]
        	},
        	// save state across page loads
        	"bStateSave": true,
        	// disable auto-width
        	"bAutoWidth": true
        });
    },

    // initalize buttons for approve/reject, ban, trust, etc.
    initButtons: function() {
        // approval buttons

        $('.btn-approval').bind('ajax:before', function() {
            console.log('starting approval');
            $(this).parents('.approval-controls').fadeOut(200).delay(200).siblings('.approval-spinner').fadeIn();
        }).bind('ajax:complete', function(evt, data) {
            console.log("approval success", evt, data);
            // switch to success
            var status = JSON.parse(data.responseText).status;

            // replace spinner
            $(this).parents('.approval-controls').siblings('.approval-spinner').stop().clearQueue().fadeOut(200, function() {
                $(this).siblings('.approval-controls').text(status).fadeIn();
            });

            // replace approval cell
            var pos = TaskResponses.dt.fnGetPosition($(this).parents('td').siblings('td.approval').get(0));
            TaskResponses.dt.fnUpdate(status, pos[0], pos[1]);

            // update chart data
            if(status == 'Rejected') {
                delete DATA.responses[$(this).attr("data-response")]
                TaskResponses.updateChart();
            }
        }).bind('ajax:error', function() {
            console.log('approval error')
            // switch to failure
            $(this).parents('.approval-controls').siblings('.approval-spinner').stop().clearQueue().fadeOut(200, function() {
                $(this).siblings('.approval-controls').text("Operation Failed").fadeIn();
            });
        });

        // banning and trusting buttons
        TaskResponses.setupButtons('Ban/Unban', '.btn-ban', '.btn-unban',
                                   '.ban-controls', '.ban-spinner', 'Banned');

        TaskResponses.setupButtons('Trust/Untrust', '.btn-trust', '.btn-untrust',
                                   '.trust-controls', '.trust-spinner', 'Trusted');
    },

    // helper function to set up the trust/untrust buttons and the ban/unban buttons
    //
    // name: name for logging purposes
    // positive selector: selector for buttons that activate a state (e.g. .trust, .ban)
    // negative selector: selector for buttons that deactivate a state (e.g. .untrust, .unban)
    // controls selector: selector for wrapper around the buttons (e.g. .trust-wrapper)
    // spinner selector: selector for spinner GIF (e.g. .trust-spinner)
    // positive response: server response for a positive action (e.g. "Trusted", "Banned")
    setupButtons: function(name, posSelector, negSelector, controlsSelector, spinnerSelector, positiveResponse) {
        $(posSelector).add(negSelector).bind('ajax:before', function() {
            // fade out the controls and fade in a spinner while we're loading
            // the response
            console.log(name, 'starting request');
            $(this).parents(controlsSelector).fadeOut(200).delay(200).siblings(spinnerSelector).fadeIn(200);
        }).bind('ajax:complete', function(evt, data) {
            // we got a successful response
            console.log(name, 'got a success response');

            // get the response to determine whether the action was positive
            // (e.g. "ban") or negative (e.g. "unban")
            var status = JSON.parse(data.responseText).status;

            // replace the spinner with the new action button. Clear the
            // spinner's animation queue in case it's still fading in.
            $(this).parents(controlsSelector).siblings(spinnerSelector).stop().clearQueue().fadeOut(200, function() {
                // find all rows that belong to this user and fade out the controls
                userid = $(this).parents('tr').children(".mturk-user").text();
                TaskResponses.dt.$('tr:contains(' + userid + ')').find(controlsSelector).fadeOut(function() {
                    if (status == positiveResponse) {
                        // we serviced a request for a positive action. Hide the
                        // positve action button and show the negative action
                        // button.
                        $(this).children(posSelector).hide();
                        $(this).children(negSelector).css('display', 'block');
                    }
                    else {
                        // other way around
                        $(this).children(posSelector).css('display', 'block');
                        $(this).children(negSelector).hide();
                    }

                    // fade the controls back in
                    $(this).fadeIn();
                });
            })
        }).bind('ajax:error', function() {
            console.log(name, 'got an error response');

            // switch to failure
            $(this).parents(controlsSelector).siblings(spinnerSelector).stop().clearQueue().fadeOut(200, function() {
                $(this).siblings(controlsSelector).text("Operation Failed").fadeIn();
            });
        });
    }
}

google.load('visualization', '1.0', {'packages':['corechart']});
google.setOnLoadCallback(function() {
    if ($('body').attr('class') != "task_responses index") {
        // we're not on the task responses index page; abort
        return;
    }

    // initialize everything
    TaskResponses.initButtons();
    TaskResponses.initChart();
    TaskResponses.initDataTable();
});