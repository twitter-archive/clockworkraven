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

module RoutingTestHelper
  def assert_recognizes(x, path, *args)
    # take the mounted_path into consideration
    mount = ClockworkRaven::Application.mounted_path
    if path.is_a?(Hash)
      path[:path] = "#{mount}#{path[:path]}" if path[:path]
    else
      path = "#{mount}#{path}" if path
    end
    super
  end
  
  def assert_resource_routed resource
    assert_routing({:method => 'get', :path => "/#{resource}"},
                   {:controller => resource, :action => 'index'})

    assert_routing({:method => 'get', :path => "/#{resource}/new"},
                   {:controller => resource, :action => 'new'})

    assert_routing({:method => 'post', :path => "/#{resource}"},
                   {:controller => resource, :action => 'create'})

    assert_routing({:method => 'get', :path => "/#{resource}/5"},
                   {:controller => resource, :action => 'show', :id => "5"})

    assert_routing({:method => 'get', :path => "/#{resource}/7/edit"},
                   {:controller => resource, :action => 'edit', :id => "7"})

    assert_routing({:method => 'put', :path => "/#{resource}/10"},
                   {:controller => resource, :action => 'update', :id => "10"})

    assert_routing({:method => 'delete', :path => "/#{resource}/3"},
                   {:controller => resource, :action => 'destroy', :id => "3"})
  end

  def assert_nested_resource_routed resource, parent
    parent_id = "#{parent.singularize}_id".to_sym

    assert_routing({:method => 'get', :path => "/#{parent}/20/#{resource}"},
                   {:controller => resource, :action => 'index', parent_id => "20"})

    assert_routing({:method => 'get', :path => "/#{parent}/20/#{resource}/new"},
                   {:controller => resource, :action => 'new', parent_id => "20"})

    assert_routing({:method => 'post', :path => "/#{parent}/20/#{resource}"},
                   {:controller => resource, :action => 'create', parent_id => "20"})

    assert_routing({:method => 'get', :path => "/#{parent}/20/#{resource}/5"},
                   {:controller => resource, :action => 'show', :id => "5", parent_id => "20"})

    assert_routing({:method => 'get', :path => "/#{parent}/20/#{resource}/7/edit"},
                   {:controller => resource, :action => 'edit', :id => "7", parent_id => "20"})

    assert_routing({:method => 'put', :path => "/#{parent}/20/#{resource}/10"},
                   {:controller => resource, :action => 'update', :id => "10", parent_id => "20"})

    assert_routing({:method => 'delete', :path => "/#{parent}/20/#{resource}/3"},
                   {:controller => resource, :action => 'destroy', :id => "3", parent_id => "20"})
  end
end
