ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  errors = Array(instance.error_message).join(',')
  %(<span class="control-group error">#{html_tag}<span class="help-inline">&nbsp;#{errors}</span></span>).html_safe
end