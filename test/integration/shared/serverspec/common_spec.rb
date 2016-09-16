require 'serverspec'

# Required by serverspec
set :backend, :exec

describe package('curl') do
  it { should be_installed }
end
