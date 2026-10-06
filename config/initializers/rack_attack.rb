# Injection and traversal syntax only, never bare SQL words: the live search sends a request
# per pause while typing, and a visitor searching "Richard" or "union" must not be banned.
PENTESTER_QUERY = %r{
  UNION\s+(ALL\s+)?SELECT
  | CHAR\(
  | ORDER\s+BY\s+\d
  | INFORMATION_SCHEMA
  | PG_SLEEP
  | AND\s+SLEEP\s*\(
  | '\s*(OR|AND)\s+'?\w+'?\s*=  # quoted tautology such as ' OR '1'='1
  | \.\./\.\.
  | /etc/passwd
  | /etc/hosts
  | /proc/self
}xi

PENTESTER_PATHS = %w[
  /etc/passwd
  setup.php
  phpMyAdmin
  xmlrpc.php
  wp-admin
  wp-content
  wp-login
  th1s_1s_a_4o4.html
  ads.txt
  wlwmanifest.xml
  eval-stdin.php
  .env
].freeze

Rack::Attack.blocklist("fail2ban pentesters") do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 60.minutes) do
    CGI.unescape(req.query_string).match?(PENTESTER_QUERY) ||
      PENTESTER_PATHS.any? { |path| req.path.include?(path) }
  end
end
