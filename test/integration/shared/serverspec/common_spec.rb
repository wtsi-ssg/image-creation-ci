require 'serverspec'
require 'socket'
hostname = Socket.gethostname

# Required by serverspec
set :backend, :exec

describe package('curl') do
  it { should be_installed }
end
