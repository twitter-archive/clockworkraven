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

ClockworkRaven::Application.routes.draw do
  scope ClockworkRaven::Application.mounted_path do
    resources :evaluations do
      resources :tasks

      member do
        get 'original_data'
        get 'random_task'
        post 'submit'
        post 'purge'
        post 'close'
        post 'approve_all'
        get 'edit_template'
        put 'update_template'
      end

      resources :task_responses do
        member do
          post 'approve'
          post 'reject'
        end
      end
    end

    resources :m_turk_users do
      member do
        post 'trust'
        post 'untrust'
        post 'ban'
        post 'unban'
      end
    end

    resources :jobs do
      member do
        post 'kill'
      end
    end

    # login routes
    get "login" => "logins#login"
    post "login" => "logins#persist_login"
    post "logout" => "logins#logout"

    # account routes
    get 'account' => 'users#show', :as => 'account'
    get 'account/edit' => 'users#edit', :as => 'edit_account'
    put 'account' => 'users#update', :as => 'update_account'
    post 'account/reset_key' => 'users#reset_key', :as => 'reset_key'

    # default: /evaluations
    root :to => 'evaluations#index'

    mount Resque::Server.new, :at => "/resque"
  end
end 