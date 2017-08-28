use Mix.Config

config :idq_auth,
  endpoint: "https://taas.idquanta.com/idqoauth/api/v1/",
  callback_url: "http://localhost:4000/",
  client_id: "KEY",
  client_secret: "SECRET"
