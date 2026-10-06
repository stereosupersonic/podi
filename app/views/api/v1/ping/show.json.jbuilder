json.status "ok"
json.user do
  json.email @api_token.user.email
end
json.token do
  json.name @api_token.name
end
