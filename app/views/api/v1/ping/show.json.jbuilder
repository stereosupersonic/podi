json.status "ok"
json.user do
  json.email @current_api_token.user.email
end
json.token do
  json.name @current_api_token.name
end
