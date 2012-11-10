# Tools for generating worker stats based on response times an payments
class CRStats
  # tasks: tuples of [[time to complete task, amount paid for task], ...]
  # Times are in seconds, payments are in cents.
  def initialize tasks
    @tasks = tasks
    @times = tasks.map(&:first)
    @payments = tasks.map(&:last)
    @num_tasks = tasks.length
  end

  # Mean average amount of time it took workers to complete tasks, in seconds.
  def mean_time
    mean @times
  end

  # Total amount of time it took workers to complete tasks, in seconds
  def sum_time
    sum @times
  end

  # Median amount of time it took workers to complete tasks, in seconds
  def median_time
    median @times
  end

  # Effective pay rate, in cents per hour, over all tasks
  # This is calculated as:
  # sum(pay rate for task * time spent on task) / sum(time spent on task)
  # e.g. the average pay rate for each task weighted by the time spent on the
  # task -- which is mathematically equivalent to the pay rate based on the sum
  # of payments and the sum of task times,
  def overall_pay_rate
    pay_rate(sum(@times), sum(@payments))
  end

  # Mean of the tasks' pay rates
  def mean_pay_rate
    mean(pay_rates)
  end

  # Median of the tasks' pay rates
  def median_pay_rate
    median(pay_rates)
  end

  private

  def pay_rates
    @tasks.map do |task|
      pay_rate(*task)
    end
  end

  # Returns the pay rate, in cents per hour, given the time in seconds
  # and the payment in cents.
  def pay_rate time, payment
    if time == 0
      # assume time is actually 1
      time = 1
    end

    (1.0/time) * (60.0*60.0) * payment
  end

  def sum ary
    ary.inject 0, &:+
  end

  def mean ary
    return 0 if ary.length == 0
    sum(ary).to_f / ary.length
  end

  def median ary
    return 0 if ary.length == 0

    sorted = ary.sort
    middle = ary.length / 2

    if (ary.length % 2) == 0
      # even, take mean of middle 2
      return (sorted[middle] + sorted[middle-1]) / 2.0
    else
      # odd, return middle
      return sorted[middle]
    end
  end
end