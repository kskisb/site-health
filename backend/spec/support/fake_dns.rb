# 名前解決の答えをテストの中で差し替える。Resolv::DNS.open に、決めた答えを返す偽物を渡す
#
#   stub_dns("example.com" => %w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c])
module FakeDns
  def stub_dns(answers)
    dns = instance_double(Resolv::DNS, :timeouts= => nil)

    allow(dns).to receive(:getresources) do |name, type|
      addresses = Array(answers[name.to_s]).map { |address| IPAddr.new(address) }

      if type == Resolv::DNS::Resource::IN::A
        addresses.select(&:ipv4?).map { |address| Resolv::DNS::Resource::IN::A.new(address.to_s) }
      else
        addresses.select(&:ipv6?).map { |address| Resolv::DNS::Resource::IN::AAAA.new(address.to_s) }
      end
    end

    allow(Resolv::DNS).to receive(:open).and_yield(dns)
    dns
  end
end

RSpec.configure do |config|
  config.include FakeDns
end
