# Fixes encoding error when converting uploaded file to JSON
# https://github.com/rails/rails/issues/25250
class Tempfile
  def as_json(_any = nil)
    to_s
  end
end
