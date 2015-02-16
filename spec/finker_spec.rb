require 'spec_helper'

FILE_PATH   = '/path/to/file'
HOGERC_PATH = '/home/hoge/.hogerc'

describe Finker do
  it 'has a version number' do
    expect(Finker::VERSION).not_to be nil
  end

  describe Finker::CLI do
    before do
      FileUtils.mkdir_p('working')
      FileUtils.cd('working')

      File.open(Finker::CONFIG_FILE, 'w') do |file|
        file.write(<<-EOS)
link:
  - /path/to/file
  - $ENV_VAR:
    - .hogerc
        EOS
      end
      ENV['ENV_VAR'] = '/home/hoge'

      FileUtils.mkdir_p('/path/to')
      FileUtils.mkdir_p('/home/hoge')
    end

    describe '#setup' do
      before do
        [FILE_PATH, HOGERC_PATH].each do |path|
          FileUtils.touch(path)
        end

        Finker::CLI.new.setup
      end

      it 'creates symbolic links' do
        [FILE_PATH, HOGERC_PATH].each do |path|
          expect(File.lstat(path).ftype).to eq 'link'
        end
      end

      it 'creates symbolic links pointing valid files' do
        expect(File.readlink(FILE_PATH)).to eq '/working/path/to/file'
        expect(File.readlink(HOGERC_PATH)).to eq '/working/$ENV_VAR/.hogerc'
      end
    end
  end
end
