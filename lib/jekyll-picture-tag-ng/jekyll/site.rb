# frozen_string_literal: true

require "jekyll"

module Jekyll
  # Override the write methid to paralellize it
  class Site
    alias_method "old_write", "write"

    def write
      if config["picture_tag_ng"]["parallel"]
        Jekyll.logger.info "Writing files in parallel"
        Jekyll::Commands::Doctor.conflicting_urls(self)
        each_site_file do |item|
          regenerator.regenerate?(item) && add_task { item.write(dest) }
        end
        thread_pool.each do
          add_task { -1 } # Each thread will terminate when a task returns `-1`
        end
        thread_pool.each(&:join)
        reset_thread_pool # Cleanup to be ready for next generation (`jekyll serve`)
        regenerator.write_metadata
        Jekyll::Hooks.trigger :site, :post_write, self
        nil
      else
        old_write
      end
    end

    def thread_pool
      @thread_pool ||= (0..n_threads).map do |i|
        Jekyll.logger.debug "Creating thread num #{i}"
        Thread.new do
          j = 0
          Kernel.loop do
            Jekyll.logger.debug "Doing task num. #{j}"
            j += 1
            task = next_task
            if task.nil?
              sleep 0.1
            elsif task.instance_of?(Proc)
              res = task.call
            end

            break if res == -1
          end
          Jekyll.logger.debug "Finishing thread num #{i}"
        end
      end
    end

    def n_threads
      config["picture_tag_ng"]["threads"] || 8
    end

    def reset_thread_pool
      @thread_pool = nil
    end

    def next_task
      @task_queue ||= []
      @task_queue.shift
    end

    def add_task(&task)
      @task_queue ||= []
      @task_queue.push(task)
    end
  end
end
