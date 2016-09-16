require 'serverspec'

# Required by serverspec
set :backend, :exec



describe "file system checks" do
  describe file('/data1') do
    it { should be_mounted }
  end

  describe file('/data1') do
    it { should be_mounted.with( :type => 'ext4' ) }
  end
end
