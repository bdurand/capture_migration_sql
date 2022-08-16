RAILS_7_RELEASES = ["7.0"].freeze

RAILS_7_RELEASES.each do |version|
  appraise "activerecord-#{version.split('.').take(2).join('.')}" do
    gem "activerecord", "~> #{version}.0"
    gem "sqlite3", "~> 1.4.0"
  end
end

RAILS_6_RELEASES = ["6.0", "6.1"].freeze

RAILS_6_RELEASES.each do |version|
  appraise "activerecord-#{version.split('.').take(2).join('.')}" do
    gem "activerecord", "~> #{version}.0"
    gem "sqlite3", "~> 1.4.0"
  end
end

RAILS_5_RELEASES = ["5.2", "5.1", "5.0"].freeze

RAILS_5_RELEASES.each do |version|
  appraise "activerecord-#{version.split('.').take(2).join('.')}" do
    gem "activerecord", "~> #{version}.0"
    gem "sqlite3", "~> 1.3.0"
  end
end

RAILS_4_RELEASES = ["4.2"].freeze

RAILS_4_RELEASES.each do |version|
  appraise "activerecord-#{version.split('.').take(2).join('.')}" do
    gem "activerecord", "~> #{version}.0"
    gem "sqlite3", "~> 1.3.0"
  end
end
