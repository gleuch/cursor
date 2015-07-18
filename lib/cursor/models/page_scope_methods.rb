module Cursor
  module PageScopeMethods
    # Specify the <tt>per_page</tt> value for the preceding <tt>page</tt> scope
    #   Model.page(3).per(10)
    def per(num)
      if (n = num.to_i) <= 0
        self
      elsif max_per_page && max_per_page < n
        limit(max_per_page)
      else
        limit(n)
      end
    end

    # Number results returned
    def total_results
      @total_results ||= count
    end

    # Total number of results
    def total_entries
      @total_entries ||= limit(nil).count
    end

    # TODO: are these 2 methods triggering multiple db hits? want to run this on cached result
    def next_cursor
      @_next_cursor ||= all.last.try(:id)
    end

    def prev_cursor
      @_prev_cursor ||= all.first.try(:id)
    end

    def next_url request_url
      return nil if next_cursor.nil? || current_cursor == next_cursor
      return nil if current_cursor.nil? && direction == :after
      direction == :after ? 
        after_url(request_url, next_cursor) :
        before_url(request_url, next_cursor)
    end

    def prev_url request_url
      return nil if prev_cursor.nil? || current_cursor == prev_cursor
      return nil if current_cursor.nil? && direction != :after
      direction == :after ? 
        before_url(request_url, prev_cursor) :
        after_url(request_url, prev_cursor)
    end

    def before_url request_url, cursor
      base, params = url_parts(request_url)
      params.merge!(Cursor.config.before_param_name.to_s => cursor) unless cursor.nil?
      params.to_query.length > 0 ? "#{base}?#{CGI.unescape(params.to_query)}" : base
    end

    def after_url request_url, cursor
      base, params = url_parts(request_url)
      params.merge!(Cursor.config.after_param_name.to_s => cursor) unless cursor.nil?
      params.to_query.length > 0 ? "#{base}?#{CGI.unescape(params.to_query)}" : base
    end

    def url_parts request_url
      base, params = request_url.split('?', 2)
      params = Rack::Utils.parse_nested_query(params || '')
      params.stringify_keys!
      params.delete(Cursor.config.before_param_name.to_s)
      params.delete(Cursor.config.after_param_name.to_s)
      [base, params]
    end

    def direction
      return :after if prev_cursor.nil? && next_cursor.nil?
      @_direction ||= prev_cursor < next_cursor ? :after : :before
    end

    def pagination request_url
      h = {
        next_cursor: next_cursor,
        prev_cursor: prev_cursor
      }
      h[:next_url] = next_url(request_url) unless next_cursor.nil?
      h[:prev_url] = prev_url(request_url) unless prev_cursor.nil?
      h
    end
  end
end
