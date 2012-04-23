def stub_request(path="/", method=:get)
  ActionDispatch::TestRequest.new("PATH_INFO"      => path,
                                  "REQUEST_METHOD" => method.to_s.upcase)
end