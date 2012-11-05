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

require 'thread'

# Basic thread pooling utilities. Processes a shared queue of items in a fixed
# number of threads
module Threading
  # Processes <items> in a thread pool of size <size> by calling
  # <processor> and passing the item in as an argument.
  #
  # Blocks until the pool is done processing.
  #
  # Will retry up to <retry_count> times if items fail.
  #
  # If the processor throws an exception on any item, the queue is cleared,
  # and the exception is propagated.
  def Threading.thread_pool items, size=4, retry_count=3, &processor
    queue = Queue.new
    items.each {|o| queue.push o}
    threads = []
    results = []

    size.times do
      threads << Threading.new_thread do
        begin
          until queue.empty?
            item = queue.pop
            result = nil
            retries = retry_count

            begin
              result = processor.call(item)
            rescue Resque::Plugins::Status::Killed => e
              # don't retry if we get forcibly killed
              raise e
            rescue => e
              # for any other error, retry if we have retries left.
              Rails.logger.warn("Got an error in thread pool. Retries: #{retries}.\n#{e.inspect}")
              if retries > 1
                retries -= 1
                retry
              else
                raise e
              end
            end

            results.push result
          end
        rescue => e
          queue.clear
          raise e
        end
      end
    end

    threads.each &:join
    return results
  end

  # Sets the factory used to create new threads.
  #
  # The factory must response to .new(&block) by running &block (possibly in
  # the background) and returning an object that responds to .join. join must
  # not return until the block passed to new completes, and must return the
  # result of the block.
  #
  # Possible factories include Ruby build-in Thread class or
  # Threading::FakeThread
  def self.thread_factory= factory
    @factory = factory
  end

  # Returns the current thread factory. Defaults to Thread.
  def self.thread_factory
    @factory || Thread
  end

  # Creates a new thread using the current thread factory and executes <block>
  # in that thread. Returns an object that responds to :join.
  def self.new_thread &block
    self.thread_factory.new &block
  end

  # A Thread-like class that just stores the block passed to .new and runs
  # it when join is called.
  class FakeThread
    def initialize &block
      @block = block
    end

    def join
      @block.call
    end
  end
end