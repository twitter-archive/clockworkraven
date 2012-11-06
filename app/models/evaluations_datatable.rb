class EvaluationsDatatable
  delegate :params, :h, :link_to, :to => :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      :sEcho => params[:sEcho].to_i,
      :iTotalRecords => Evaluation.count,
      :iTotalDisplayRecords => evaluations.total_entries,
      :aaData => data
    }
  end

private
  PRODUCTION_ID = {
    "production" => 1,
    "sandbox" => 0
  }


  def data
    evaluations.map do |evaluation|
      [
        evaluation.name,
        evaluation.prod? ? 'Production' : 'Sandbox',
        evaluation.status_name,
        evaluation.user.name,
        evaluation.created_at.in_time_zone("Pacific Time (US & Canada)").strftime(ClockworkRaven::Application::TIME_FORMAT),
        evaluation
      ]
    end
  end

  def evaluations
    @evaluations ||= fetch_evaluations
  end

  def fetch_evaluations

    # Protect against SQL injection by validating column and direction before sorting
    if Evaluation.column_names.include?(sort_column) && %w(asc desc).include?(sort_direction)
      evaluations = Evaluation.order("#{sort_column} #{sort_direction}")
    end

    evaluations = evaluations.page(page).per_page(per_page)
    if params[:sSearch].present?

      def query_ids(id_map, query)
        id_map.find_all { |key, value| key.to_s.include?(query.downcase) }.map { |key, value| value }
      end

      # must match each search term
      params[:sSearch].split.each do |term|
        search_term = "%#{term}%"

        # Match mode searches
        prod = query_ids(PRODUCTION_ID, term)

        # Match status searches
        status = query_ids(Evaluation::STATUS_ID, term)

        matched_ids = User.select('id').where("name like :search", :search => search_term).map { |match| match.id }
        evaluations = evaluations.where("name like :search or user_id in (:uids) or prod in (:prod) or status in (:status)",
          :search => search_term, :uids => matched_ids, :prod => prod, :status => status)
      end

      # check for production search

    end
    evaluations
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[name prod status creator created_at]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end