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

// job.rb: Code to automatically update the job status page to show
//         progress of the page



$(function() {
    if($('body').attr('class') != "jobs show") {
        // we're not on the job status page; abort
        return;
    }

    Jobs.startUpdating();
})

Jobs = {
    // Time, in ms, between updates
    UPDATE_INTERVAL: 2000,
    UPDATE_URL: window.location.href + '.json',
    KILL_URL: window.location.href + '/kill.json',

    startUpdating: function() {
        Jobs.updateIntervalId = setInterval(Jobs._update, Jobs.UPDATE_INTERVAL);
    },

    stopUpdating: function() {
        if(Jobs.updateIntervalId) {
            clearInterval(Jobs.updateIntervalId);
        }
    },

    killJob: function() {
        if (confirm("Are you sure?")) {
        Jobs.stopUpdating();
            $.ajax({
                type: 'POST',
                url: Jobs.KILL_URL,
                success: function() {
                    Jobs.killButton().text('Killed.').attr('disabled', 'disabled');
                    Jobs.progressBar().addClass('progress-danger');
                    Jobs.progressBar().removeClass('active');
                },
                error: function() {
                    Jobs.killButton().text('Failed. Retry.').removeAttr('disabled');
                },
                complete: function() {
                    Jobs._update();
                    Jobs.startUpdating();
                }
            });
            Jobs.killButton().text('Killing...').attr('disabled', 'disabled');
        }
    },

    backButton: function() {
        return $('.btn-danger');
    },

    killButton: function() {
        return $('.btn-inverse');
    },

    continueButton: function() {
        return $('.btn-success');
    },

    progressBar: function() {
        return $('.progress');
    },

    progressText: function() {
        return $('.progress-text');
    },

    queuedText: function() {
        return $('.queued');
    },

    _update: function() {
        $.getJSON(Jobs.UPDATE_URL, Jobs._handleData);
    },

    _handleData: function(data) {
        // update progress bar and text
        $('#progress_bar').css('width', data.percentage + '%');
        $('.completed').text(data.completed);
        $('.total').text(data.total);

        // show error if there is one
        if(data.status_name == 'error' || (data.status_name == 'killed')) {
            $('.alert').slideDown();
        }
        else {
            $('.alert').slideUp();
        }

        $('.alert-content').text(data.error)

        // if the job isn't new, hide the "Queued" text and show progress
        if(data.status_name != 'new') {
            Jobs.progressText().show();
            Jobs.queuedText().hide();
        }

        // if the job has completed, un-disable the continue button
        if(data.status_name == 'done') {
            Jobs.continueButton().removeAttr('disabled');
            Jobs.progressBar().addClass('progress-success');
        }
        else {
            Jobs.continueButton().attr('disabled', 'disabled');
        }

        // red progress bar for killed or failed jobs
        if((data.status_name == 'error') || (data.status_name == 'killed')) {
            Jobs.progressBar().addClass('progress-danger');
        }

        // if the job has ended, style the progress bar, disable kill,
        // and stop updating this page.
        if(data['ended?'] == true) {
            Jobs.killButton().attr('disabled', 'disabled');
            Jobs.progressBar().removeClass('active');
            Jobs.stopUpdating();
        }
        else {
            Jobs.killButton().removeAttr('disabled');
        }
    }
}