RAILS_MINOR_RELEASES = ["5.2", "5.1", "5.0", "4.2"].freeze

RAILS_MINOR_RELEASES.each do |version|
  appraise "activerecord-#{version}" do
    gem "activerecord", "~> #{version}.0"
  end
end
