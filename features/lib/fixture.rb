class Fixture
  def initialize(name, version = nil)
    @name = name
    @version = version
  end

  def docker_service
    "#{@name}#{@version}"
  end

  def host
    if running_in_docker?
      docker_service
    else
      "localhost"
    end
  end

  def port
    # the rails integrations tests run with a version of "_integrations" and
    # bind to port 3000 even when running outside of docker
    if running_in_docker? || @version == "_integrations"
      "3000"
    elsif @name == "rack"
      "7251"
    else
      "725#{@version}"
    end
  end

  def version_matches?(operator, version_to_compare)
    @version.to_i.send(operator, version_to_compare)
  end

  def uri_for(route)
    URI("http://#{host}:#{port}#{route}")
  end

  def navigate_to(route, headers = {})
    uri = uri_for(route)

    make_request(uri) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)

      headers.each do |key, value|
        request[key] = value
      end

      request
    end
  end

  def post_form(route, form_data)
    uri = uri_for(route)

    make_request(uri) do |http|
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(form_data)

      request
    end
  end

  def post_json(route, json_data)
    uri = uri_for(route)

    make_request(uri) do |http|
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.generate(json_data)
      request["Content-Type"] = "application/json"

      request
    end
  end

  private

  def make_request(uri, &block)
    attempts = 0

    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = block.call(http)

        http.request(request)
      end
    rescue => e
      raise e if attempts > 10

      attempts += 1
      sleep 1

      retry
    end
  end
end
